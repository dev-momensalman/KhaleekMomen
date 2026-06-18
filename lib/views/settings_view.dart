import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:islamic_audio_hub/controllers/settings_controller.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';
import 'package:islamic_audio_hub/data/models/adhan_sound_option.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settingsController = Provider.of<SettingsController>(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. Audio and Scheduling Settings Group
        _buildSectionHeader(context, l10n.audioScheduling),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: settingsController.adhanAutoPlay,
                title: Text(l10n.adhanAutoplay),
                subtitle: Text(l10n.adhanAutoplaySubtitle),
                secondary: Icon(
                  Icons.notifications_active_rounded,
                  color: settingsController.adhanAutoPlay ? theme.colorScheme.primary : null,
                ),
                onChanged: (value) => settingsController.updateAdhanAutoPlay(value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 1b. Adhan Sound Selection
        _buildSectionHeader(context, 'صوت الأذان'),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < settingsController.availableAdhans.length; i++)
                _AdhanSoundTile(
                  option: settingsController.availableAdhans[i],
                  isSelected: settingsController.selectedAdhan ==
                      settingsController.availableAdhans[i],
                  isPreviewingThis: settingsController.isPreviewing &&
                      settingsController.previewedAdhan ==
                          settingsController.availableAdhans[i],
                  onSelect: () => settingsController
                      .selectAdhan(settingsController.availableAdhans[i]),
                  onPreview: () => settingsController
                      .previewAdhan(settingsController.availableAdhans[i]),
                  onStopPreview: settingsController.stopPreview,
                  showDivider: i < settingsController.availableAdhans.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Personalization Settings Group
        _buildSectionHeader(context, l10n.personalization),
        Card(
          child: Column(
            children: [
              // Theme Mode Selector
              ListTile(
                leading: const Icon(Icons.palette_rounded),
                title: Text(l10n.themeMode),
                subtitle: Text(_getThemeName(l10n, settingsController.themeMode)),
                trailing: DropdownButton<ThemeMode>(
                  value: settingsController.themeMode,
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
                  onChanged: (mode) {
                    if (mode != null) {
                      settingsController.updateThemeMode(mode);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              
              // Language Selector
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: Text(l10n.appLanguage),
                subtitle: Text(settingsController.locale.languageCode == 'ar' ? l10n.arabic : l10n.english),
                trailing: DropdownButton<String>(
                  value: settingsController.locale.languageCode,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(l10n.english),
                    ),
                    DropdownMenuItem(
                      value: 'ar',
                      child: Text(l10n.arabic),
                    ),
                  ],
                  onChanged: (lang) {
                    if (lang != null) {
                      settingsController.updateLanguage(lang);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. About Section Group
        _buildSectionHeader(context, l10n.aboutApplication),
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.privacySnackbar)),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 100), // padding to clear player bar
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ).merge(AppTheme.uiTextStyle), // Ensures UI text styling is used
      ),
    );
  }

  String _getThemeName(AppLocalizations l10n, ThemeMode mode) {
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

// ── Private tile widget ───────────────────────────────────────────────────────

class _AdhanSoundTile extends StatelessWidget {
  final AdhanSoundOption option;
  final bool isSelected;
  final bool isPreviewingThis;
  final VoidCallback onSelect;
  final VoidCallback onPreview;
  final VoidCallback onStopPreview;
  final bool showDivider;

  const _AdhanSoundTile({
    required this.option,
    required this.isSelected,
    required this.isPreviewingThis,
    required this.onSelect,
    required this.onPreview,
    required this.onStopPreview,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isSelected
                ? Icon(
                    Icons.check_circle_rounded,
                    key: const ValueKey('selected'),
                    color: theme.colorScheme.primary,
                  )
                : Icon(
                    Icons.radio_button_unchecked_rounded,
                    key: const ValueKey('unselected'),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
          title: Text(
            option.displayName,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
          ),
          trailing: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isPreviewingThis
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
            tooltip: isPreviewingThis ? 'إيقاف' : 'معاينة',
            onPressed: isPreviewingThis ? onStopPreview : onPreview,
          ),
          onTap: onSelect,
        ),
        if (showDivider) const Divider(height: 1, indent: 56),
      ],
    );
  }
}

