@HtmlImport('child_element.html')
library bwu_utils_dev.test.testing.polymer_test_example.child_element;

import 'dart:html' as dom;
import 'package:polymer/polymer.dart';

@CustomTag('child-element')
class ChildElement extends PolymerElement {
  ChildElement.created() : super.created();

  @override
  attached() {
    super.attached();
    ($['some-div'] as dom.DivElement).text = 'updated';
  }
}
