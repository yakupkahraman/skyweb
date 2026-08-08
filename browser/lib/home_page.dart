import 'package:browser/dns_client.dart';
import 'package:browser/engine/css_parser.dart';
import 'package:browser/engine/engine.dart';
import 'package:browser/engine/html_to_widget.dart';
import 'package:browser/engine/script_runner.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  ResolveResult? lastResult;
  FetchResult? fetchResult;

  final ScriptRuntime scriptRuntime = ScriptRuntime();

  @override
  void initState() {
    super.initState();
    scriptRuntime.onUpdate = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    scriptRuntime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 30,
              color: Colors.grey[900],
              child: Row(
                children: [
                  SizedBox(
                    height: 30,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 4),
                            _buildFavicon(),
                            const SizedBox(width: 4),
                            Text(
                              fetchResult?.siteName ?? 'Sky Browser',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
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
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: TextField(
                                onSubmitted: (value) => _handleSubmit(value),
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
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lastResult == null) {
      return const Center(
        child: Text('Enter a sky:// URL above and press Enter.'),
      );
    }

    switch (lastResult!.status) {
      case ResolveStatus.success:
        if (fetchResult == null) {
          return const Center(child: Text('Site loading...'));
        }
        switch (fetchResult!.status) {
          case FetchStatus.success:
            final html = fetchResult!.html;
            if (html == null) {
              return const Center(child: Text('No content available.'));
            }
            final cssRules = parseCss(fetchResult!.css ?? '');
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      minHeight: constraints.maxHeight,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: buildWidgetFromHtml(html, cssRules, scriptRuntime),
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

  Future<void> _handleSubmit(String value) async {
    setState(() {
      isLoading = true;
      fetchResult = null;
    });

    final result = await resolveDomain(value);

    if (result.status == ResolveStatus.success && result.repo != null) {
      final siteResult = await fetchSite(result.repo!);
      scriptRuntime.load(siteResult.script);
      setState(() {
        isLoading = false;
        lastResult = result;
        fetchResult = siteResult;
      });
    } else {
      setState(() {
        isLoading = false;
        lastResult = result;
      });
    }
  }

  Widget _buildFavicon() {
    final faviconUrl = fetchResult?.faviconUrl;
    if (faviconUrl == null) {
      return const Icon(Icons.language_outlined, color: Colors.grey, size: 14);
    }
    return Image.network(
      faviconUrl,
      width: 14,
      height: 14,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.language_outlined,
          color: Colors.grey,
          size: 14,
        );
      },
    );
  }
}
