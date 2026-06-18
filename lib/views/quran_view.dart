import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:islamic_audio_hub/controllers/quran_controller.dart';
import 'package:islamic_audio_hub/widgets/surah_tile.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';
import 'package:islamic_audio_hub/views/surah_detail_view.dart';

class QuranView extends StatefulWidget {
  const QuranView({super.key});

  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final quranController = Provider.of<QuranController>(context);

    final filteredSurahs = quranController.surahs.where((surah) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isEmpty) return true;
      return surah.englishName.toLowerCase().contains(query) ||
          surah.name.contains(query) ||
          surah.number.toString() == query;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ─── Continue Reading Banner ───────────────────────────────────────
          if (quranController.lastReadingPosition != null) ...[
            _buildContinueReadingCard(context, quranController),
          ],

          // ─── Reciter Selector Card ─────────────────────────────────────────
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: const Icon(Icons.person_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.currentReciter,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          quranController.selectedReciter?.name ?? 'Loading...',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    tooltip: l10n.changeReciter,
                    onPressed: quranController.reciters.isEmpty
                        ? null
                        : () => _showRecitersModal(context, quranController),
                  ),
                ],
              ),
            ),
          ),

          // ─── Search Bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchSurah,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // ─── Main List ─────────────────────────────────────────────────────
          Expanded(
            child: quranController.isLoading
                ? const Center(child: CircularProgressIndicator())
                : quranController.errorMessage != null
                ? _buildErrorWidget(quranController)
                : filteredSurahs.isEmpty
                ? Center(child: Text(l10n.noSurahsFound))
                : ListView.builder(
                    itemCount: filteredSurahs.length,
                    padding: const EdgeInsets.only(bottom: 100),
                    itemBuilder: (context, index) {
                      final surah = filteredSurahs[index];
                      return SurahTile(
                        surah: surah,
                        controller: quranController,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueReadingCard(
    BuildContext context,
    QuranController controller,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final pos = controller.lastReadingPosition!;
    final surahNumber = pos['surahNumber'] as int? ?? 1;
    final ayahNumber = pos['ayahNumber'] as int? ?? 1;
    final surahName = pos['surahName']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.tertiary,
          foregroundColor: theme.colorScheme.onTertiary,
          child: const Icon(Icons.bookmark_rounded),
        ),
        title: Text(
          l10n.continueReading,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          '$surahName • ${l10n.ayahLabel} $ayahNumber',
          style: theme.textTheme.titleMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.tertiary,
              )
              .merge(AppTheme.uiTextStyle),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () => controller.clearReadingPosition(),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
        onTap: () {
          final surah = controller.surahs.firstWhere(
            (s) => s.number == surahNumber,
            orElse: () => controller.surahs.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailView(surah: surah),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(QuranController controller) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.networkError,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // FIX: Call retryFetch() instead of selectReciter().
            // selectReciter() only rebuilds the surah list from static data
            // and does NOT make a new network request. retryFetch() calls
            // _loadInitialData() which re-fetches reciters from the API.
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgain),
              onPressed: () => controller.retryFetch(),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecitersModal(BuildContext context, QuranController controller) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectReciter,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)
                    .merge(AppTheme.uiTextStyle),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.reciters.length,
                  itemBuilder: (context, index) {
                    final reciter = controller.reciters[index];
                    final isSelected =
                        controller.selectedReciter?.id == reciter.id;
                    return ListTile(
                      title: Text(
                        reciter.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ).merge(AppTheme.uiTextStyle),
                      ),
                      subtitle: Text(
                        reciter.letter,
                        style: AppTheme.uiTextStyle,
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        controller.selectReciter(reciter);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
