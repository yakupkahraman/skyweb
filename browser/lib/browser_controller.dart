import 'package:browser/dns_client.dart';
import 'package:browser/engine/engine.dart';
import 'package:flutter/material.dart';

class BrowserController extends ChangeNotifier {
  bool isLoading = false;
  ResolveResult? lastResult;
  FetchResult? fetchResult;

  final ScriptRuntime scriptRuntime = ScriptRuntime();
  final TextEditingController urlController = TextEditingController();

  final List<String> _history = [];
  int _historyIndex = -1;

  bool get canGoBack => _historyIndex > 0;
  bool get canGoForward =>
      _historyIndex >= 0 && _historyIndex < _history.length - 1;

  BrowserController() {
    scriptRuntime.onUpdate = notifyListeners;
    scriptRuntime.onNavigate = (url) => navigateTo(url);
  }

  void goBack() {
    if (canGoBack) {
      _historyIndex--;
      navigateTo(_history[_historyIndex], isHistoryNav: true);
    }
  }

  void goForward() {
    if (canGoForward) {
      _historyIndex++;
      navigateTo(_history[_historyIndex], isHistoryNav: true);
    }
  }

  Future<void> navigateTo(String value, {bool isHistoryNav = false}) async {
    final url = value.trim();
    if (url.isEmpty) return;

    urlController.text = url;

    if (!isHistoryNav) {
      if (_historyIndex >= 0 && _historyIndex < _history.length - 1) {
        _history.removeRange(_historyIndex + 1, _history.length);
      }
      if (_history.isEmpty || _history[_historyIndex] != url) {
        _history.add(url);
        _historyIndex = _history.length - 1;
      }
    }

    isLoading = true;
    fetchResult = null;
    notifyListeners();

    final result = await resolveDomain(url);

    if (result.status == ResolveStatus.success && result.repo != null) {
      final siteResult = await fetchSite(result.repo!);
      scriptRuntime.load(siteResult.script);
      isLoading = false;
      lastResult = result;
      fetchResult = siteResult;
    } else {
      isLoading = false;
      lastResult = result;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    urlController.dispose();
    scriptRuntime.dispose();
    super.dispose();
  }
}
