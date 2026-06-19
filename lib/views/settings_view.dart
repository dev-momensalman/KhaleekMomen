// lib/views/settings_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:islamic_audio_hub/controllers/settings_controller.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';

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
        // ── 1. تنبيهات ──────────────────────────────────────────────
        _sectionHeader(context, l10n.audioScheduling),
        Card(
          child: SwitchListTile(
            value: ctrl.adhanAutoPlay,
            title: Text(l10n.adhanAutoplay),
            subtitle: Text(l10n.adhanAutoplaySubtitle),
            secondary: Icon(
              Icons.notifications_active_rounded,
              color: ctrl.adhanAutoPlay ? theme.colorScheme.primary : null,
            ),
            onChanged: ctrl.updateAdhanAutoPlay,
          ),
        ),
        const SizedBox(height: 24),

        // ── 2. صوت الأذان ────────────────────────────────────────────
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

        // ── 3. التخصيص ──────────────────────────────────────────────
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

        // ── 4. عن التطبيق ────────────────────────────────────────────
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

        // ── 5. مطور البرنامج ─────────────────────────────────────────
        _sectionHeader(context, l10n.appDeveloper),
        _DevCard(isArabic: isArabic),
        const SizedBox(height: 100),
      ],
    );
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

  Widget _sectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Title
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

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: l10n.searchReciter,
                hintTextDirection: TextDirection.rtl,
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

          // List
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
// Developer Card — Material 3
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
              // Avatar
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
                  // Online dot
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

              // Text
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
                        // ✅ FIX: l10n.connect بدل isArabic ternary
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
// Developer Dialog — Material 3
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
            // ── Hero Header ──────────────────────────────────────────
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
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
