import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:islamic_audio_hub/controllers/settings_controller.dart';
import 'package:islamic_audio_hub/core/services/notification_service.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';
import 'package:islamic_audio_hub/data/models/prayer_calculation_method.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ctrl = Provider.of<SettingsController>(context);
    final isArabic = ctrl.locale.languageCode == 'ar';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 1. أوقات الصلاة ──────────────────────────────────────────
        _sectionHeader(
          context,
          _t(isArabic, ar: 'أوقات الصلاة', en: 'Prayer Times'),
        ),
        Card(
          child: Column(
            children: [
              // تفعيل الأذان
              SwitchListTile(
                value: ctrl.adhanAutoPlay,
                title: Text(l10n.adhanAutoplay),
                subtitle: Text(l10n.adhanAutoplaySubtitle),
                secondary: Icon(
                  Icons.notifications_active_rounded,
                  color: ctrl.adhanAutoPlay ? theme.colorScheme.primary : null,
                ),
                onChanged: ctrl.updateAdhanAutoPlay,
              ),
              const Divider(height: 1),
              // فحص موثوقية الأذان
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  _t(
                    isArabic,
                    ar: 'فحص موثوقية الأذان',
                    en: 'Adhan reliability check',
                  ),
                ),
                subtitle: Text(
                  _t(
                    isArabic,
                    ar: 'تأكد من الإشعارات والتنبيهات الدقيقة والبطارية.',
                    en: 'Check notifications, exact alarms and battery settings.',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showAdhanDiagnosticsSheet(context, ctrl),
              ),
              const Divider(height: 1),
              // طريقة حساب الأوقات
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calculate_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  _t(
                    isArabic,
                    ar: 'طريقة حساب الأوقات',
                    en: 'Calculation method',
                  ),
                ),
                subtitle: Text(
                  ctrl.calculationMethod.displayName(isArabic),
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showCalculationMethodSheet(context, ctrl),
              ),
              const Divider(height: 1),
              // تأخير الأذان
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.timer_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  _t(isArabic, ar: 'تأخير الأذان', en: 'Adhan offset'),
                ),
                subtitle: Text(
                  ctrl.adhanOffsetMinutes == 0
                      ? _t(isArabic, ar: 'بدون تأخير', en: 'No offset')
                      : _t(
                          isArabic,
                          ar: '+${ctrl.adhanOffsetMinutes} دقيقة بعد الوقت المحسوب',
                          en: '+${ctrl.adhanOffsetMinutes} min after calculated time',
                        ),
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showAdhanOffsetSheet(context, ctrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── 2. صوت الأذان ──────────────────────────────────────────
        _sectionHeader(context, l10n.adhanSound),
        Card(
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(l10n.adhanSound),
            subtitle: Text(
              ctrl.selectedAdhan.displayName,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showAdhanSheet(context, ctrl),
          ),
        ),
        const SizedBox(height: 24),

        // ── 3. التخصيص ────────────────────────────────────────────
        _sectionHeader(context, l10n.personalization),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_rounded),
                title: Text(l10n.themeMode),
                subtitle: Text(_themeName(l10n, ctrl.themeMode)),
                trailing: DropdownButton<ThemeMode>(
                  value: ctrl.themeMode,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l10n.themeLight),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l10n.themeDark),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(l10n.themeSystem),
                    ),
                  ],
                  onChanged: (m) {
                    if (m != null) ctrl.updateThemeMode(m);
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: Text(l10n.appLanguage),
                subtitle: Text(
                  ctrl.locale.languageCode == 'ar' ? l10n.arabic : l10n.english,
                ),
                trailing: DropdownButton<String>(
                  value: ctrl.locale.languageCode,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                    DropdownMenuItem(value: 'ar', child: Text(l10n.arabic)),
                  ],
                  onChanged: (lang) {
                    if (lang != null) ctrl.updateLanguage(lang);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── 4. عن التطبيق ──────────────────────────────────────────
        _sectionHeader(context, l10n.aboutApplication),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.appTitle),
                subtitle: Text(l10n.appVersion),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security_rounded),
                title: Text(l10n.dataSafety),
                subtitle: Text(l10n.dataSafetySubtitle),
                onTap: () => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.privacySnackbar))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── 5. مطور البرنامج ───────────────────────────────────────
        _sectionHeader(context, l10n.appDeveloper),
        _DevCard(isArabic: isArabic),
        const SizedBox(height: 100),
      ],
    );
  }

  static String _t(bool isArabic, {required String ar, required String en}) {
    return isArabic ? ar : en;
  }

  void _showAdhanSheet(BuildContext context, SettingsController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: ctrl,
        child: const _AdhanBottomSheet(),
      ),
    );
  }

  void _showAdhanDiagnosticsSheet(
    BuildContext context,
    SettingsController ctrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: ctrl,
        child: const _AdhanDiagnosticsSheet(),
      ),
    );
  }

  void _showCalculationMethodSheet(
    BuildContext context,
    SettingsController ctrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: ctrl,
        child: const _CalculationMethodSheet(),
      ),
    );
  }

  void _showAdhanOffsetSheet(BuildContext context, SettingsController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: ctrl,
        child: const _AdhanOffsetSheet(),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, right: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium
            ?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            )
            .merge(AppTheme.uiTextStyle),
      ),
    );
  }

  String _themeName(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Calculation Method Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════
class _CalculationMethodSheet extends StatelessWidget {
  const _CalculationMethodSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = Provider.of<SettingsController>(context);
    final isArabic = ctrl.locale.languageCode == 'ar';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.calculate_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic ? 'طريقة حساب الأوقات' : 'Calculation Method',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: ctrl.availableMethods.length,
              itemBuilder: (_, i) {
                final method = ctrl.availableMethods[i];
                final isSelected = ctrl.calculationMethod == method;
                return ListTile(
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected ? Icons.check_rounded : Icons.mosque_rounded,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    method.displayName(isArabic),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    isArabic ? method.nameEn : method.nameAr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    ctrl.updateCalculationMethod(method);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? 'تم تغيير طريقة الحساب إلى ${method.nameAr}\nسيتم تحديث الأوقات تلقائياً'
                              : 'Method changed to ${method.nameEn}\nTimes will update automatically',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Adhan Offset Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════
class _AdhanOffsetSheet extends StatefulWidget {
  const _AdhanOffsetSheet();

  @override
  State<_AdhanOffsetSheet> createState() => _AdhanOffsetSheetState();
}

class _AdhanOffsetSheetState extends State<_AdhanOffsetSheet> {
  late int _offset;

  @override
  void initState() {
    super.initState();
    final ctrl = Provider.of<SettingsController>(context, listen: false);
    _offset = ctrl.adhanOffsetMinutes;
  }

  bool get _isArabic {
    return Provider.of<SettingsController>(
          context,
          listen: false,
        ).locale.languageCode ==
        'ar';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = Provider.of<SettingsController>(context, listen: false);
    final isArabic = _isArabic;
    final presets = [0, 1, 2, 3, 5, 10, 15];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.45,
      maxChildSize: 0.75,
      builder: (_, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic ? 'تأخير الأذان' : 'Adhan Offset',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              isArabic
                  ? 'أضف دقائق بعد وقت الصلاة المحسوب لمراعاة الاختلافات المحلية.'
                  : 'Add minutes after the calculated prayer time to account for local differences.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Current value display
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _offset == 0
                    ? (isArabic ? 'بدون تأخير' : 'No offset')
                    : (isArabic ? '+$_offset دقيقة' : '+$_offset min'),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: _offset.toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              label: _offset == 0 ? '0' : '+$_offset',
              onChanged: (v) => setState(() => _offset = v.round()),
            ),
          ),
          // Presets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: presets.map((p) {
                final isSelected = _offset == p;
                return FilterChip(
                  label: Text(p == 0 ? (isArabic ? 'بدون' : 'None') : '+$p'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _offset = p),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton.icon(
              onPressed: () async {
                await ctrl.updateAdhanOffsetMinutes(_offset);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'تم الحفظ وإعادة جدولة الأذان ✓'
                            : 'Saved & Adhan rescheduled ✓',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: Text(
                isArabic ? 'حفظ وإعادة الجدولة' : 'Save & Reschedule',
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Adhan Diagnostics Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════
class _AdhanDiagnosticsSheet extends StatefulWidget {
  const _AdhanDiagnosticsSheet();

  @override
  State<_AdhanDiagnosticsSheet> createState() => _AdhanDiagnosticsSheetState();
}

class _AdhanDiagnosticsSheetState extends State<_AdhanDiagnosticsSheet> {
  bool _loading = true;
  PermissionStatus? _notificationStatus;
  bool? _canScheduleExactAlarms;
  bool? _batteryOptimizationIgnored;

  bool get _isArabic {
    final ctrl = Provider.of<SettingsController>(context, listen: false);
    return ctrl.locale.languageCode == 'ar';
  }

  String _t({required String ar, required String en}) {
    return _isArabic ? ar : en;
  }

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    PermissionStatus? notificationStatus;
    bool? canScheduleExactAlarms;
    bool? batteryOptimizationIgnored;
    try {
      notificationStatus = await Permission.notification.status;
    } catch (_) {
      notificationStatus = null;
    }
    try {
      canScheduleExactAlarms = Platform.isAndroid
          ? await NotificationService.canScheduleNativeExactAlarms()
          : true;
    } catch (_) {
      canScheduleExactAlarms = false;
    }
    try {
      batteryOptimizationIgnored = Platform.isAndroid
          ? await NotificationService.isIgnoringBatteryOptimizationsNative()
          : true;
    } catch (_) {
      batteryOptimizationIgnored = false;
    }
    if (!mounted) return;
    setState(() {
      _notificationStatus = notificationStatus;
      _canScheduleExactAlarms = canScheduleExactAlarms;
      _batteryOptimizationIgnored = batteryOptimizationIgnored;
      _loading = false;
    });
  }

  Future<void> _requestNotifications() async {
    await Permission.notification.request();
    await _refreshStatus();
  }

  Future<void> _openExactAlarmSettings(SettingsController ctrl) async {
    await ctrl.openExactAlarmSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            ar: 'ارجع للتطبيق بعد تفعيل التنبيهات الدقيقة ثم اضغط تحديث الحالة.',
            en: 'Return to the app after enabling precise alarms, then tap refresh.',
          ),
        ),
      ),
    );
  }

  Future<void> _openBatterySettings(SettingsController ctrl) async {
    await ctrl.openBatteryOptimizationSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            ar: 'ارجع للتطبيق بعد إلغاء قيود البطارية ثم اضغط تحديث الحالة.',
            en: 'Return to the app after disabling battery restrictions, then tap refresh.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = Provider.of<SettingsController>(context);
    final isArabic = ctrl.locale.languageCode == 'ar';
    final notificationOk = _notificationStatus?.isGranted ?? false;
    final exactOk = _canScheduleExactAlarms ?? false;
    final batteryOk = _batteryOptimizationIgnored ?? false;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t(
                        ar: 'فحص موثوقية الأذان',
                        en: 'Adhan reliability check',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _InfoCard(
                          title: _t(
                            ar: 'قبل الاعتماد على الأذان',
                            en: 'Before relying on Adhan',
                          ),
                          body: _t(
                            ar: 'تأكد من تفعيل الثلاث نقاط التالية. بعض أجهزة Android قد تؤخر الأذان إذا كانت قيود البطارية مفعلة.',
                            en: 'Make sure the following checks are enabled. Some Android devices may delay Adhan if battery restrictions are active.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Column(
                            children: [
                              _StatusTile(
                                icon: Icons.notifications_active_rounded,
                                title: _t(
                                  ar: 'إشعارات الصلاة',
                                  en: 'Prayer notifications',
                                ),
                                subtitle: notificationOk
                                    ? _t(
                                        ar: 'الإشعارات مفعّلة.',
                                        en: 'Notifications are enabled.',
                                      )
                                    : _t(
                                        ar: 'الإشعارات غير مفعّلة. يجب السماح بها.',
                                        en: 'Notifications are not enabled. Please allow them.',
                                      ),
                                ok: notificationOk,
                                actionLabel: notificationOk
                                    ? null
                                    : _t(ar: 'تفعيل', en: 'Enable'),
                                onAction: notificationOk
                                    ? null
                                    : _requestNotifications,
                              ),
                              const Divider(height: 1),
                              _StatusTile(
                                icon: Icons.alarm_on_rounded,
                                title: _t(
                                  ar: 'التنبيهات الدقيقة',
                                  en: 'Precise alarms',
                                ),
                                subtitle: exactOk
                                    ? _t(
                                        ar: 'التنبيهات الدقيقة مفعّلة.',
                                        en: 'Precise alarms are enabled.',
                                      )
                                    : _t(
                                        ar: 'التنبيهات الدقيقة غير مفعّلة. قد يتأخر الأذان.',
                                        en: 'Precise alarms are disabled. Adhan may be delayed.',
                                      ),
                                ok: exactOk,
                                actionLabel: exactOk
                                    ? null
                                    : _t(
                                        ar: 'فتح الإعدادات',
                                        en: 'Open settings',
                                      ),
                                onAction: exactOk
                                    ? null
                                    : () => _openExactAlarmSettings(ctrl),
                              ),
                              const Divider(height: 1),
                              _StatusTile(
                                icon: Icons.battery_saver_rounded,
                                title: _t(
                                  ar: 'قيود البطارية',
                                  en: 'Battery restrictions',
                                ),
                                subtitle: batteryOk
                                    ? _t(
                                        ar: 'التطبيق مستثنى من قيود البطارية.',
                                        en: 'The app is allowed to run without battery restrictions.',
                                      )
                                    : _t(
                                        ar: 'قد تمنع قيود البطارية الأذان في الخلفية.',
                                        en: 'Battery restrictions may delay background Adhan.',
                                      ),
                                ok: batteryOk,
                                actionLabel: batteryOk
                                    ? null
                                    : _t(
                                        ar: 'فتح الإعدادات',
                                        en: 'Open settings',
                                      ),
                                onAction: batteryOk
                                    ? null
                                    : () => _openBatterySettings(ctrl),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _refreshStatus,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                            _t(ar: 'تحديث الحالة', en: 'Refresh status'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _t(
                            ar: 'ملاحظة: وضع عدم الإزعاج أو كتم صوت الهاتف قد يمنع سماع الأذان.',
                            en: 'Note: Do Not Disturb or muted volume may prevent hearing Adhan.',
                          ),
                          textAlign: isArabic
                              ? TextAlign.right
                              : TextAlign.left,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Info Card
// ══════════════════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Status Tile
// ══════════════════════════════════════════════════════════════════════════════
class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool ok;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ok,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ok ? const Color(0xFF2E7D32) : theme.colorScheme.error;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_rounded,
            color: color,
            size: 20,
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(subtitle),
      ),
      trailing: actionLabel == null
          ? null
          : TextButton(onPressed: onAction, child: Text(actionLabel!)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Adhan Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════
class _AdhanBottomSheet extends StatefulWidget {
  const _AdhanBottomSheet();

  @override
  State<_AdhanBottomSheet> createState() => _AdhanBottomSheetState();
}

class _AdhanBottomSheetState extends State<_AdhanBottomSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ctrl = Provider.of<SettingsController>(context);
    final isArabic = ctrl.locale.languageCode == 'ar';
    final filtered = ctrl.availableAdhans
        .where((o) => o.displayName.contains(_query))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.music_note_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.selectAdhanSound,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                hintText: l10n.searchReciter,
                hintTextDirection: isArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      l10n.noResultsFound,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final opt = filtered[i];
                      final isSelected = ctrl.selectedAdhan == opt;
                      final isPreviewing =
                          ctrl.isPreviewing && ctrl.previewedAdhan == opt;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.check_rounded
                                : Icons.person_rounded,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          opt.displayName,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isPreviewing
                                ? Icon(
                                    Icons.stop_circle_rounded,
                                    key: const ValueKey('stop'),
                                    color: theme.colorScheme.error,
                                  )
                                : Icon(
                                    Icons.play_circle_outline_rounded,
                                    key: const ValueKey('play'),
                                    color: theme.colorScheme.primary,
                                  ),
                          ),
                          onPressed: isPreviewing
                              ? ctrl.stopPreview
                              : () => ctrl.previewAdhan(opt),
                        ),
                        onTap: () {
                          ctrl.selectAdhan(opt);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Developer Card
// ══════════════════════════════════════════════════════════════════════════════
class _DevCard extends StatelessWidget {
  final bool isArabic;
  const _DevCard({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => _DevDialog(isArabic: isArabic),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      theme.colorScheme.surfaceContainerHigh,
                      theme.colorScheme.surfaceContainerHighest,
                    ]
                  : [
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      theme.colorScheme.surface,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.tertiary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.5),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appDeveloper,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _BrandBadge(
                          color: const Color(0xFF0077B5),
                          icon: Icons.work_rounded,
                        ),
                        const SizedBox(width: 6),
                        _BrandBadge(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF24292E),
                          icon: Icons.code_rounded,
                        ),
                        const SizedBox(width: 6),
                        _BrandBadge(
                          color: const Color(0xFFEA4335),
                          icon: Icons.email_rounded,
                        ),
                        const Spacer(),
                        Text(
                          l10n.connect,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _BrandBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Developer Dialog
// ══════════════════════════════════════════════════════════════════════════════
class _DevDialog extends StatelessWidget {
  final bool isArabic;
  const _DevDialog({required this.isArabic});

  String _t({required String ar, required String en}) => isArabic ? ar : en;

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(ar: 'تعذر فتح الرابط', en: 'Could not open link')),
          ),
        );
      }
    }
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(ar: 'تم النسخ ✓', en: 'Copied ✓'),
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 130,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: size.width * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -10,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -40,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icon/icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 52),
            Text(
              _t(ar: 'مطور البرنامج', en: 'App Developer'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _t(ar: 'تطبيق خليك مؤمن', en: 'KhaleekMomen App'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionBtn(
                    icon: Icons.work_rounded,
                    label: 'LinkedIn',
                    color: const Color(0xFF0077B5),
                    onTap: () => _open(
                      context,
                      'https://www.linkedin.com/in/momensalman',
                    ),
                    onLongPress: () => _copy(
                      context,
                      'https://www.linkedin.com/in/momensalman',
                    ),
                  ),
                  _ActionBtn(
                    icon: Icons.code_rounded,
                    label: 'GitHub',
                    color: isDark ? Colors.white : const Color(0xFF24292E),
                    onTap: () =>
                        _open(context, 'https://github.com/dev-momensalman'),
                    onLongPress: () =>
                        _copy(context, 'https://github.com/dev-momensalman'),
                  ),
                  _ActionBtn(
                    icon: Icons.email_rounded,
                    label: _t(ar: 'راسلني', en: 'Email'),
                    color: const Color(0xFFEA4335),
                    onTap: () =>
                        _open(context, 'mailto:momensalman.dev@gmail.com'),
                    onLongPress: () =>
                        _copy(context, 'momensalman.dev@gmail.com'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                ar: 'اضغط للفتح · اضغط مطولاً للنسخ',
                en: 'Tap to open · Long press to copy',
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _t(ar: 'إغلاق', en: 'Close'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Action Button
// ══════════════════════════════════════════════════════════════════════════════
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
