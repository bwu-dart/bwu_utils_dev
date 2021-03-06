@Timeout(const Duration(minutes: 10))
@TestOn('browser')
library bwu_utils_dev.test.testing.polymer_test_example;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';
import 'package:bwu_utils_dev/testing_browser.dart';
import 'package:bwu_utils/bwu_utils_browser.dart';
export 'package:polymer/init.dart';
import 'child_element.dart';
import 'app_element.dart';

final _log = new Logger('bwu_utils.test.shared.test_parse_num');

@whenPolymerReady
init() {
  initLogging();
  // just to silence the analyzer
  dom.document.querySelector('app-element') as AppElement;

  group('getParentElement', () {
    setUp(() async {});

    test('simple DOM elements', () {
      // set up
      final elem = dom.document.querySelector('#child');

      // exercise
      final parent = getParentElement(getParentElement(elem));

      // verification
      expect(parent, equals(dom.document.querySelector('#parent')));

      // tear down
    });

    test('Polymer elements', () {
      // set up
      final elem = dom.document.querySelector('#polymer-child') as ChildElement;

      // exercise
      final parent = getParentElement(elem);
      final expectedParent = dom.document.querySelector('#polymer-parent');
      expect(expectedParent, isNotNull);

      // verification
      expect(parent, equals(expectedParent));

      // tear down
    });

    test('Polymer shadow DOM elements', () {
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
    }, timeout: const Timeout(const Duration(minutes: 3)));
  });
}
