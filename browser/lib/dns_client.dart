import 'dart:convert';

import 'package:http/http.dart' as http;

enum ResolveStatus { success, notFound, error }

class ResolveResult {
  final ResolveStatus status;
  final String? repo;

  ResolveResult({required this.status, this.repo});
}

final Map<String, String> _domainCache = {};

Future<ResolveResult> resolveDomain(String url) async {
  final parts = url.trim().split('.');
  if (parts.length != 2) {
    return ResolveResult(status: ResolveStatus.error);
  }
  final domainPart = parts[0];
  final tldPart = parts[1];
  
  final cacheKey = '$domainPart.$tldPart';

  if (_domainCache.containsKey(cacheKey)) {
    return ResolveResult(status: ResolveStatus.success, repo: _domainCache[cacheKey]);
  }

  final uri = Uri.https('skydns.yakupkahraman.com', '/resolve', {
    'domain': domainPart,
    'tld': tldPart,
  });

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final repo = data['repo'] as String?;
      if (repo != null) {
        _domainCache[cacheKey] = repo;
      }
      return ResolveResult(status: ResolveStatus.success, repo: repo);
    } else if (response.statusCode == 404) {
      return ResolveResult(status: ResolveStatus.notFound);
    } else {
      return ResolveResult(status: ResolveStatus.error);
    }
  } catch (e) {
    return ResolveResult(status: ResolveStatus.error);
  }
}