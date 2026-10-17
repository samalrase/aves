import 'package:aves/locale/calendar/calendar_utils.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/section_keys.dart';
import 'package:aves/theme/format.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/grid/header.dart';
import 'package:material_ui/material_ui.dart';

class const DaySectionHeader<T>({
  super.key,
  required final SectionKey sectionKey,
  required final DateTime? date,
  required final bool selectable,
}) extends StatelessWidget {
  static String _formatDate(BuildContext context, DateTime? date) {
    final l10n = context.l10n;
    if (date == null) return l10n.sectionUnknown;

    final locale = settings.avesLocale;

    try {
      final calOps = locale.calendar.ops;
      if (calOps.isToday(date)) return l10n.dateToday;
      if (calOps.isYesterday(date)) return l10n.dateYesterday;
    } catch (_) {
      // fall through to the plain date, a header must never break the page
    }

    // format: `weekday, day month year` (e.g. `سه شنبه، ۲۱ مهر ۱۴۰۵`)
    return formatDay(date, locale);
  }

  @override
  Widget build(BuildContext context) {
    return SectionHeader<T>(
      sectionKey: sectionKey,
      title: _formatDate(context, date),
      selectable: selectable,
    );
  }
}

class const MonthSectionHeader<T>({
  super.key,
  required final SectionKey sectionKey,
  required final DateTime? date,
  required final bool selectable,
}) extends StatelessWidget {
  static String _formatDate(BuildContext context, DateTime? date) {
    final l10n = context.l10n;
    if (date == null) return l10n.sectionUnknown;

    final locale = settings.avesLocale;

    bool isThisYear = false;
    try {
      final calOps = locale.calendar.ops;
      if (calOps.isThisMonth(date)) return l10n.dateThisMonth;
      isThisYear = calOps.isThisYear(date);
    } catch (_) {
      // fall through to the plain month
    }

    final localized = isThisYear ? formatMonth(date, locale) : formatMonthYear(date, locale);
    if (localized.isEmpty) return localized;
    return '${localized.substring(0, 1).toUpperCase()}${localized.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return SectionHeader<T>(
      sectionKey: sectionKey,
      title: _formatDate(context, date),
      selectable: selectable,
    );
  }
}
