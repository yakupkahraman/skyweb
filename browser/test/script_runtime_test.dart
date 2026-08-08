import 'package:browser/engine/script.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScriptRuntime Tests', () {
    test('Counter state persists across call() invocations', () {
      final runtime = ScriptRuntime();

      const scriptSource = '''
      int sayi = 0;

      void main() {
        setText('sayac', '0');
      }

      void arttir() {
        sayi++;
        setText('sayac', sayi.toString());
      }
      ''';

      runtime.load(scriptSource);

      expect(runtime.lastError, isNull);
      expect(runtime.textFor('sayac', ''), equals('0'));

      runtime.call('arttir');
      expect(runtime.lastError, isNull);
      expect(runtime.textFor('sayac', ''), equals('1'));

      runtime.call('arttir');
      expect(runtime.lastError, isNull);
      expect(runtime.textFor('sayac', ''), equals('2'));

      runtime.dispose();
    });

    test('getText bridge reads current text state', () {
      final runtime = ScriptRuntime();

      const scriptSource = '''
      void testGetText() {
        setText('status', 'Initial');
        var val = getText('status');
        setText('result', 'Read: ' + val);
      }
      ''';

      runtime.load(scriptSource);
      runtime.call('testGetText');

      expect(runtime.lastError, isNull);
      expect(runtime.textFor('result', ''), equals('Read: Initial'));

      runtime.dispose();
    });

    test('get bridge returns raw response body', () {
      final runtime = ScriptRuntime();

      const scriptSource = '''
      void testGet() {
        get('https://skydns.yakupkahraman.com/resolve?domain=docs&tld=sky', 'output');
      }
      ''';

      runtime.load(scriptSource);
      runtime.call('testGet');

      expect(runtime.lastError, isNull);
      expect(runtime.textFor('output', ''), equals('...'));

      runtime.dispose();
    });

    test('setTimeout schedules delayed execution', () async {
      final runtime = ScriptRuntime();

      const scriptSource = '''
      void startTimer() {
        setText('status', 'Waiting');
        setTimeout('onTimeout', 100);
      }

      void onTimeout() {
        setText('status', 'Done');
      }
      ''';

      runtime.load(scriptSource);
      runtime.call('startTimer');

      expect(runtime.textFor('status', ''), equals('Waiting'));

      await Future.delayed(const Duration(milliseconds: 150));

      expect(runtime.textFor('status', ''), equals('Done'));
      expect(runtime.lastError, isNull);

      runtime.dispose();
    });

    test('clearInterval stops periodic execution', () async {
      final runtime = ScriptRuntime();

      const scriptSource = '''
      int ticks = 0;
      void main() {
        setInterval('tick', 50);
      }

      void tick() {
        ticks++;
        setText('clock', ticks.toString());
        if (ticks == 2) {
          clearInterval('tick');
        }
      }
      ''';

      runtime.load(scriptSource);

      await Future.delayed(const Duration(milliseconds: 250));

      // Should stop at exactly 2 ticks because of clearInterval('tick')
      expect(runtime.textFor('clock', ''), equals('2'));

      runtime.dispose();
    });

    test('setInterval replaces previous timer with same handler name (deduping)', () async {
      final runtime = ScriptRuntime();

      const scriptSource = '''
      int ticks = 0;

      void startAgain() {
        setInterval('tick', 50);
      }

      void tick() {
        ticks++;
        setText('clock', ticks.toString());
      }
      ''';

      runtime.load(scriptSource);

      // Call startAgain 3 times
      runtime.call('startAgain');
      runtime.call('startAgain');
      runtime.call('startAgain');

      await Future.delayed(const Duration(milliseconds: 180));

      // If deduping works, ticks should be around 3 (from single interval), not 9 (from 3 parallel intervals)
      final val = int.parse(runtime.textFor('clock', '0'));
      expect(val, lessThan(6));

      runtime.dispose();
    });
  });
}
