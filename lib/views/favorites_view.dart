import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/controllers/radio_controller.dart';
import 'package:islamic_audio_hub/controllers/quran_controller.dart';
import 'package:islamic_audio_hub/widgets/station_card.dart';
import 'package:islamic_audio_hub/widgets/surah_tile.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final radioController = Provider.of<RadioController>(context);
    final quranController = Provider.of<QuranController>(context);

    // List of favorite items
    final favoriteStations = radioController.favoriteStations;
    final favoriteSurahIds = quranController.favoriteSurahIds;
    final favoriteSurahs = quranController.surahs.where((s) {
      return favoriteSurahIds.contains(s.number.toString());
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Favorites Subtabs
          TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: [
              Tab(
                text: l10n.radioStations,
                icon: const Icon(Icons.radio_rounded),
              ),
              Tab(
                text: l10n.quranSurahs,
                icon: const Icon(Icons.menu_book_rounded),
              ),
            ],
          ),

          // Main Tabs Layout
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Favorite Radio Stations
                favoriteStations.isEmpty
                    ? _buildEmptyState(
                        context,
                        title: l10n.noRadioFavorites,
                        message: l10n.noRadioFavoritesMsg,
                        icon: Icons.radio_outlined,
                      )
                    : ListView.builder(
                        itemCount: favoriteStations.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final station = favoriteStations[index];
                          return StationCard(
                            station: station,
                            controller: radioController,
                          );
                        },
                      ),

                // Tab 2: Favorite Surahs
                favoriteSurahs.isEmpty
                    ? _buildEmptyState(
                        context,
                        title: l10n.noSurahFavorites,
                        message: l10n.noSurahFavoritesMsg,
                        icon: Icons.menu_book_outlined,
                      )
                    : ListView.builder(
                        itemCount: favoriteSurahs.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final surah = favoriteSurahs[index];
                          return SurahTile(
                            surah: surah,
                            controller: quranController,
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
