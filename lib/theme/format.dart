import 'package:aves/locale/aves_locale.dart';
import 'package:aves/theme/text.dart';
import 'package:intl/intl.dart';

// format: `weekday, day month year` (e.g. `سه شنبه، ۲۱ مهر ۱۴۰۵`)
String formatDay(DateTime date, AvesLocale locale) {
  try {
    final lang = locale.languageBcp47;
    final weekday = DateFormat.EEEE(lang).format(date);
    final separator = lang.startsWith('fa') || lang.startsWith('ar') ? '، ' : ', ';
    return '$weekday$separator${locale.yMMMMd(date)}';
  } catch (_) {
    return DateFormat.yMMMMd().format(date);
  }
}

// time does not depend on the calendar, so it is formatted with the regular (Gregorian) formatter
String formatTime(DateTime date, AvesLocale locale, bool use24hour) {
  try {
    final lang = locale.languageBcp47;
    final formatter = use24hour ? DateFormat.Hm(lang) : DateFormat.jm(lang);
    return formatter.format(date);
  } catch (_) {
    return DateFormat(use24hour ? 'HH:mm' : 'h:mm a').format(date);
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
