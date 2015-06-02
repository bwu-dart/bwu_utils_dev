library bwu_utils_dev.testing.web_driver;

import 'dart:io' as io;
import 'dart:async' show Completer, Future, Stream;
import 'package:webdriver/io.dart';
export 'package:webdriver/io.dart';
import 'package:which/which.dart';
import 'package:bwu_utils_dev/testing_server.dart';

final _log = new Logger('bwu_utils.testing.server.web_driver');

WebDriverFactory createDriverFactory() {
  List<WebDriverFactory> factories = [
    //new SauceLabsDriverFactory(),
    //new ChromeDriverFactory(),
    //new PhantomJSDriverFactory(),
    new DartiumDriverFactory(),
    //new FirefoxDriverFactory(),
  ];

  WebDriverFactory factory;

  for (WebDriverFactory f in factories) {
    if (f.isAvailable) {
      factory = f;
      break;
    }
  }

  if (factory == null) {
    _log.severe('No webdriver candidates found.');
    _log.severe(
        'Either set up the env. variables for using saucelabs, or install '
        'chromedriver or phantomjs.');
    io.exit(1);
  }
  return factory;
}

abstract class WebDriverFactory {
  final String name;

  WebDriverFactory(this.name);

  Map get _env => io.Platform.environment;
  bool get isAvailable;

  Future startFactory();
  Future stopFactory();

  Future<WebDriver> createWebDriver();

  String toString() => name;
}

class SauceLabsDriverFactory extends WebDriverFactory {
  SauceLabsDriverFactory() : super('saucelabs');

  bool get isAvailable => _env.containsKey('SAUCE_USERNAME') &&
      _env.containsKey('SAUCE_ACCESS_KEY');

  Future startFactory() => new Future.value();
  Future stopFactory() => new Future.value();

  Future<WebDriver> createWebDriver() => new Future.error('not implemented');
}

class PhantomJSDriverFactory extends WebDriverFactory {
  io.Process _process;

  PhantomJSDriverFactory() : super('phantomjs');

  bool get isAvailable => whichSync('phantomjs', orElse: () => null) != null;

  Future startFactory() {
    //return io.Process.start('phantomjs', ['--webdriver=9515']).then((p) {
    //  _process = p;
    //return new Future.delayed(new Duration(seconds: 1));
    //});
    return new Future.value();
  }

  Future stopFactory() {
    _process.kill();
    Future f = _process.exitCode;
    _process = null;
    return f;
  }

  Future<WebDriver> createWebDriver() {
    return createDriver(
        //uri: Uri.parse('http://127.0.0.1:9515/wd'),
        uri: Uri.parse('http://127.0.0.1:4444/wd/hub/'),
        desired: Capabilities.empty
      ..[Capabilities.browserName] = 'phantomjs'
      ..[Capabilities.version] = ''
      ..[Capabilities.platform] = BrowserPlatform.any);
  }
}

class FirefoxDriverFactory extends WebDriverFactory {
  io.Process _process;

  FirefoxDriverFactory() : super('firefox');

  bool get isAvailable => whichSync('firefox', orElse: () => null) != null;

  Future startFactory() {
    return io.Process.start('firefox', ['--webdriver=9515']).then((p) {
      _process = p;
      return new Future.delayed(new Duration(seconds: 1));
    });
  }

  Future stopFactory() {
    _process.kill();
    Future f = _process.exitCode;
    _process = null;
    return f;
  }

  Future<WebDriver> createWebDriver() {
    Map capabilities = Capabilities.firefox;
    capabilities['webdriver.firefox.profile'] = 'WebDriver';
    return createDriver(
        uri: Uri.parse('http://127.0.0.1:4444/wd/hub/'), desired: capabilities);
  }
}

class ChromeDriverFactory extends WebDriverFactory {
  io.Process _process;

  ChromeDriverFactory() : super('chromedriver') {
//    if (_env['CHROME_BINARY'] != null) {
//      chromeOptions['binary'] = _env['CHROME_BINARY'];
//    }
//    if (_env['CHROMEDRIVER_ARGS'] != null) {
//      chromeOptions['args'] = _env['CHROMEDRIVER_ARGS'].split(' ');
//    }
  }

  bool get isAvailable => whichSync('dartium', orElse: () => null) != null;

  Future startFactory() {
    _log.fine('starting chromedriver');

    return io.Process.start('chromedriver', []).then((p) {
      _process = p;
      return new Future.delayed(new Duration(seconds: 1));
    });
  }

  Future stopFactory() {
    _log.finest('stopping chromedriver');

    _process.kill();
    Future f = _process.exitCode;
    _process = null;
    return f;
  }

  final Map chromeOptions = {};

