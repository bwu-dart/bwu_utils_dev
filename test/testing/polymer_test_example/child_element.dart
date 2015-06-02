@HtmlImport('child_element.html')
library bwu_utils_dev.test.testing.polymer_test_example.child_element;

import 'package:polymer/polymer.dart';

@CustomTag('child-element')
class ChildElement extends PolymerElement {
  ChildElement.created() : super.created();
}
