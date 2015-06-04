@Timeout(const Duration(minutes: 5))
@TestOn('vm')
library bwu_utils_dev.test.testing.webdriver.polymer;

import 'dart:io' as io;
import 'package:bwu_utils_dev/testing_server.dart';
//import 'package:which/which.dart';

final _log = new Logger('bwu_utils.test.testing.webdriver.polymer');

main([List<String> args]) {
  initLogging(args);
//  WebDriverFactory wdFactory = new ChromeDriverFactory()
  //..chromeOptions['binary'] = '/home/zoechi/Downloads/Dart/manual/dartium-lucid64-full-stable-45104.0/chrome';
  //whichSync('dartium', orElse: () => null);
  WebDriverFactory wdFactory =
      createDriverFactory(); // TODO(zoechi) make it work with Dartium

  group('selenium', () {
    WebDriver driver;
    PubServe pubServe;
//    int finishedTests;

    setUp(() async {
//      if (pubServe == null) {
      await wdFactory.startFactory();
      pubServe = new PubServe();
      await pubServe.start(directories: const ['test']);
      //    }
      driver = await wdFactory.createWebDriver();
      print('driver = $driver, ${driver.capabilities}, ${driver.id}');
    });

    tearDown(() async {
      await driver.quit();
      pubServe.stop();
      final ec = await wdFactory.stopFactory();
      print('exitCode: ${ec}');
    });

    test('selenium polymer', () async {
      // set up
      final examplePubServePort = pubServe.directoryPorts['test'];
      final url =
          'http://localhost:${examplePubServePort}/testing/webdriver/polymer/index.html';
      print(url);
      // exercise
      _log.finest('get: ${url}');
      await driver.get(url);
//      await driver.get(url);
      driver.timeouts.setImplicitTimeout(const Duration(seconds: 50));
      final title = await driver.title;
      //driver.timeouts.setImplicitTimeout(const Duration(seconds: 15));

      // http://caniuse.com/#feat=shadowdom
      //bool canShadowDom =
      [
        'chrome',
        'dartium',
        'opera'
      ].contains(driver.capabilities['browserName']);
      print(await driver.execute('return window.navigator.userAgent;', []));

      var ret = await driver.executeAsync('''

  var _done = function(e) {
    window.removeEventListener('WebComponentsReady', _done);
    window.removeEventListener('polymer-ready', _done);
    arguments[0]('xxx');
  };

  window.addEventListener('WebComponentsReady', _done);
  window.addEventListener('polymer-ready', _done);
      ''', []);
      print(ret);

      WebElement someDiv;
      print('page source: ${await driver.pageSource}');
      final screenShot = new io.File('screenshot.png');
      final sink = screenShot.openWrite();
      sink.add(await driver.captureScreenshot().toList());
      //if(canShadowDom) {
      print('use shadow DOM');
//        someDiv =
//          await driver.findElement(const By.cssSelector('* /deep/ #some-div'));
//      } else {
      print('no shadow DOM');
      someDiv = await driver.findElement(const By.cssSelector('#some-div'));
//      }
      print(someDiv);
      expect(title, equals('browser/webdriver test'));
      expect(someDiv, isNotNull);
      expect(await someDiv.attributes['id'], equals('some-div'));

      // tear down
    }, timeout: const Timeout(const Duration(minutes: 5)));
  }, skip: 'work in progress');
}
