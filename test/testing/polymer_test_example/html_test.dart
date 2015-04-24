@Timeout(const Duration(minutes: 10))
@TestOn('browser')
library bwu_utils.test.browser.polymer_test_example;

import 'dart:async' show Completer, Future, Stream, Zone;
import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:bwu_utils_dev/testing_browser.dart';
import 'package:bwu_utils/bwu_utils_browser.dart';
export 'package:polymer/init.dart';

final _log = new Logger('bwu_utils.test.shared.test_parse_num');

main() {
  initLogging();
  Zone zone;

  group('getParentElement', () {
    setUp(() async {
      if (zone == null) zone = await initPolymer();
      await Polymer.onReady;
    });

    test('simple DOM elements', () => zone.run(() {
      // set up
      final elem = dom.document.querySelector('#child');

      // exercise
      final parent = getParentElement(getParentElement(elem));

      // verification
      expect(parent, equals(dom.document.querySelector('#parent')));

      // tear down
    }));

    test('Polymer elements', () => zone.run(() {
      // set up
      final elem = dom.document.querySelector('#polymer-child');

      // exercise
      final parent = getParentElement(elem);
      final expectedParent = dom.document.querySelector('#polymer-parent');
      expect(expectedParent, isNotNull);

      // verification
      expect(parent, equals(expectedParent));

      // tear down
    }));

    test('Polymer shadow DOM elements', () => zone.run(() {
      // set up
      final elem = dom.document.querySelector('* /deep/ #shadow-dom-child');
      expect(elem, isNotNull);
      // exercise
      final parent = getParentElement(elem);
      final expectedParent = dom.document.querySelector('#polymer-parent');
      expect(expectedParent, isNotNull);

      // verification
      expect(parent, equals(expectedParent));

      // tear down
    }), timeout: const Timeout(const Duration(minutes: 3)));
  }, skip: 'blocked on https://github.com/dart-lang/polymer-dart/issues/60');
}
