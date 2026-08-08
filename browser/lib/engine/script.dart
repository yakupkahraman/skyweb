import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScriptRuntime {
  final Map<String, TextEditingController> _inputs = {};
  final Map<String, String> _texts = {};
  final Map<String, Timer> _timeoutTimers = {};
  final Map<String, Timer> _intervalTimers = {};

  Program? _program;
  Runtime? _runtime;
  String? _lastError;
  int _sessionId = 0;

  VoidCallback? onUpdate;
  void Function(String url)? onNavigate;

  String? get lastError => _lastError;
  bool get hasScript => _runtime != null || _program != null;

  void load(String? source) {
    dispose();

    if (source == null || source.trim().isEmpty) return;

    try {
      final compiler = Compiler();

      _registerBridgeDeclarations(compiler);

      compiler.entrypoints.add('package:sky/script.dart');
      _program = compiler.compile({
        'sky': {'script.dart': source},
      });

      final runtime = Runtime.ofProgram(_program!);
      _registerBridgeFunctions(runtime, _sessionId);
      _runtime = runtime;

      _autoRunMain();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Script compilation error: $e');
      onUpdate?.call();
    }
  }

  void _registerBridgeDeclarations(Compiler compiler) {
    compiler.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'package:sky/script.dart',
        'getInput',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'id',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    );

    compiler.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'package:sky/script.dart',
        'setText',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'id',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'text',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    );

    compiler.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'package:sky/script.dart',
        'getText',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'id',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    );

    compiler.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'package:sky/script.dart',
        'get',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'url',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'resultId',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
      ),
    );

    compiler.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'package:sky/script.dart',
        'post',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'url',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'body',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'resultId',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
      ),
    );

    compiler.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'package:sky/script.dart',
        'setTimeout',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'handler',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'milliseconds',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    );

    compiler.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'package:sky/script.dart',
        'clearTimeout',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'handler',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    );

    compiler.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'package:sky/script.dart',
        'setInterval',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'handler',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'milliseconds',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    );

    compiler.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        'package:sky/script.dart',
        'clearInterval',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'handler',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    );
  }

  void _registerBridgeFunctions(Runtime runtime, int currentSessionId) {
    runtime.registerBridgeFunc(
      'package:sky/script.dart',
      'getInput',
      _BridgeGetInput(_inputs).call,
    );
    runtime.registerBridgeFunc(
      'package:sky/script.dart',
      'setText',
      _BridgeSetText(_texts, () => onUpdate?.call()).call,
    );
    runtime.registerBridgeFunc(
      'package:sky/script.dart',
      'getText',
      _BridgeGetText(_texts).call,
    );
    runtime.registerBridgeFunc(
      'package:sky/script.dart',
      'get',
      _BridgeGet(_texts, currentSessionId, () => _sessionId, () => onUpdate?.call()).call,
    );
    runtime.registerBridgeFunc(
      'package:sky/script.dart',
      'post',
      _BridgePost(_texts, currentSessionId, () => _sessionId, () => onUpdate?.call()).call,
    );
    runtime.registerBridgeFunc(
      'package:sky/script.dart',
      'setTimeout',
      _BridgeSetTimeout(_scheduleTimeout).call,
    );
    runtime.registerBridgeFunc(
      'package:sky/script.dart',
      'clearTimeout',
      _BridgeClearTimeout(_clearTimeout).call,
    );
    runtime.registerBridgeFunc(
      'package:sky/script.dart',
      'setInterval',
      _BridgeSetInterval(_scheduleInterval).call,
    );
    runtime.registerBridgeFunc(
      'package:sky/script.dart',
      'clearInterval',
      _BridgeClearInterval(_clearInterval).call,
    );
  }

  void _scheduleTimeout(String handler, int ms) {
    _clearTimeout(handler);
    final effectiveMs = ms < 16 ? 16 : ms;
    final currentSession = _sessionId;

    _timeoutTimers[handler] = Timer(Duration(milliseconds: effectiveMs), () {
      _timeoutTimers.remove(handler);
      if (_sessionId != currentSession) return;
      call(handler);
    });
  }

  void _clearTimeout(String handler) {
    _timeoutTimers.remove(handler)?.cancel();
  }

  void _scheduleInterval(String handler, int ms) {
    _clearInterval(handler);
    // Enforce 50ms minimum floor to prevent UI locks
    final effectiveMs = ms < 50 ? 50 : ms;
    final currentSession = _sessionId;

    _intervalTimers[handler] = Timer.periodic(
      Duration(milliseconds: effectiveMs),
      (timer) {
        if (_sessionId != currentSession) {
          timer.cancel();
          _intervalTimers.remove(handler);
          return;
        }
        call(handler);
      },
    );
  }

  void _clearInterval(String handler) {
    _intervalTimers.remove(handler)?.cancel();
  }

  bool _hasFunction(Program program, String name) {
    final libId = program.bridgeLibraryMappings['package:sky/script.dart'];
    if (libId == null) return false;
    final decls = program.topLevelDeclarations[libId];
    return decls != null && decls.containsKey(name);
  }

  void _autoRunMain() {
    final program = _program;
    final runtime = _runtime;
    if (program == null || runtime == null) return;

    if (!_hasFunction(program, 'main')) return;

    try {
      runtime.executeLib('package:sky/script.dart', 'main', []);
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Script error in main(): $e');
      onUpdate?.call();
    }
  }

  void navigate(String url) => onNavigate?.call(url);

  TextEditingController controllerFor(String id) =>
      _inputs.putIfAbsent(id, TextEditingController.new);

  String textFor(String id, String fallback) => _texts[id] ?? fallback;

  void call(String handler) {
    final runtime = _runtime;
    if (runtime == null) return;

    try {
      runtime.executeLib('package:sky/script.dart', handler, []);
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Script error in "$handler": $e');
      onUpdate?.call();
    }
  }

  void dispose() {
    _sessionId++;
    for (final timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();

    for (final timer in _intervalTimers.values) {
      timer.cancel();
    }
    _intervalTimers.clear();

    for (final controller in _inputs.values) {
      controller.dispose();
    }
    _inputs.clear();
    _texts.clear();
    _program = null;
    _runtime = null;
    _lastError = null;
  }
}

