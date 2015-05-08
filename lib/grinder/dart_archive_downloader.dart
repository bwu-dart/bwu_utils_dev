library bwu_utils_dev.grinder.dart_archive_downloader;

import 'dart:io' as io;
import 'dart:async' show Completer, Future, Stream;
import 'dart:convert' show JSON;
import 'package:html/parser.dart' show parse;

abstract class Channel {
  const Channel();
  static final values = new List.unmodifiable([]
    ..addAll(BleedingEdgeChannel.values)
    ..addAll(DevChannel.values)
    ..addAll(StableChannel.values));

  factory Channel.fromString(String channelName) {
    return values.firstWhere((v) => v.value == channelName);
  }
}

class BleedingEdgeChannel extends Channel {
  static const raw = const BleedingEdgeChannel('be/raw');

  static const values = const [raw];

  final String value;

  const BleedingEdgeChannel(this.value);

  @override
  String toString() => value;
}

class DevChannel extends Channel {
  static const raw = const DevChannel('dev/raw');
  static const release = const DevChannel('dev/release');
  static const signed = const DevChannel('dev/signed');

  static const values = const [raw, release, signed];

  final String value;

  const DevChannel(this.value);

  @override
  String toString() => value;
}

class StableChannel extends Channel {
  static const raw = const StableChannel('stable/raw');
  static const release = const StableChannel('stable/release');
  static const signed = const StableChannel('stable/signed');

  final String value;

  const StableChannel(this.value);

  static const values = const [raw, release, signed];

  @override
  String toString() => value;
}

class DartArchiveDownloader {
  static const host = 'https://gsdview.appspot.com';
  final Channel channel;

  DartArchiveDownloader([this.channel = StableChannel.release]);

  Stream<Iterable<String>> getVersions([int loadCount = 100]) async* {
    int valuesReturned = 0;
    _ParseResult parseResult;
    Uri nextPage = buildUrl();
    do {
      final data = await _loadUrl(nextPage);
      parseResult = _parseVersions(data);
      yield parseResult.versions;

      valuesReturned += parseResult.versions.length;
      nextPage = parseResult.nextPage;
    } while (valuesReturned <= loadCount && nextPage != null);
  }

  Future<VersionInfo> getVersionInfo(String version) async {
    final content = await _loadUrl(buildUrl(version, 'VERSION'));
    return new VersionInfo.fromJsonBytes(content);
  }

  Future<VersionInfo> getLatestVersionInfo(String version) =>
      getVersionInfo('latest');

  Future<io.HttpClientRequest> getFileRequest(
      String version, String file) async {
    final request = await new io.HttpClient().getUrl(buildUrl(version, file));
    return request;
  }

  Future<Null> downloadFile(
      String version, String file, io.File destination) async {
    assert(version != null && version.isNotEmpty);
    assert(file != null && file.isNotEmpty);
    assert(destination != null && !destination.existsSync());
    destination.createSync();
    final fileSink = destination.openWrite();
    final request = await getFileRequest(version, file);
    final response = await request.close();

    await fileSink.addStream(response);
  }

  static Future<List<int>> _loadUrl(Uri uri) async {
    final doneCompleter = new Completer<List<int>>();
//    print(uri);
    final io.HttpClientRequest request = await new io.HttpClient().getUrl(uri);
    final responseData = <int>[];
    final response = await request.close();
    response.listen((data) {
      responseData.addAll(data);
    }, onDone: () {
      doneCompleter.complete(responseData);
    });
    return doneCompleter.future;
  }

  Uri buildUrl([String version, String file]) {
    assert(channel != null);
    if (file != null) {
      assert(version != null);
      return Uri
          .parse('${host}/dart-archive/channels/${channel}/${version}/${file}');
    }
    if (version != null) {
      assert(file == null);
      return Uri.parse('${host}/dart-archive/channels/${channel}/${version}/');
    }
    return Uri.parse('${host}/dart-archive/channels/${channel}/');
  }

  static _ParseResult _parseVersions(List<int> html) {
    final Iterable<String> urls = parse(html)
        .querySelectorAll('a[href]')
        .map((a) => a.attributes['href']);
    final versions = urls
        .map((a) => a.split('/').where((e) => e.isNotEmpty).last)
        .where((a) => new RegExp(r'^\d*$').hasMatch(a));

    final nextPageLinks = urls.where((a) => a.contains('?marker='));
    final nextPageLink = nextPageLinks.length == 1
        ? Uri.parse('${host}${nextPageLinks.first}')
        : null;
    return new _ParseResult(versions, nextPageLink);
  }
}

class _ParseResult {
  Iterable<String> versions;
  Uri nextPage;
  _ParseResult(this.versions, this.nextPage);
}

class VersionInfo {
  String _revision;
  String get revision => _revision;

  String _version;
  String get version => _version;
  int get versionAsInt {
    if (version == null) {
      return null;
    }
    return int.parse(version, onError: (_) => 0);
  }

  String _date;
  String get date => _date;
  DateTime get dateAsDateTime {
    if (date == null) {
      return null;
    }
    return DateTime.parse(date);
  }

  factory VersionInfo.fromJsonBytes(List<int> bytes) =>
      new VersionInfo.fromJsonString(new String.fromCharCodes(bytes));
  factory VersionInfo.fromJsonString(String json) =>
      new VersionInfo.fromJsonMap(JSON.decode(json));
  VersionInfo.fromJsonMap(Map map) {
    _revision = map['revision'];
    _version = map['version'];
    _date = map['date'];
  }
}