  Future<WebDriver> createWebDriver() {
    Map capabilities = Capabilities.chrome;
    if (chromeOptions.isNotEmpty) {
      capabilities['chromeOptions'] = chromeOptions;
    }

    return createDriver(uri: Uri.parse('http://127.0.0.1:9515/wd'),
        //uri: Uri.parse('http://127.0.0.1:4444/wd/hub/'),
        desired: capabilities);
  }
}

class DartiumDriverFactory extends WebDriverFactory {
  io.Process _process;

  DartiumDriverFactory() : super('chromedriver') {
    // /home/zoechi/Downloads/Dart/manual/chromedriver-lucid64-full-stable-45104.0/chromedriver') {
//    if (_env['CHROME_BINARY'] != null) {
    chromeOptions['binary'] =
        'dartium'; //'/home/zoechi/Downloads/Dart/manual/dartium-lucid64-full-stable-45104.0/chrome'; // _env['CHROME_BINARY'];
    //chromeOptions['binary'] = '/home/zoechi/Downloads/Dart/manual/chromedriver-lucid64-full-stable-45104.0/chromedriver'; _env['CHROME_BINARY'];
//    }
//    if (_env['CHROMEDRIVER_ARGS'] != null) {
//      chromeOptions['args'] = _env['CHROMEDRIVER_ARGS'].split(' ');
//    }
  }

  bool get isAvailable => whichSync('chromedriver', orElse: () => null) != null;

  Future startFactory() {
    _log.fine('starting ${name}');

    return io.Process.start(name, []).then((p) {
      _process = p;
      return new Future.delayed(new Duration(seconds: 1));
    });
  }

  Future stopFactory() {
    _log.finest('stopping ${name}');

    _process.kill();
    Future f = _process.exitCode;
    _process = null;
    return f;
  }

  final Map chromeOptions = {};

  Future<WebDriver> createWebDriver() {
    Map capabilities = Capabilities.chrome;
    if (chromeOptions.isNotEmpty) {
      capabilities['chromeOptions'] = chromeOptions;
    }

    return createDriver(uri: Uri.parse('http://127.0.0.1:9515/wd'),
        //uri: Uri.parse('http://127.0.0.1:4444/wd/hub/'),
        desired: capabilities);
  }
}

class DartiumWebDriver extends CustomWebDriver {
  DartiumWebDriver._(WebDriver driver, String userAgent)
      : super._(driver, userAgent);

  // TODO: implement onAfterCommand
  @override
  Stream<WebDriverCommandEvent> get onAfterCommand => null;
}

class CustomWebDriver implements WebDriver {
  WebDriver _driver;
  final String userAgent;
  factory CustomWebDriver(WebDriver driver, String userAgent) {
    print(userAgent);
    return new DartiumWebDriver._(driver, userAgent);
  }

  CustomWebDriver._(this._driver, this.userAgent);

  @override
  Future<WebElement> get activeElement => _driver.activeElement;

  @override
  Map<String, dynamic> get capabilities => _driver.capabilities;

  @override
  Stream<int> captureScreenshot() => _driver.captureScreenshot();

  @override
  Future close() => _driver.close();

  @override
  Cookies get cookies => _driver.cookies;

  @override
  Future<String> get currentUrl => _driver.currentUrl;

  @override
  Future deleteRequest(String command) => _driver.deleteRequest(command);

  @override
  WebDriver get driver => this;

  @override
  Future execute(String script, List args) => _driver.execute(script, args);

  @override
  Future executeAsync(String script, List args) =>
      _driver.executeAsync(script, args);

  @override
  Future<WebElement> findElement(By by, {By noShadowDom}) {
    return _driver.findElement(noShadowDom != null ? noShadowDom : by);
  }

  @override
  Stream<WebElement> findElements(By by) {
    return _driver.findElements(by);
  }

  @override
  Future get(url) => _driver.get(url);

  @override
  Future getRequest(String command) => _driver.getRequest(command);

  @override
  String get id => _driver.id;

  @override
  Keyboard get keyboard => _driver.keyboard;

  @override
  Logs get logs => _driver.logs;

  @override
  Mouse get mouse => _driver.mouse;

  @override
  Navigation get navigate => _driver.navigate;

  @override
  Future<String> get pageSource => _driver.pageSource;

  @override
  Future postRequest(String command, [params]) =>
      _driver.postRequest(command, params);

  @override
  Future quit() => quit();

  @override
  TargetLocator get switchTo => _driver.switchTo;

  @override
  Timeouts get timeouts => _driver.timeouts;

  @override
  Future<String> get title => _driver.title;

  @override
  Uri get uri => _driver.uri;

  @override
  Future<Window> get window => _driver.window;

  @override
  Stream<Window> get windows => _driver.windows;

  // TODO: implement onAfterCommand
  @override
  Stream<WebDriverCommandEvent> get onAfterCommand => null;
}
