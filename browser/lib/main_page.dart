import 'package:browser/browser_controller.dart';
import 'package:browser/dns_client.dart';
import 'package:browser/engine/engine.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final BrowserController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BrowserController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Column(
              children: [
                _topBar(),
                Expanded(child: _body()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    final fetchResult = _controller.fetchResult;
    return Container(
      height: 30,
      color: Colors.grey[900],
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _favicon(fetchResult?.faviconUrl),
                  const SizedBox(width: 4),
                  Text(
                    fetchResult?.siteName ?? 'Sky Browser',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.arrow_back, size: 16),
            color: Colors.white,
            disabledColor: Colors.grey[700],
            onPressed: _controller.canGoBack ? _controller.goBack : null,
            tooltip: 'Geri',
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.arrow_forward, size: 16),
            color: Colors.white,
            disabledColor: Colors.grey[700],
            onPressed: _controller.canGoForward ? _controller.goForward : null,
            tooltip: 'İleri',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      'sky://',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: TextField(
                        controller: _controller.urlController,
                        onSubmitted: (val) => _controller.navigateTo(val),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter URL',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _body() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final lastResult = _controller.lastResult;
    if (lastResult == null) {
      return const Center(
        child: Text('Enter a sky:// URL above and press Enter.'),
      );
    }

    switch (lastResult.status) {
      case ResolveStatus.success:
        final fetchResult = _controller.fetchResult;
        if (fetchResult == null) {
          return const Center(child: Text('Site loading...'));
        }
        switch (fetchResult.status) {
          case FetchStatus.success:
            final html = fetchResult.html;
            if (html == null) {
              return const Center(child: Text('No content available.'));
            }
            final cssRules = parseCss(fetchResult.css ?? '');
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      minHeight: constraints.maxHeight,
                    ),
                    child: Container(
                      color: bodyBackgroundColor(cssRules) ?? Colors.black,
                      child: buildWidgetFromHtml(
                        html,
                        cssRules,
                        _controller.scriptRuntime,
                      ),
                    ),
                  ),
                );
              },
            );
          case FetchStatus.notFound:
            return const Center(child: Text('index.html not found.'));
          case FetchStatus.error:
            return const Center(
              child: Text('Error occurred while loading the site.'),
            );
        }
      case ResolveStatus.notFound:
        return const Center(child: Text('This domain is not registered.'));
      case ResolveStatus.error:
        return const Center(child: Text('An error occurred.'));
    }
  }

  Widget _favicon(String? faviconUrl) {
    if (faviconUrl == null) {
      return const Icon(Icons.language_outlined, color: Colors.grey, size: 14);
    }
    return Image.network(
      faviconUrl,
      width: 14,
      height: 14,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.language_outlined, color: Colors.grey, size: 14),
    );
  }
}
