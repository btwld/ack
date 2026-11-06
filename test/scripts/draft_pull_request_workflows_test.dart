import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('draft pull requests', () {
    test('run no workflow jobs', () {
      final triggered = _workflowFiles().where(_triggersOnPullRequest).toList();

      expect(
        triggered.map(_repoPath),
        containsAll(const <String>[
          '.github/workflows/ci.yml',
          '.github/workflows/docs.yml',
          '.github/workflows/preflight.yml',
        ]),
        reason: 'ci, docs, and preflight listen for pull requests',
      );

      for (final file in triggered) {
        final document = loadYaml(file.readAsStringSync()) as YamlMap;
        final pullRequest = _pullRequestTrigger(document, _repoPath(file));
        final types = pullRequest['types'];
        if (types is! List) {
          fail(
            '${_repoPath(file)} must list pull_request types opened, '
            'synchronize, reopened, and ready_for_review',
          );
        }
        expect(
          types.map((type) => '$type'),
          containsAll(const <String>[
            'opened',
            'synchronize',
            'reopened',
            'ready_for_review',
          ]),
          reason:
              '${_repoPath(file)} must run when a draft pull request is '
              'marked ready',
        );

        final jobs = document['jobs'];
        if (jobs is! YamlMap || jobs.entries.isEmpty) {
          fail('${_repoPath(file)} must define jobs to gate');
        }
        for (final entry in jobs.entries) {
          final job = entry.value;
          if (job is! YamlMap) {
            fail('${_repoPath(file)} job ${entry.key} must be a mapping');
          }
          expect(
            _normalizeExpression(job['if']),
            _skipDraftPullRequests,
            reason:
                '${_repoPath(file)} job ${entry.key} must skip while the '
                'pull request is a draft and still run for push, schedule, '
                'and workflow_dispatch',
          );
        }
      }
    });
  });
}

/// Skip draft pull requests. Push, schedule, workflow_dispatch, and
/// workflow_call still run, because those events are not `pull_request`.
const _skipDraftPullRequests =
    "github.event_name != 'pull_request' || "
    'github.event.pull_request.draft == false';

List<File> _workflowFiles() {
  final files =
      Directory('.github/workflows')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) => file.path.endsWith('.yml') || file.path.endsWith('.yaml'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

bool _triggersOnPullRequest(File file) {
  final document = loadYaml(file.readAsStringSync()) as YamlMap;
  final trigger = _trigger(document);
  if (trigger is YamlList) {
    return trigger.any((event) => '$event' == 'pull_request');
  }
  if (trigger is String) return trigger == 'pull_request';
  if (trigger is! YamlMap) return false;
  return trigger.containsKey('pull_request');
}

YamlMap _pullRequestTrigger(YamlMap document, String path) {
  final trigger = _trigger(document);
  if (trigger is! YamlMap) {
    fail('$path must configure pull_request as a mapping so it can set types');
  }
  final pullRequest = trigger['pull_request'];
  if (pullRequest is! YamlMap) {
    fail('$path must set pull_request activity types');
  }
  return pullRequest;
}

/// The workflow trigger map. YAML 1.1 parses a bare `on` key as `true`.
Object? _trigger(YamlMap document) {
  if (document.containsKey('on')) return document['on'];
  if (document.containsKey(true)) return document[true];
  return null;
}

String _normalizeExpression(Object? expression) {
  var value = '${expression ?? ''}'.trim();
  const start = r'${{';
  const end = '}}';
  if (value.startsWith(start) && value.endsWith(end)) {
    value = value.substring(start.length, value.length - end.length).trim();
  }
  return value.replaceAll(RegExp(r'\s+'), ' ');
}

String _repoPath(File file) {
  final prefix = '${Directory.current.path}/';
  final path = file.path;
  if (path.startsWith(prefix)) return path.substring(prefix.length);
  return path;
}
