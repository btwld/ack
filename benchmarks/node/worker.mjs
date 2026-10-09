import { readFileSync } from 'node:fs';
import { isDeepStrictEqual } from 'node:util';
import Ajv from 'ajv';
import { z } from 'zod';
import * as v from 'valibot';

function zodSchema(s) {
  switch (s.type) {
    case 'string':
      return z.string().min(s.minLength).max(s.maxLength)
        .regex(new RegExp(s.pattern));
    case 'integer': return z.number().int().min(s.minimum).max(s.maximum);
    case 'boolean': return z.boolean();
    case 'array':
      return z.array(zodSchema(s.items)).min(s.minItems).max(s.maxItems);
    case 'object':
      return z.strictObject(Object.fromEntries(
        Object.entries(s.properties).map(([key, value]) => [key, zodSchema(value)]),
      ));
    default: throw new Error(`Unsupported schema type ${s.type}`);
  }
}

function valibotSchema(s) {
  switch (s.type) {
    case 'string':
      return v.pipe(v.string(), v.minLength(s.minLength),
        v.maxLength(s.maxLength), v.regex(new RegExp(s.pattern)));
    case 'integer':
      return v.pipe(v.number(), v.integer(),
        v.minValue(s.minimum), v.maxValue(s.maximum));
    case 'boolean': return v.boolean();
    case 'array':
      return v.pipe(v.array(valibotSchema(s.items)),
        v.minLength(s.minItems), v.maxLength(s.maxItems));
    case 'object':
      return v.strictObject(Object.fromEntries(
        Object.entries(s.properties)
          .map(([key, value]) => [key, valibotSchema(value)]),
      ));
    default: throw new Error(`Unsupported schema type ${s.type}`);
  }
}

function prepare(engine, definition) {
  let result;
  switch (engine) {
    case 'zod': {
      const schema = zodSchema(definition);
      return {
        validate(input) { result = schema.safeParse(input); return result.success; },
        output: () => result.data,
        snapshot: () => result.success ? result.data : result.error.issues,
      };
    }
    case 'valibot': {
      const schema = valibotSchema(definition);
      return {
        validate(input) {
          result = v.safeParse(schema, input, {
            abortEarly: false, abortPipeEarly: false,
          });
          return result.success;
        },
        output: () => result.output,
        snapshot: () => result.success ? result.output : result.issues,
      };
    }
    case 'ajv': {
      // A new instance prevents schema-cache hits in construct+validate.
      // This phase deliberately includes instance creation + compilation.
      const ajv = new Ajv({
        allErrors: true, strict: true,
        coerceTypes: false, useDefaults: false, removeAdditional: false,
      });
      const validate = ajv.compile(definition);
      let inputValue;
      return {
        validate(input) {
          inputValue = input;
          result = validate(input);
          return result;
        },
        output: () => inputValue,
        snapshot: () => result ? inputValue : validate.errors,
      };
    }
    default: throw new Error(`Unknown benchmark engine ${engine}`);
  }
}

if (process.argv.length !== 4) {
  throw new Error('Usage: node worker.mjs <corpus.json> <job.json>');
}
const corpus = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const job = JSON.parse(readFileSync(process.argv[3], 'utf8'));
const { engine } = job;
const validators = Object.fromEntries(Object.entries(corpus.schemas)
  .map(([key, schema]) => [key, prepare(engine, schema)]));
let checks = 0;
for (const c of corpus.cases) {
  const validator = validators[c.schema];
  for (const entry of c.inputs) {
    const before = structuredClone(entry.value);
    for (let repeat = 0; repeat < 2; repeat++) {
      const valid = validator.validate(entry.value);
      if (valid !== entry.valid) throw new Error(`${engine} disagrees on ${c.name}`);
      if (valid && !isDeepStrictEqual(validator.output(), before)) {
        throw new Error(`${engine} changed output on ${c.name}`);
      }
      if (!isDeepStrictEqual(entry.value, before)) {
        throw new Error(`${engine} mutated input on ${c.name}`);
      }
      checks++;
    }
  }
}

const now = () => process.hrtime.bigint();
const elapsedNs = start => Number(now() - start);
const results = [];
if (!job.checkOnly) {
  for (const name of job.cases) {
    const c = corpus.cases.find(c => c.name === name);
    const definition = corpus.schemas[c.schema];
    let validator = prepare(engine, definition);
    const inputs = c.inputs.map(entry => entry.value);
    const encoded = inputs.map(input => JSON.stringify(input));
    let operation;
    switch (c.phase) {
      case 'validate': operation = i => validator.validate(inputs[i]); break;
      case 'decode+validate':
        operation = i => validator.validate(JSON.parse(encoded[i])); break;
      case 'construct+validate':
        operation = i => {
          validator = prepare(engine, definition);
          return validator.validate(inputs[i]);
        }; break;
      default: throw new Error(`Unknown phase ${c.phase}`);
    }
    const expectedCycle = c.inputs.reduce((sum, e) => sum + (e.valid ? 1 : 2), 0);
    function batch(cycles) {
      let checksum = 0;
      for (let cycle = 0; cycle < cycles; cycle++) {
        for (let i = 0; i < inputs.length; i++) {
          checksum += operation(i) ? 1 : 2;
        }
      }
      if (checksum !== cycles * expectedCycle) {
        throw new Error(`Invalid timed checksum for ${engine} / ${name}`);
      }
      return checksum;
    }
    const sampleNs = job.sampleMs * 1e6;
    const warmup = now();
    let cycles = 1;
    do {
      const start = now();
      batch(cycles);
      if (elapsedNs(start) < sampleNs / 2) cycles *= 2;
    } while (elapsedNs(warmup) < job.warmupMs * 1e6);
    const samples = [];
    let checksum = 0;
    for (let sample = 0; sample < job.samples; sample++) {
      const start = now();
      checksum += batch(cycles);
      const elapsed = elapsedNs(start);
      samples.push({ iterations: cycles * inputs.length, elapsedNs: elapsed });
      if (elapsed < sampleNs / 2) cycles *= 2;
    }
    results.push({
      name, schema: c.schema, phase: c.phase, samples, checksum,
      sinkBytes: Buffer.byteLength(JSON.stringify(validator.snapshot())),
    });
  }
}
process.stdout.write(`${JSON.stringify({
  engine, checks, runtime: process.version, results,
})}\n`);
