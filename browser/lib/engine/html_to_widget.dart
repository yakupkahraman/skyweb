import 'package:browser/engine/css_parser.dart';
import 'package:browser/engine/script_runner.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

Widget buildWidgetFromHtml(
  String htmlSource,
  List<CssRule> cssRules,
  ScriptRuntime runtime,
) {
  final document = html_parser.parse(htmlSource);
  final body = document.body;

  if (body == null) {
    return const SizedBox.shrink();
  }

  final style = resolveStyle(body, cssRules);

  final widgets = <Widget>[];
  for (final node in body.nodes) {
    if (node is dom.Element) {
      final widget = _buildElement(node, cssRules, runtime);
      if (widget != null) {
        widgets.add(widget);
      }
    }
  }

  return Column(
    mainAxisAlignment: parseMainAxis(style['main-axis']),
    crossAxisAlignment: parseCrossAxis(style['cross-axis']),
    mainAxisSize: MainAxisSize.max,
    spacing: parseGap(style['gap']) ?? 0,
    children: widgets,
  );
}

Widget _buildChildren(
  dom.Element element,
  List<CssRule> cssRules,
  ScriptRuntime runtime,
) {
  final widgets = <Widget>[];

  for (final node in element.nodes) {
    if (node is dom.Element) {
      final widget = _buildElement(node, cssRules, runtime);
      if (widget != null) {
        widgets.add(widget);
      }
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: widgets,
  );
}

Widget _buildFlexChildren(
  dom.Element element,
  List<CssRule> cssRules,
  ScriptRuntime runtime,
  Map<String, String> style,
) {
  final widgets = <Widget>[];

  for (final node in element.nodes) {
    if (node is dom.Element) {
      final widget = _buildElement(node, cssRules, runtime);
      if (widget != null) {
        widgets.add(widget);
      }
    }
  }

  final isColumn = style['direction']?.trim() == 'column';
  final mainAxis = parseMainAxis(style['main-axis']);
  final crossAxis = parseCrossAxis(style['cross-axis']);
  final gap = parseGap(style['gap']) ?? 0;

  if (isColumn) {
    return Column(
      mainAxisAlignment: mainAxis,
      crossAxisAlignment: crossAxis,
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: widgets,
    );
  }

  return Row(
    mainAxisAlignment: mainAxis,
    crossAxisAlignment: crossAxis,
    mainAxisSize: MainAxisSize.min,
    spacing: gap,
    children: widgets,
  );
}

Widget? _buildElement(
  dom.Element element,
  List<CssRule> cssRules,
  ScriptRuntime runtime,
) {
  switch (element.localName) {
    case 'div':
      final style = resolveStyle(element, cssRules);

      final content = _buildFlexChildren(element, cssRules, runtime, style);

      final backgroundColor = parseColor(style['background-color']);
      final padding = parsePadding(style['padding']);

      Widget result = content;

      if (padding != null) {
        result = Padding(padding: padding, child: result);
      }

      if (backgroundColor != null) {
        result = Container(color: backgroundColor, child: result);
      }

      return result;
    case 'p':
      final style = resolveStyle(element, cssRules);
      final color = parseColor(style['color']) ?? Colors.white;
      final fontSize = parseFontSize(style['font-size']) ?? 16;
      final id = element.attributes['id'];
      final text = id != null
          ? runtime.textFor(id, element.text)
          : element.text;
      return Text(
        text,
        style: TextStyle(fontSize: fontSize, color: color),
      );
    case 'h1':
      final style = resolveStyle(element, cssRules);
      final color = parseColor(style['color']) ?? Colors.white;
      final fontSize = parseFontSize(style['font-size']) ?? 24;
      return Text(
        element.text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );
    case 'h2':
      final style = resolveStyle(element, cssRules);
      final color = parseColor(style['color']) ?? Colors.white;
      final fontSize = parseFontSize(style['font-size']) ?? 20;
      return Text(
        element.text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );
    case 'h3':
      final style = resolveStyle(element, cssRules);
      final color = parseColor(style['color']) ?? Colors.white;
      final fontSize = parseFontSize(style['font-size']) ?? 18;
      return Text(
        element.text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );
    case 'ul':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: element.children
            .where((li) => li.localName == 'li')
            .map(
              (li) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: _buildChildren(li, cssRules, runtime)),
                ],
              ),
            )
            .toList(),
      );
    case 'ol':
      int index = 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: element.children.where((li) => li.localName == 'li').map((
          li,
        ) {
          final numbered = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$index. '),
              Expanded(child: _buildChildren(li, cssRules, runtime)),
            ],
          );
          index++;
          return numbered;
        }).toList(),
      );
    case 'a':
      return GestureDetector(
        onTap: () {},
        child: Text(
          element.text,
          style: const TextStyle(
            color: Colors.lightBlueAccent,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    case 'img':
      final src = element.attributes['src'] ?? '';
      if (src.isEmpty) {
        return const Icon(Icons.broken_image, color: Colors.grey);
      }
      return Image.network(
        src,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.grey);
        },
      );
    case 'input':
      final style = resolveStyle(element, cssRules);
      final id = element.attributes['id'] ?? '';
      final width = parseGap(style['width']) ?? 240;
      return SizedBox(
        width: width,
        child: TextField(
          controller: runtime.controllerFor(id),
          style: TextStyle(
            fontSize: parseFontSize(style['font-size']) ?? 14,
            color: parseColor(style['color']) ?? Colors.white,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: element.attributes['placeholder'],
            hintStyle: const TextStyle(color: Colors.grey),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
      );
    case 'button':
      final handler = element.attributes['onclick'];
      return ElevatedButton(
        onPressed: handler == null ? null : () => runtime.call(handler),
        child: Text(element.text),
      );
    default:
      return null;
  }
}

Color? parseColor(String? raw) {
  if (raw == null) return null;
  final value = raw.trim().toLowerCase();

  const namedColors = {
    'black': Colors.black,
    'white': Colors.white,
    'red': Colors.red,
    'green': Colors.green,
    'blue': Colors.blue,
    'yellow': Colors.yellow,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'grey': Colors.grey,
    'gray': Colors.grey,
  };

  if (namedColors.containsKey(value)) {
    return namedColors[value];
  }

  if (value.startsWith('#')) {
    var hex = value.substring(1);
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) {
      hex = 'ff$hex';
    }
    final intValue = int.tryParse(hex, radix: 16);
    if (intValue != null) {
      return Color(intValue);
    }
  }

  return null;
}

