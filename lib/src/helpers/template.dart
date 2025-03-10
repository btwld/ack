class Template {
  final String _content;
  final Map<String, Object?> _data;

  const Template(String content, {Map<String, Object?>? data})
      : _content = content,
        _data = data ?? const {};

  /// Orchestrates both loop parsing and variable replacement
  String _renderTemplate(String template, Map<String, Object?> data) {
    // First handle loops (recursively)
    final withLoopsHandled = _processLoops(template, data);

    // Then handle variable substitutions
    return _processVariables(withLoopsHandled, data);
  }

  // =========================================================
  // LOOP HANDLING
  // =========================================================

  String _processLoops(String template, Map<String, Object?> data) {
    // Find the first loop opening
    final startRegex = RegExp(r'\{\{#each\s+([^\}]+)\}\}\n?');
    final startMatch = startRegex.firstMatch(template);

    if (startMatch == null) {
      return template; // No loop, nothing more to do
    }

    final path = startMatch.group(1)?.trim() ?? '';
    final startTagEnd = startMatch.end;

    // Find matching /each, accounting for nested loops
    final tagRegex = RegExp(r'\{\{(#each\s+[^\}]+|\/each)\}\}');
    int nested = 1;
    int endTagStart = -1;

    for (final match in tagRegex.allMatches(template, startTagEnd)) {
      if (match.group(0)!.startsWith('{{#each')) {
        nested++;
      } else {
        nested--;
      }
      if (nested == 0) {
        endTagStart = match.start;
        break;
      }
    }

    if (endTagStart == -1) {
      // No matching closing tag found
      return template;
    }

    final closingRegex = RegExp(r'\{\{/each\}\}\n?');
    final closingMatch = closingRegex.matchAsPrefix(template, endTagStart);
    final endIndex = closingMatch != null
        ? closingMatch.end
        : endTagStart + '{{/each}}'.length;

    final blockContent = template.substring(startTagEnd, endTagStart);

    // Retrieve the data for iteration
    final loopData = _getNestedValue(data, path);
    final renderedBlock = _renderLoop(loopData, blockContent);

    // Replace the entire `{{#each}} ... {{/each}}` block with the expanded text
    final updatedTemplate =
        template.replaceRange(startMatch.start, endIndex, renderedBlock);

    // Recursively handle any further loops in the updated template
    return _processLoops(updatedTemplate, data);
  }

  String _renderLoop(Object? collection, String blockContent) {
    final result = StringBuffer();
    int index = 0;

    Iterable entries;
    if (collection is List) {
      entries = collection.asMap().entries; // Convert list to map-like entries
    } else if (collection is Map) {
      entries = collection.entries;
    } else {
      return ''; // Invalid input
    }

    for (final entry in entries) {
      final key = entry.key;
      final value = entry.value;
      final localContext = <String, Object?>{
        '@this': collection is List ? value : {'key': key, 'value': value},
        '@index': index++,
      };

      if (value is Map) {
        value.forEach((k, v) {
          if (k is String) localContext[k] = v;
        });
      }

      String rendered = _renderTemplate(blockContent, {...localContext});
      result.write(rendered);
    }

    return result.toString();
  }
  // =========================================================
  // VARIABLE HANDLING
  // =========================================================

  String _processVariables(String template, Map<String, Object?> data) {
    return template.replaceAllMapped(
      RegExp(r'{{\s*([@\w.]+)\s*}}'),
      (match) {
        final path = match.group(1) ?? '';
        final value = _getNestedValue(data, path);

        // Default to 'N/A' if value is null
        return value?.toString() ?? 'N/A';
      },
    );
  }

  // =========================================================
  // LOOKUP HELPER
  // =========================================================

  Object? _getNestedValue(Map<String, Object?> data, String path) {
    final keys = path.split('.');
    Object? current = data;

    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      }
      if (key == 'length') {
        final currentValue = current;
        if (currentValue is Iterable) return currentValue.length;
        if (currentValue is Map) return currentValue.length;
        if (currentValue is String) return currentValue.length;
      }
    }

    return current;
  }

  String render({
    Map<String, Object?>? overrideData,
    TemplateRenderer? customRenderer,
  }) {
    final renderData = overrideData ?? _data;

    if (customRenderer == null) {
      return _renderTemplate(_content, renderData);
    }

    final customRenderedData = <String, Object?>{};

    for (final entry in renderData.entries) {
      final customRendered = customRenderer(entry.key, entry.value);
      customRenderedData[entry.key] = customRendered;
    }

    return _renderTemplate(_content, customRenderedData);
  }
}

typedef TemplateRenderer = String Function(String key, Object? value);
