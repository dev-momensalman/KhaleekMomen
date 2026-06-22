import 'package:intl/intl.dart';

class PrayerTimes {
  final String date; // YYYY-MM-DD
  final String fajr; // HH:mm
  final String sunrise; // HH:mm
  final String dhuhr; // HH:mm
  final String asr; // HH:mm
  final String maghrib; // HH:mm
  final String isha; // HH:mm
  final double? latitude;
  final double? longitude;
  final String timezone;
  // ✅ طريقة الحساب المستخدمة — نحفظها مع الكاش لنتحقق منها عند القراءة
  final int? calculationMethod;

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
    this.calculationMethod, // ✅ اختياري — backward-compatible مع الكاش القديم
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
      calculationMethod:
          json['calculationMethod'] as int?, // ✅ null if old cache
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
      if (calculationMethod != null)
        'calculationMethod': calculationMethod, // ✅
    };
  }

  /// Returns a copy with a different date (times stay the same — approximation).
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
      calculationMethod: calculationMethod, // ✅ نحافظ عليها
    );
  }

  bool get isForToday {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return date == today;
  }

  bool get isForFutureDate {
    try {
      final dateParts = date.split('-');
      if (dateParts.length != 3) return false;
      final d = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      return d.isAfter(todayMidnight) || d.isAtSameMomentAs(todayMidnight);
    } catch (_) {
      return false;
    }
  }

  DateTime? getDateTimeForPrayer(String timeStr) {
    try {
      final dateParts = date.split('-');
      final timeParts = timeStr.split(':');
      if (dateParts.length != 3 || timeParts.length != 2) return null;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Strip timezone suffix e.g. "05:12 (EET)"
      final hour = int.parse(timeParts[0].trim().split(' ')[0]);
      final minute = int.parse(timeParts[1].trim().split(' ')[0]);

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  bool isValidChronologically() {
    final tFajr = getDateTimeForPrayer(fajr);
    final tSunrise = getDateTimeForPrayer(sunrise);
    final tDhuhr = getDateTimeForPrayer(dhuhr);
    final tAsr = getDateTimeForPrayer(asr);
    final tMaghrib = getDateTimeForPrayer(maghrib);
    final tIsha = getDateTimeForPrayer(isha);

    if (tFajr == null ||
        tSunrise == null ||
        tDhuhr == null ||
        tAsr == null ||
        tMaghrib == null ||
        tIsha == null) {
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
    return 'PrayerTimes(date: $date, fajr: $fajr, dhuhr: $dhuhr, '
        'asr: $asr, maghrib: $maghrib, isha: $isha, '
        'tz: $timezone, method: $calculationMethod)';
  }
}
