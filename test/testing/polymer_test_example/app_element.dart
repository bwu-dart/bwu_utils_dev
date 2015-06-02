@HtmlImport('app_element.html')
library bwu_utils_dev.test.testing.polymer_test_example.app_element;

import 'package:polymer/polymer.dart';

@CustomTag('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();
}
