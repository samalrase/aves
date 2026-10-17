import 'package:aves/locale/aves_locale.dart';
import 'package:aves/theme/text.dart';
import 'package:intl/intl.dart';

String _two(int v) => v.toString().padLeft(2, '0');

// format: `weekday, day month year` (e.g. `سه شنبه، ۲۱ مهر ۱۴۰۵`)
// each part is computed independently and none of them can throw,
// so a formatting failure can never break the page that displays a date
String formatDay(DateTime date, AvesLocale locale) {
  String weekday = '';
  try {
    weekday = DateFormat.EEEE(locale.languageBcp47).format(date);
  } catch (_) {
    // weekday is optional
  }

  String day;
  try {
    day = locale.yMMMMd(date);
  } catch (_) {
    day = '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  if (weekday.isEmpty) return day;
  final lang = locale.languageBcp47;
  final separator = lang.startsWith('fa') || lang.startsWith('ar') ? '، ' : ', ';
  return '$weekday$separator$day';
}

// time does not depend on the calendar
String formatTime(DateTime date, AvesLocale locale, bool use24hour) {
  try {
    return use24hour ? locale.Hm(date) : locale.jm(date);
  } catch (_) {
    // fall through to the plain formatter
  }
  try {
    final lang = locale.languageBcp47;
    return (use24hour ? DateFormat.Hm(lang) : DateFormat.jm(lang)).format(date);
  } catch (_) {
    return '${_two(date.hour)}:${_two(date.minute)}';
  }
}

String formatDateTime(DateTime date, AvesLocale locale, bool use24hour) => [
  formatDay(date, locale),
  formatTime(date, locale, use24hour),
].join(AText.separator);

String formatFriendlyDuration(Duration d) {
  final isNegative = d.isNegative;
  final sign = isNegative ? '-' : '';
  d = d.abs();
  final hours = d.inHours;
  d -= Duration(hours: hours);
  final minutes = d.inMinutes;
  d -= Duration(minutes: minutes);
  final seconds = d.inSeconds;

  if (hours == 0) return '$sign$minutes:${seconds.toString().padLeft(2, '0')}';

  return '$sign$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String formatPreciseDuration(Duration d) {
  final millis = ((d.inMicroseconds / 1000.0).round() % 1000).toString().padLeft(3, '0');
  final seconds = (d.inSeconds.remainder(Duration.secondsPerMinute)).toString().padLeft(2, '0');
  final minutes = (d.inMinutes.remainder(Duration.minutesPerHour)).toString().padLeft(2, '0');
  final hours = (d.inHours).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds.$millis';
}
