import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../app/localization/generated/app_localizations.dart';

/// Human-friendly date output shared by the library, profile and AI history.
abstract final class AppFormatters {
  static String relativeTime(
    BuildContext context,
    AppLocalizations l10n,
    DateTime value,
  ) {
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final difference = today.difference(day).inDays;
    if (difference <= 0) return l10n.today;
    if (difference == 1) return l10n.yesterday;
    if (difference < 30) return l10n.daysAgo(difference);
    return DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .format(local);
  }

  static String shortDate(BuildContext context, DateTime value) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
          .format(value.toLocal());

  static String monthYear(BuildContext context, DateTime value) =>
      DateFormat.yMMMM(Localizations.localeOf(context).toLanguageTag())
          .format(value.toLocal());

  static String compactCount(int value) {
    if (value < 1000) return '$value';
    if (value < 10000) {
      final short = value / 1000;
      return '${short.toStringAsFixed(short >= 10 ? 0 : 1)}k';
    }
    return '${(value / 1000).round()}k';
  }

  static String bytes(int value) {
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) {
      return '${(value / 1024).toStringAsFixed(1)} KB';
    }
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String tokens(int value) =>
      value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : '$value';
}