double? parseFontSize(String? raw) {
  if (raw == null) return null;
  final match = RegExp(r'^(\d+(\.\d+)?)px$').firstMatch(raw.trim());
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}

EdgeInsets? parsePadding(String? raw) {
  if (raw == null) return null;

  final parts = raw.trim().split(RegExp(r'\s+'));
  final values = <double>[];

  for (final part in parts) {
    final match = RegExp(r'^(\d+(\.\d+)?)px$').firstMatch(part);
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!);
    if (value == null) return null;
    values.add(value);
  }

  switch (values.length) {
    case 1:
      return EdgeInsets.all(values[0]);
    case 2:
      return EdgeInsets.symmetric(vertical: values[0], horizontal: values[1]);
    case 4:
      return EdgeInsets.fromLTRB(values[3], values[0], values[1], values[2]);
    default:
      return null;
  }
}

double? parseGap(String? raw) {
  if (raw == null) return null;
  final match = RegExp(r'^(\d+(\.\d+)?)px$').firstMatch(raw.trim());
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}

MainAxisAlignment parseMainAxis(String? raw) {
  switch (raw?.trim()) {
    case 'center':
      return MainAxisAlignment.center;
    case 'end':
      return MainAxisAlignment.end;
    case 'space-between':
      return MainAxisAlignment.spaceBetween;
    case 'space-around':
      return MainAxisAlignment.spaceAround;
    case 'start':
    default:
      return MainAxisAlignment.start;
  }
}

CrossAxisAlignment parseCrossAxis(String? raw) {
  switch (raw?.trim()) {
    case 'center':
      return CrossAxisAlignment.center;
    case 'end':
      return CrossAxisAlignment.end;
    case 'stretch':
      return CrossAxisAlignment.stretch;
    case 'start':
    default:
      return CrossAxisAlignment.start;
  }
}

Color? bodyBackgroundColor(List<CssRule> cssRules) {
  for (final rule in cssRules) {
    if (rule.selector == 'body') {
      final color = parseColor(rule.declarations['background-color']);
      if (color != null) return color;
    }
  }
  return null;
}
