import 'package:aves/locale/aves_locale.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/text.dart';
import 'package:intl/intl.dart';

String _two(int v) => v.toString().padLeft(2, '0');

const _jalaliMonthsFa = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
const _jalaliMonthsEn = ['Farvardin', 'Ordibehesht', 'Khordad', 'Tir', 'Mordad', 'Shahrivar', 'Mehr', 'Aban', 'Azar', 'Dey', 'Bahman', 'Esfand'];
// `DateTime.weekday`: 1 = Monday ... 7 = Sunday
const _weekdaysFa = ['دوشنبه', 'سه\u200cشنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه'];

bool _isFa(AvesLocale locale) => locale.languageBcp47.startsWith('fa');

// detect the Jalali (Solar Hijri) calendar without depending on the exact calendar type
bool _isJalali(AvesLocale locale) {
  try {
    final name = locale.calendar.toString().toLowerCase();
    return name.contains('persian') || name.contains('jalali') || name.contains('shamsi') || name.contains('solar');
  } catch (_) {
    return false;
  }
}

// Gregorian to Jalali conversion, returns (year, month, day)
(int, int, int) _toJalali(DateTime date) {
  const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy = date.year;
  final gy2 = date.month > 2 ? gy + 1 : gy;
  var days = 355666 + (365 * gy) + ((gy2 + 3) ~/ 4) - ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400) + date.day + gdm[date.month - 1];
  var jy = -1595 + (33 * (days ~/ 12053));
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  final jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
  final jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
  return (jy, jm, jd);
}

String _digits(int v, AvesLocale locale) {
  final s = v.toString();
  final useNative = _isFa(locale) && !settings.forceWesternArabicNumerals;
  if (!useNative) return s;
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return s.split('').map((c) => fa[int.parse(c)]).join();
}

String _jalaliMonthName(int month, AvesLocale locale) => (_isFa(locale) ? _jalaliMonthsFa : _jalaliMonthsEn)[month - 1];

// format: `month` (e.g. `مهر`)
String formatMonth(DateTime date, AvesLocale locale) {
  if (_isJalali(locale)) {
    final (_, m, _) = _toJalali(date);
    return _jalaliMonthName(m, locale);
  }
  try {
    return locale.MMMM(date);
  } catch (_) {
    return DateFormat.MMMM().format(date);
  }
}

// format: `month year` (e.g. `مهر ۱۴۰۵`)
String formatMonthYear(DateTime date, AvesLocale locale) {
  if (_isJalali(locale)) {
    final (y, m, _) = _toJalali(date);
    return '${_jalaliMonthName(m, locale)} ${_digits(y, locale)}';
  }
  try {
    return locale.yMMMM(date);
  } catch (_) {
    return '${date.year}-${_two(date.month)}';
  }
}

// format: `weekday, day month year` (e.g. `سه شنبه، ۲۱ مهر ۱۴۰۵`)
// each part is computed independently and none of them can throw,
// so a formatting failure can never break the page that displays a date
String formatDay(DateTime date, AvesLocale locale) {
  final jalali = _isJalali(locale);

  String weekday = '';
  try {
    weekday = DateFormat.EEEE(locale.languageBcp47).format(date);
  } catch (_) {
    if (jalali && _isFa(locale)) weekday = _weekdaysFa[date.weekday - 1];
  }

  String day;
  if (jalali) {
    // computed here so the displayed year can never be the Gregorian one
    final (y, m, d) = _toJalali(date);
    day = '${_digits(d, locale)} ${_jalaliMonthName(m, locale)} ${_digits(y, locale)}';
  } else {
    try {
      day = locale.yMMMMd(date);
    } catch (_) {
      day = '${date.year}-${_two(date.month)}-${_two(date.day)}';
    }
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
