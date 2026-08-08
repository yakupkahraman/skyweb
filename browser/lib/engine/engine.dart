import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

export 'css.dart';
export 'html.dart';
export 'script.dart';

enum FetchStatus { success, notFound, error }

class FetchResult {
  final FetchStatus status;
  final String? html;
  final String? css;
  final String? script;
  final String? siteName;
  final String? faviconUrl;

  FetchResult({
    required this.status,
    this.html,
    this.css,
    this.script,
    this.siteName,
    this.faviconUrl,
  });
}

String _baseUrl(String repo) {
  final parts = repo.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.length < 2) {
    return 'https://raw.githubusercontent.com/$repo/main';
  }
  final owner = parts[0];
  final name = parts[1];
  final path = parts.sublist(2).join('/');
  final suffix = path.isEmpty ? '' : '/$path';
  return 'https://raw.githubusercontent.com/$owner/$name/main$suffix';
}

Future<String?> _fetchOptional(String repo, String fileName) async {
  try {
    final uri = Uri.parse('${_baseUrl(repo)}/$fileName');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    }
  } catch (e) {
    debugPrint('Error fetching $fileName: $e');
  }
  return null;
}

Future<FetchResult> fetchSite(String repo) async {
  final base = _baseUrl(repo);
  final uri = Uri.parse('$base/index.html');

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final htmlBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      final document = html_parser.parse(htmlBody);

      final siteName = document.querySelector('title')?.text;
      final iconSrc = document.querySelector('icon')?.attributes['src'];
      final faviconUrl = iconSrc != null ? '$base/$iconSrc' : null;

      // Fetch CSS and script in parallel for performance improvement
      final optionalAssets = await Future.wait([
        _fetchOptional(repo, 'styles.css'),
        _fetchOptional(repo, 'script.dart'),
      ]);

      return FetchResult(
        status: FetchStatus.success,
        html: htmlBody,
        css: optionalAssets[0] ?? '',
        script: optionalAssets[1],
        siteName: siteName,
        faviconUrl: faviconUrl,
      );
    } else if (response.statusCode == 404) {
      return FetchResult(status: FetchStatus.notFound);
    } else {
      return FetchResult(status: FetchStatus.error);
    }
  } catch (e) {
    return FetchResult(status: FetchStatus.error);
  }
}