class _BridgeGetInput implements EvalCallable {
  final Map<String, TextEditingController> _inputs;
  const _BridgeGetInput(this._inputs);

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final id = args[0]?.$value as String? ?? '';
    return $String(_inputs[id]?.text ?? '');
  }
}

class _BridgeSetText implements EvalCallable {
  final Map<String, String> _texts;
  final VoidCallback _onUpdate;
  const _BridgeSetText(this._texts, this._onUpdate);

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final id = args[0]?.$value as String? ?? '';
    final val = args[1]?.$value as String? ?? '';
    _texts[id] = val;
    _onUpdate();
    return null;
  }
}

class _BridgeGetText implements EvalCallable {
  final Map<String, String> _texts;
  const _BridgeGetText(this._texts);

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final id = args[0]?.$value as String? ?? '';
    return $String(_texts[id] ?? '');
  }
}

class _BridgeSetTimeout implements EvalCallable {
  final void Function(String handler, int ms) _onTimeout;
  const _BridgeSetTimeout(this._onTimeout);

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final handler = args[0]?.$value as String? ?? '';
    final ms = args[1]?.$value as int? ?? 0;
    _onTimeout(handler, ms);
    return null;
  }
}

class _BridgeClearTimeout implements EvalCallable {
  final void Function(String handler) _onClear;
  const _BridgeClearTimeout(this._onClear);

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final handler = args[0]?.$value as String? ?? '';
    _onClear(handler);
    return null;
  }
}

class _BridgeSetInterval implements EvalCallable {
  final void Function(String handler, int ms) _onInterval;
  const _BridgeSetInterval(this._onInterval);

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final handler = args[0]?.$value as String? ?? '';
    final ms = args[1]?.$value as int? ?? 0;
    _onInterval(handler, ms);
    return null;
  }
}

class _BridgeClearInterval implements EvalCallable {
  final void Function(String handler) _onClear;
  const _BridgeClearInterval(this._onClear);

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final handler = args[0]?.$value as String? ?? '';
    _onClear(handler);
    return null;
  }
}

class _BridgeGet implements EvalCallable {
  final Map<String, String> _texts;
  final int _sessionId;
  final int Function() _getCurrentSessionId;
  final VoidCallback _onUpdate;

  const _BridgeGet(
    this._texts,
    this._sessionId,
    this._getCurrentSessionId,
    this._onUpdate,
  );

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final url = args[0]?.$value as String? ?? '';
    final resultId = args.length > 1 ? args[1]?.$value as String? : null;

    _performGet(url, resultId);
    return null;
  }

  Future<void> _performGet(String url, String? resultId) async {
    void write(String val) {
      if (resultId == null) return;
      if (_getCurrentSessionId() != _sessionId) return;
      _texts[resultId] = val;
      _onUpdate();
    }

    write('...');
    try {
      final response = await http.get(Uri.parse(url));
      if (_getCurrentSessionId() != _sessionId) return;
      write(response.body);
    } catch (e) {
      if (_getCurrentSessionId() != _sessionId) return;
      write('error: $e');
    }
  }
}

class _BridgePost implements EvalCallable {
  final Map<String, String> _texts;
  final int _sessionId;
  final int Function() _getCurrentSessionId;
  final VoidCallback _onUpdate;

  const _BridgePost(
    this._texts,
    this._sessionId,
    this._getCurrentSessionId,
    this._onUpdate,
  );

  @override
  $Value? call(Runtime runtime, $Value? target, List<$Value?> args) {
    final url = args[0]?.$value as String? ?? '';
    final body = args[1]?.$value as String? ?? '';
    final resultId = args.length > 2 ? args[2]?.$value as String? : null;

    _performPost(url, body, resultId);
    return null;
  }

  Future<void> _performPost(String url, String body, String? resultId) async {
    void write(String val) {
      if (resultId == null) return;
      if (_getCurrentSessionId() != _sessionId) return;
      _texts[resultId] = val;
      _onUpdate();
    }

    write('...');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (_getCurrentSessionId() != _sessionId) return;
      write(response.body);
    } catch (e) {
      if (_getCurrentSessionId() != _sessionId) return;
      write('error: $e');
    }
  }
}
