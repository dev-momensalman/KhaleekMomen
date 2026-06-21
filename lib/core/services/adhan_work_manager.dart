// lib/core/services/adhan_work_manager.dart
//
// WorkManager background task — يعيد جدولة الأذان كل 12 ساعة
// حتى لو التطبيق مهجور تماماً.
//
// ✅ لا يحتاج أي صلاحية إضافية من المستخدم
// ✅ يعمل حتى في Doze Mode عبر Android JobScheduler
// ✅ يُعاد تسجيله تلقائياً بعد إعادة تشغيل الجهاز

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/core/services/notification_service.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart'; // ✅ FIX #1: المسار الصحيح

// ──────────────────────────────────────────────────────────────────────────────
// Constants
// ──────────────────────────────────────────────────────────────────────────────

const _kTaskName = 'adhanDailyReschedule';
const _kTaskUniqueName = 'adhan-daily-reschedule';

// ──────────────────────────────────────────────────────────────────────────────
// Top-level callback — يعمل في Dart isolate منفصل تماماً عن الـ UI
// ──────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void adhanWorkManagerCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('[AdhanWorker] Task triggered: $taskName');

    try {
      // 1. تهيئة Flutter bindings (ضرورية في الـ isolate المنفصل)
      WidgetsFlutterBinding.ensureInitialized();

      // 2. تهيئة Hive storage
      await StorageService.init();
      final storage = StorageService();

      // 3. تهيئة NotificationService
      await NotificationService.init();

      // 4. قراءة أوقات الصلاة المحفوظة في الـ cache
      final dynamic raw = storage.get('cached_prayer_times');
      if (raw == null) {
        debugPrint('[AdhanWorker] No cached prayer times found — skipping.');
        return true; // لا توجد بيانات، لا داعي لإعادة المحاولة
      }

      final PrayerTimes pt = PrayerTimes.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );

      // ✅ FIX #2: لا حاجة لـ setTimezone منفصلة
      // schedulePrayerNotifications تقرأ pt.timezone وتضبط الـ timezone تلقائياً
      // (Africa/Cairo من الـ API مباشرةً)

      // 5. قراءة أوقات صلاة الغد إن وُجدت (لتجنب صفر إشعارات بعد العشاء)
      PrayerTimes? tomorrowPt;
      final dynamic rawTomorrow = storage.get('cached_prayer_times_tomorrow');
      if (rawTomorrow != null) {
        try {
          tomorrowPt = PrayerTimes.fromJson(
            Map<String, dynamic>.from(rawTomorrow as Map),
          );
        } catch (_) {}
      }

      // 6. إعادة جدولة الإشعارات
      await NotificationService.schedulePrayerNotifications(
        pt,
        storage: storage,
        tomorrowPrayerTimes: tomorrowPt,
      );

      debugPrint(
        '[AdhanWorker] ✅ Prayer notifications rescheduled successfully.',
      );
      return true; // نجاح — لا يُعاد تشغيل المهمة
    } catch (e, stack) {
      debugPrint('[AdhanWorker] ❌ Error: $e\n$stack');
      return false; // فشل — WorkManager سيعيد المحاولة تلقائياً
    }
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// registerAdhanWorker — يُستدعى مرة واحدة عند بدء التطبيق
// ──────────────────────────────────────────────────────────────────────────────

Future<void> registerAdhanWorker() async {
  // تهيئة WorkManager مع الـ callback
  // ✅ FIX #5: حذف isInDebugMode (deprecated في workmanager 0.5.x)
  await Workmanager().initialize(adhanWorkManagerCallback);

  // تسجيل المهمة الدورية كل 12 ساعة
  await Workmanager().registerPeriodicTask(
    _kTaskUniqueName,
    _kTaskName,
    frequency: const Duration(hours: 12),
    initialDelay: const Duration(hours: 1),
    existingWorkPolicy:
        ExistingPeriodicWorkPolicy.keep, // ✅ FIX #3: النوع الصحيح
    constraints: Constraints(
      networkType: NetworkType.notRequired, // ✅ FIX #4: camelCase الصحيح
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );

  debugPrint('[AdhanWorker] ✅ Periodic task registered — runs every 12h.');
}
