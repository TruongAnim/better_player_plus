import 'dart:convert';
import 'dart:io';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:better_player_plus/src/core/better_player_utils.dart';
import 'better_player_subtitle.dart';

class BetterPlayerSubtitlesFactory {
  static Future<List<BetterPlayerSubtitle>> parseSubtitles(
      BetterPlayerSubtitlesSource source) async {
    switch (source.type) {
      case BetterPlayerSubtitlesSourceType.file:
        return _parseSubtitlesFromFile(source);
      case BetterPlayerSubtitlesSourceType.network:
        return _parseSubtitlesFromNetwork(source);
      case BetterPlayerSubtitlesSourceType.memory:
        return _parseSubtitlesFromMemory(source);
      default:
        return [];
    }
  }

  static Future<List<BetterPlayerSubtitle>> _parseSubtitlesFromFile(
      BetterPlayerSubtitlesSource source) async {
    try {
      final List<BetterPlayerSubtitle> subtitles = [];
      for (final String? url in source.urls!) {
        final file = File(url!);
        if (file.existsSync()) {
          final String fileContent = await file.readAsString();
          final subtitlesCache = _parseString(fileContent);
          subtitles.addAll(subtitlesCache);
        } else {
          BetterPlayerUtils.log("$url doesn't exist!");
        }
      }
      return subtitles;
    } on Exception catch (exception) {
      BetterPlayerUtils.log("Failed to read subtitles from file: $exception");
    }
    return [];
  }

  static Future<List<BetterPlayerSubtitle>> _parseSubtitlesFromNetwork(
      BetterPlayerSubtitlesSource source) async {
    try {
      final client = HttpClient();
      final List<BetterPlayerSubtitle> subtitles = [];
      for (final String? url in source.urls!) {
        final request = await client.getUrl(Uri.parse(url!));
        source.headers?.keys.forEach((key) {
          final value = source.headers![key];
          if (value != null) {
            request.headers.add(key, value);
          }
        });
        final response = await request.close();
        final data = await response.transform(const Utf8Decoder()).join();
        final cacheList = _parseString(data);
        subtitles.addAll(cacheList);
      }
      client.close();

      BetterPlayerUtils.log("Parsed total subtitles: ${subtitles.length}");
      return subtitles;
    } on Exception catch (exception) {
      BetterPlayerUtils.log(
          "Failed to read subtitles from network: $exception");
    }
    return [];
  }

  static List<BetterPlayerSubtitle> _parseSubtitlesFromMemory(
      BetterPlayerSubtitlesSource source) {
    try {
      return _parseString(source.content!);
    } on Exception catch (exception) {
      BetterPlayerUtils.log("Failed to read subtitles from memory: $exception");
    }
    return [];
  }

  static List<BetterPlayerSubtitle> _parseString(String value) {
    final List<BetterPlayerSubtitle> subtitlesObj = [];

    for (final component in _readSubFile(value)) {
      if (component.length < 2) {
        continue;
      }

      final subtitle = BetterPlayerSubtitle(component.join('\n'));
      if (subtitle.start != null &&
          subtitle.end != null &&
          subtitle.text != null) {
        subtitlesObj.add(subtitle);
      }
    }

    return subtitlesObj;
  }

  static List<List<String>> _readSubFile(String file) {
    final List<String> lines = LineSplitter.split(file).toList();

    final List<List<String>> captionStrings = <List<String>>[];
    List<String> currentCaption = <String>[];
    int lineIndex = 0;
    for (final String line in lines) {
      final bool isLineBlank = line.trim().isEmpty;
      if (!isLineBlank) {
        currentCaption.add(line);
      }

      if (isLineBlank || lineIndex == lines.length - 1) {
        captionStrings.add(currentCaption);
        currentCaption = <String>[];
      }

      lineIndex += 1;
    }

    return captionStrings;
  }
}