import 'package:html/dom.dart' as dom;

class CssRule {
  final String selector;
  final Map<String, String> declarations;

  CssRule({required this.selector, required this.declarations});
}

final _commentRegex = RegExp(r'/\*.*?\*/', dotAll: true);
final _blockRegex = RegExp(r'([^{}]+)\{([^{}]*)\}');
final _whitespaceRegex = RegExp(r'\s+');

List<CssRule> parseCss(String source) {
  final rules = <CssRule>[];
  final cleaned = source.replaceAll(_commentRegex, '');

  for (final match in _blockRegex.allMatches(cleaned)) {
    final selector = match.group(1)?.trim() ?? '';
    final body = match.group(2)?.trim() ?? '';
    if (selector.isEmpty || body.isEmpty) continue;

    final declarations = <String, String>{};
    for (final statement in body.split(';')) {
      final colonIndex = statement.indexOf(':');
      if (colonIndex == -1) continue;

      final prop = statement.substring(0, colonIndex).trim().toLowerCase();
      final val = statement.substring(colonIndex + 1).trim();
      if (prop.isNotEmpty && val.isNotEmpty) {
        declarations[prop] = val;
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
  final classAttr = element.attributes['class']?.trim();
  final classNames = classAttr?.split(_whitespaceRegex).toSet() ?? const {};

  for (final rule in allRules) {
    if (rule.selector == element.localName) {
      resolved.addAll(rule.declarations);
    } else if (rule.selector.startsWith('.') &&
        classNames.contains(rule.selector.substring(1))) {
      resolved.addAll(rule.declarations);
    }
  }

  final styleAttr = element.attributes['style']?.trim();
  if (styleAttr != null && styleAttr.isNotEmpty) {
    for (final statement in styleAttr.split(';')) {
      final colonIndex = statement.indexOf(':');
      if (colonIndex == -1) continue;

      final prop = statement.substring(0, colonIndex).trim().toLowerCase();
      final val = statement.substring(colonIndex + 1).trim();
      if (prop.isNotEmpty && val.isNotEmpty) {
        resolved[prop] = val;
      }
    }
  }

  return resolved;
}
