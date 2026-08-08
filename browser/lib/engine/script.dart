import 'dart:convert';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScriptRuntime {
  final Map<String, TextEditingController> _inputs = {};
  final Map<String, String> _texts = {};

  Program? _program;
  String? _compileError;

  VoidCallback? onUpdate;
  void Function(String url)? onNavigate;

  String? get compileError => _compileError;
  bool get hasScript => _program != null;

  void load(String? source) {
    dispose();
    _inputs.clear();
    _texts.clear();
    _program = null;
    _compileError = null;

    if (source == null || source.trim().isEmpty) return;

    try {
      final compiler = Compiler();
      compiler.entrypoints.add('package:sky/script.dart');
      _program = compiler.compile({
        'sky': {'script.dart': source},
      });
    } catch (e) {
      _compileError = e.toString();
    }
  }

  void navigate(String url) => onNavigate?.call(url);

  TextEditingController controllerFor(String id) =>
      _inputs.putIfAbsent(id, TextEditingController.new);

  String textFor(String id, String fallback) => _texts[id] ?? fallback;

  void call(String handler) {
    final program = _program;
    if (program == null) return;

    try {
      final runtime = Runtime.ofProgram(program);
      runtime.executeLib('package:sky/script.dart', handler, [
        $Closure((runtime, target, args) {
          final id = args[0]?.$value as String? ?? '';
          return $String(_inputs[id]?.text ?? '');
        }),
        $Closure((runtime, target, args) {
          final url = args[0]?.$value as String? ?? '';
          final body = args[1]?.$value as String? ?? '';
          final resultId = args.length > 2 ? args[2]?.$value as String? : null;
          _post(url, body, resultId);
          return null;
        }),
        $Closure((runtime, target, args) {
          final id = args[0]?.$value as String? ?? '';
          final value = args[1]?.$value as String? ?? '';
          _texts[id] = value;
          onUpdate?.call();
          return null;
        }),
      ]);
    } catch (e) {
      debugPrint('Script error in "$handler": $e');
    }
  }

  Future<void> _post(String url, String body, String? resultId) async {
    void write(String val) {
      if (resultId == null) return;
      _texts[resultId] = val;
      onUpdate?.call();
    }

    write('...');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      String msg;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          msg = decoded['error'].toString();
        } else if (decoded is Map && decoded['success'] == true) {
          msg = 'ok';
        } else {
          msg = response.body;
        }
      } catch (_) {
        msg = response.body;
      }
      write('${response.statusCode}: $msg');
    } catch (e) {
      write('error: $e');
    }
  }

  void dispose() {
    for (final controller in _inputs.values) {
      controller.dispose();
    }
  }
}
