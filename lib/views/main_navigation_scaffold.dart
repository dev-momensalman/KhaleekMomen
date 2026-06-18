import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:islamic_audio_hub/views/home_view.dart';
import 'package:islamic_audio_hub/views/quran_view.dart';
import 'package:islamic_audio_hub/views/radio_view.dart';
import 'package:islamic_audio_hub/views/azkar_view.dart';
import 'package:islamic_audio_hub/views/prayer_times_view.dart';
import 'package:islamic_audio_hub/views/settings_view.dart';
import 'package:islamic_audio_hub/views/favorites_view.dart';
import 'package:islamic_audio_hub/widgets/global_player_bar.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      HomeView(onTabSelected: _changeTab),
      const QuranView(),
      const RadioView(),
      const AzkarView(),
      const PrayerTimesView(),
    ];
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _getAppBarTitle(AppLocalizations l10n) {
    switch (_currentIndex) {
      case 0:
        return 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ'; // ← النص الجديد
      case 1:
        return l10n.nobleQuran;
      case 2:
        return l10n.liveRadio;
      case 3:
        return l10n.dailyAzkar;
      case 4:
        return l10n.prayerAndQibla;
      default:
        return l10n.appTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(l10n),
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.favorite_rounded),
          tooltip: l10n.favorites,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: Text(l10n.myFavorites)),
                  body: const FavoritesView(),
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text(l10n.settings)),
                    body: const SettingsView(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Current Selected View
          Positioned.fill(child: _views[_currentIndex]),

          // Global Floating Player Bar
          const Align(
            alignment: Alignment.bottomCenter,
            child: GlobalPlayerBar(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changeTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: l10n.quran,
          ),
          NavigationDestination(
            icon: const Icon(Icons.radio_outlined),
            selectedIcon: const Icon(Icons.radio_rounded),
            label: l10n.radio,
          ),
          NavigationDestination(
            icon: const Icon(Icons.brightness_medium_outlined),
            selectedIcon: const Icon(Icons.brightness_medium_rounded),
            label: l10n.azkar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.access_time_outlined),
            selectedIcon: const Icon(Icons.access_time_filled_rounded),
            label: l10n.prayer,
          ),
        ],
      ),
    );
  }
}
