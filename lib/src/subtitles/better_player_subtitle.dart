import 'package:better_player_plus/src/core/better_player_utils.dart';

class BetterPlayerSubtitle {
  static const String timerSeparator = ' --> ';
  final int? index;
  final Duration? start;
  final Duration? end;
  final String? text;

  BetterPlayerSubtitle._({
    this.index,
    this.start,
    this.end,
    this.text,
  });

  factory BetterPlayerSubtitle(String value) {
    try {
      final scanner = value.split('\n');
      if (scanner.length == 2) {
        return _handle2LinesSubtitles(scanner);
      }
      if (scanner.length > 2) {
        return _handle3LinesAndMoreSubtitles(scanner);
      }
      return BetterPlayerSubtitle._();
    } on Exception catch (_) {
      BetterPlayerUtils.log("Failed to parse subtitle line: $value");
      return BetterPlayerSubtitle._();
    }
  }

  static BetterPlayerSubtitle _handle2LinesSubtitles(List<String> scanner) {
    try {
      final timeSplit = scanner[0].split(timerSeparator);
      if (timeSplit.length < 2) {
        return BetterPlayerSubtitle._();
      }

      final start = _stringToDuration(timeSplit[0]);
      final end = _stringToDuration(timeSplit[1]);
      final text = scanner.sublist(1, scanner.length).join('\n');

      return BetterPlayerSubtitle._(
        index: -1,
        start: start,
        end: end,
        text: text,
      );
    } on Exception catch (_) {
      BetterPlayerUtils.log("Failed to parse subtitle line: $scanner");
      return BetterPlayerSubtitle._();
    }
  }

  static BetterPlayerSubtitle _handle3LinesAndMoreSubtitles(
      List<String> scanner) {
    try {
      int? index = -1;
      final indexOfTimer =
          scanner.indexWhere((text) => text.contains(timerSeparator));
      if (indexOfTimer < 0) return BetterPlayerSubtitle._();
      if (indexOfTimer > 0) {
        index = int.tryParse(scanner[indexOfTimer - 1]);
      }
      final firstLineOfText = indexOfTimer + 1;
      final timeSplit = scanner[indexOfTimer].split(timerSeparator);

      final start = _stringToDuration(timeSplit[0]);
      final end = _stringToDuration(timeSplit[1]);
      final text = scanner.sublist(firstLineOfText, scanner.length).join('\n');
      return BetterPlayerSubtitle._(
          index: index, start: start, end: end, text: text);
    } on Exception catch (_) {
      BetterPlayerUtils.log("Failed to parse subtitle line: $scanner");
      return BetterPlayerSubtitle._();
    }
  }

  static Duration _stringToDuration(String value) {
    try {
      final valueSplit = value.split(" ");
      String componentValue;

      if (valueSplit.length > 1) {
        componentValue = valueSplit[0];
      } else {
        componentValue = value;
      }

      final component = componentValue.split(':');
      // Interpret a missing hour component to mean 00 hours
      if (component.length == 2) {
        component.insert(0, "00");
      } else if (component.length != 3) {
        return const Duration();
      }

      final secsAndMillisSplitChar = component[2].contains(',') ? ',' : '.';
      final secsAndMillsSplit = component[2].split(secsAndMillisSplitChar);
      if (secsAndMillsSplit.length != 2) {
        return const Duration();
      }

      final result = Duration(
        hours: int.tryParse(component[0])!,
        minutes: int.tryParse(component[1])!,
        seconds: int.tryParse(secsAndMillsSplit[0])!,
        milliseconds: int.tryParse(secsAndMillsSplit[1])!,
      );
      return result;
    } on Exception catch (_) {
      BetterPlayerUtils.log("Failed to process value: $value");
      return const Duration();
    }
  }

  @override
  String toString() {
    return 'BetterPlayerSubtitle{index: $index, start: $start, end: $end, text: $text}';
  }
}
