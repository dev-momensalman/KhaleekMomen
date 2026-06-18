import 'package:intl/intl.dart';

class PrayerTimes {
  final String date; // YYYY-MM-DD format
  final String fajr; // HH:mm format
  final String sunrise; // HH:mm format
  final String dhuhr; // HH:mm format
  final String asr; // HH:mm format
  final String maghrib; // HH:mm format
  final String isha; // HH:mm format
  final double? latitude;
  final double? longitude;
  final String timezone;

  PrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.latitude,
    this.longitude,
    required this.timezone,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    return PrayerTimes(
      date: json['date']?.toString() ?? '',
      fajr: json['fajr']?.toString() ?? '',
      sunrise: json['sunrise']?.toString() ?? '',
      dhuhr: json['dhuhr']?.toString() ?? '',
      asr: json['asr']?.toString() ?? '',
      maghrib: json['maghrib']?.toString() ?? '',
      isha: json['isha']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timezone: json['timezone']?.toString() ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
    };
  }

  // ── BUG FIX: withDate helper ─────────────────────────────────────────────
  // Returns a copy of this PrayerTimes but with a different date.
  // Used by NotificationService to schedule next-day prayers when today's
  // have all passed — prayer times change only slightly day-to-day (~1-3 min),
  // so this gives a close enough approximation when exact API data isn't cached.
  PrayerTimes withDate(String newDate) {
    return PrayerTimes(
      date: newDate,
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
    );
  }

  // ── isToday / isFuture helpers ───────────────────────────────────────────
  bool get isForToday {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return date == today;
  }

  bool get isForFutureDate {
    try {
      final dateParts = date.split('-');
      if (dateParts.length != 3) return false;
      final d = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      return d.isAfter(todayMidnight) || d.isAtSameMomentAs(todayMidnight);
    } catch (_) {
      return false;
    }
  }

  // Helper to parse a time string like "05:12" into a full DateTime on the target date
  DateTime? getDateTimeForPrayer(String timeStr) {
    try {
      final dateParts = date.split('-');
      final timeParts = timeStr.split(':');
      if (dateParts.length != 3 || timeParts.length != 2) return null;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Strip any extra text (like timezones from API: e.g. "05:12 (EET)")
      final hour = int.parse(timeParts[0].trim().split(' ')[0]);
      final minute = int.parse(timeParts[1].trim().split(' ')[0]);

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  // Helper to check if the times are in chronological order
  bool isValidChronologically() {
    final tFajr = getDateTimeForPrayer(fajr);
    final tSunrise = getDateTimeForPrayer(sunrise);
    final tDhuhr = getDateTimeForPrayer(dhuhr);
    final tAsr = getDateTimeForPrayer(asr);
    final tMaghrib = getDateTimeForPrayer(maghrib);
    final tIsha = getDateTimeForPrayer(isha);

    if (tFajr == null || tSunrise == null || tDhuhr == null ||
        tAsr == null || tMaghrib == null || tIsha == null) {
      return false;
    }

    return tFajr.isBefore(tSunrise) &&
        tSunrise.isBefore(tDhuhr) &&
        tDhuhr.isBefore(tAsr) &&
        tAsr.isBefore(tMaghrib) &&
        tMaghrib.isBefore(tIsha);
  }

  @override
  String toString() {
    return 'PrayerTimes(date: $date, fajr: $fajr, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha, tz: $timezone)';
  }
}
