library bwu_utils_dev.grinder.default_tasks;

import 'dart:io' as io;
import 'dart:async' show Future, Stream;
import 'package:grinder/grinder.dart';
export 'package:grinder/grinder.dart' show DefaultTask, Depends, Task;
import 'package:bwu_utils_dev/grinder.dart';
import 'package:bwu_utils_dev/testing_server.dart';

// TODO(zoechi) check if version was incremented
// TODO(zoechi) check if CHANGELOG.md contains version

//@Task('Delete build directory')
//void clean() => defaultClean(context);

const sourceDirs = const ['bin', 'example', 'lib', 'test', 'tool', 'web'];
final existingSourceDirs =
    sourceDirs.where((d) => new io.Directory(d).existsSync()).toList();

main(List<String> args) => grind(args);

@Task('Run analyzer')
analyze() => analyzeTask();

@Task('Runn all tests')
test() => testTask(['vm', 'content-shell']);
// TODO(zoechi) fix to support other browsers
//'dartium', 'chrome', 'phantomjs', 'firefox'

@Task('Run all VM tests')
testVm() => testTask(['vm']);

@Task('Run all browser tests')
testWeb() => testTask(['content-shell']);

@DefaultTask('Check everything')
@Depends(analyze, checkFormat, lint, test)
check() => checkTask();

@Task('Check source code format')
checkFormat() => checkFormatTask(existingSourceDirs);

/// format-all - fix all formatting issues
@Task('Fix all source format issues')
format() => formatTask();

@Task('Run lint checks')
lint() => lintTask();

@Depends(check, coverage)
@Task('Travis')
travis() {}

@Task('Gather and send coverage data.')
coverage() => coverageTask();

Function analyzeTask = analyzeTaskImpl;

analyzeTaskImpl() => new PubApp.global('tuneup').run(['check']);

Function checkTask = checkTaskImpl;

checkTaskImpl() => run('pub', arguments: ['publish', '-n']);

Function coverageTask = coverageTaskImpl;

coverageTaskImpl() {
  final String coverageToken = io.Platform.environment['REPO_TOKEN'];

  if (coverageToken != null) {
    PubApp coverallsApp = new PubApp.global('dart_coveralls');
    coverallsApp.run(
        ['report', '--retry', '2', '--exclude-test-files', 'test/all.dart']);
  } else {
    log('Skipping coverage task: no environment variable `REPO_TOKEN` found.');
  }
}

Function formatTask = formatTaskImpl;

formatTaskImpl() => new PubApp.global('dart_style').run(
    ['-w']..addAll(existingSourceDirs), script: 'format');

Function lintTask = lintTaskImpl;

lintTaskImpl() => new PubApp.global('linter')
    .run(['--stats', '-ctool/lintcfg.yaml']..addAll(existingSourceDirs));

Function testTask = testTaskImpl;

testTaskImpl(List<String> platforms,
    {bool runPubServe: false, bool runSelenium: false}) async {
  final seleniumJar = io.Platform.environment['SELENIUM_JAR'];

  var pubServe;
  var selenium;
  final servers = <Future<RunProcess>>[];

  try {
    if (runPubServe) {
      pubServe = new PubServe();
      print('start pub serve');
      servers.add(pubServe.start(directories: const ['test']).then((_) {
        pubServe.stdout.listen((e) => io.stdout.add(e));
        pubServe.stderr.listen((e) => io.stderr.add(e));
      }));
    }
    if (runSelenium) {
      selenium = new SeleniumStandaloneServer();
      print('start Selenium standalone server');
      servers.add(selenium.start(seleniumJar, args: []).then((_) {
        selenium.stdout.listen((e) => io.stdout.add(e));
        selenium.stderr.listen((e) => io.stderr.add(e));
      }));
    }

    await Future.wait(servers);

    if (runPubServe) {
      new PubApp.local('test').run(
          ['--pub-serve=${pubServe.directoryPorts['test']}']
        ..addAll(platforms.map((p) => '-p${p}')));
    } else {
      new PubApp.local('test').run([]..addAll(platforms.map((p) => '-p${p}')));
    }
  } finally {
    if (pubServe != null) {
      pubServe.stop();
    }
    if (selenium != null) {
      selenium.stop();
    }
  }
}

//  final chromeBin = '-Dwebdriver.chrome.bin=/usr/bin/google-chrome';
//  final chromeDriverBin = '-Dwebdriver.chrome.driver=/usr/local/apps/webdriver/chromedriver/2.15/chromedriver_linux64/chromedriver';
