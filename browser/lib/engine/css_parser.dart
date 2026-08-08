import 'package:html/dom.dart' as dom;

class CssRule {
  final String selector;
  final Map<String, String> declarations;

  CssRule({required this.selector, required this.declarations});
}

List<CssRule> parseCss(String source) {
  final rules = <CssRule>[];

  final cleaned = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  final blockPattern = RegExp(r'([^{}]+)\{([^{}]*)\}');

  for (final match in blockPattern.allMatches(cleaned)) {
    final selector = match.group(1)?.trim() ?? '';
    final body = match.group(2)?.trim() ?? '';

    if (selector.isEmpty || body.isEmpty) continue;

    final declarations = <String, String>{};
    for (final statement in body.split(';')) {
      final trimmed = statement.trim();
      if (trimmed.isEmpty) continue;

      final colonIndex = trimmed.indexOf(':');
      if (colonIndex == -1) continue;

      final property = trimmed.substring(0, colonIndex).trim().toLowerCase();
      final value = trimmed.substring(colonIndex + 1).trim();

      if (property.isNotEmpty && value.isNotEmpty) {
        declarations[property] = value;
      }
    }

    if (declarations.isNotEmpty) {
      rules.add(CssRule(selector: selector, declarations: declarations));
    }
  }

  return rules;
}

Map<String, String> resolveStyle(dom.Element element, List<CssRule> allRules) {
  final resolved = <String, String>{};

  for (final rule in allRules) {
    if (rule.selector == element.localName) {
      resolved.addAll(rule.declarations);
    }
  }

  final classAttr = element.attributes['class'];
  if (classAttr != null) {
    final classNames = classAttr.trim().split(RegExp(r'\s+'));
    for (final rule in allRules) {
      if (rule.selector.startsWith('.')) {
        final className = rule.selector.substring(1);
        if (classNames.contains(className)) {
          resolved.addAll(rule.declarations);
        }
      }
    }
  }

  return resolved;
}