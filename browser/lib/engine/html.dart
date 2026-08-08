import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'css.dart';
import 'script.dart';

final _pxRegex = RegExp(r'^(\d+(?:\.\d+)?)px$');
final _whitespaceRegex = RegExp(r'\s+');

const _namedColors = <String, Color>{
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

Widget buildWidgetFromHtml(
  String htmlSource,
  List<CssRule> cssRules,
  ScriptRuntime runtime,
) {
  final document = html_parser.parse(htmlSource);
  final body = document.body;
  if (body == null) return const SizedBox.shrink();

  final style = resolveStyle(body, cssRules);
  final children = _buildChildWidgets(body, cssRules, runtime);

  return Column(
    mainAxisAlignment: parseMainAxis(style['main-axis']),
    crossAxisAlignment: parseCrossAxis(style['cross-axis']),
    mainAxisSize: MainAxisSize.max,
    spacing: parseGap(style['gap']) ?? 0,
    children: children,
  );
}

List<Widget> _buildChildWidgets(
  dom.Element element,
  List<CssRule> cssRules,
  ScriptRuntime runtime,
) {
  final widgets = <Widget>[];
  for (final node in element.nodes) {
    if (node is dom.Element) {
      final widget = _buildElement(node, cssRules, runtime);
      if (widget != null) widgets.add(widget);
    }
  }
  return widgets;
}

Widget? _buildElement(
  dom.Element element,
  List<CssRule> cssRules,
  ScriptRuntime runtime,
) {
  switch (element.localName) {
    case 'div':
      final style = resolveStyle(element, cssRules);
      final children = _buildChildWidgets(element, cssRules, runtime);
      final isColumn = style['direction']?.trim() == 'column';
      final mainAxis = parseMainAxis(style['main-axis']);
      final crossAxis = parseCrossAxis(style['cross-axis']);
      final gap = parseGap(style['gap']) ?? 0;

      Widget result = isColumn
          ? Column(
              mainAxisAlignment: mainAxis,
              crossAxisAlignment: crossAxis,
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: children,
            )
          : Row(
              mainAxisAlignment: mainAxis,
              crossAxisAlignment: crossAxis,
              mainAxisSize: MainAxisSize.min,
              spacing: gap,
              children: children,
            );

      final padding = parsePadding(style['padding']);
      final bg = parseColor(style['background-color']);

      if (padding != null) result = Padding(padding: padding, child: result);
      if (bg != null) result = Container(color: bg, child: result);
      return result;

    case 'p':
      return _buildText(element, cssRules, runtime, defaultSize: 16);
    case 'h1':
      return _buildText(
        element,
        cssRules,
        runtime,
        defaultSize: 24,
        fontWeight: FontWeight.bold,
      );
    case 'h2':
      return _buildText(
        element,
        cssRules,
        runtime,
        defaultSize: 20,
        fontWeight: FontWeight.bold,
      );
    case 'h3':
      return _buildText(
        element,
        cssRules,
        runtime,
        defaultSize: 18,
        fontWeight: FontWeight.bold,
      );

    case 'ul':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: element.children
            .where((li) => li.localName == 'li')
            .map((li) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: _buildChildWidgets(li, cssRules, runtime),
                      ),
                    ),
                  ],
                ))
            .toList(),
      );

    case 'ol':
      int index = 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: element.children
            .where((li) => li.localName == 'li')
            .map((li) {
              final row = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${index++}. '),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: _buildChildWidgets(li, cssRules, runtime),
                    ),
                  ),
                ],
              );
              return row;
            })
            .toList(),
      );

    case 'a':
      final style = resolveStyle(element, cssRules);
      final href = element.attributes['href']?.trim();
      final isNavigable =
          href != null && href.isNotEmpty && !href.contains('://');
      final color = parseColor(style['color']) ??
          (isNavigable ? Colors.lightBlueAccent : Colors.grey);
      final link = Text(
        element.text,
        style: TextStyle(
          fontSize: parseFontSize(style['font-size']) ?? 16,
          color: color,
          decoration: TextDecoration.underline,
          decorationColor: color,
        ),
      );

      if (!isNavigable) return link;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => runtime.navigate(href),
          child: link,
        ),
      );

    case 'img':
      final src = element.attributes['src'] ?? '';
      if (src.isEmpty) return const Icon(Icons.broken_image, color: Colors.grey);
      return Image.network(
        src,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );

    case 'input':
      final style = resolveStyle(element, cssRules);
      final id = element.attributes['id'] ?? '';
      return SizedBox(
        width: parseGap(style['width']) ?? 240,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

Widget _buildText(
  dom.Element element,
  List<CssRule> cssRules,
  ScriptRuntime runtime, {
  required double defaultSize,
  FontWeight? fontWeight,
}) {
  final style = resolveStyle(element, cssRules);
  final color = parseColor(style['color']) ?? Colors.white;
  final fontSize = parseFontSize(style['font-size']) ?? defaultSize;
  final id = element.attributes['id'];
  final text = id != null ? runtime.textFor(id, element.text) : element.text;
  return Text(
    text,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    ),
  );
}

Color? parseColor(String? raw) {
  if (raw == null) return null;
  final value = raw.trim().toLowerCase();
  if (_namedColors.containsKey(value)) return _namedColors[value];

  if (value.startsWith('#')) {
    var hex = value.substring(1);
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) hex = 'ff$hex';
    final intValue = int.tryParse(hex, radix: 16);
    if (intValue != null) return Color(intValue);
  }
  return null;
}

double? parsePxValue(String? raw) {
  if (raw == null) return null;
  final match = _pxRegex.firstMatch(raw.trim());
  return match == null ? null : double.tryParse(match.group(1)!);
}

double? parseFontSize(String? raw) => parsePxValue(raw);
double? parseGap(String? raw) => parsePxValue(raw);

EdgeInsets? parsePadding(String? raw) {
  if (raw == null) return null;
  final parts = raw.trim().split(_whitespaceRegex);
  final values = <double>[];

  for (final part in parts) {
    final val = parsePxValue(part);
    if (val == null) return null;
    values.add(val);
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
