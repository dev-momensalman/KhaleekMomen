import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/controllers/radio_controller.dart';
import 'package:islamic_audio_hub/widgets/station_card.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';

class RadioView extends StatefulWidget {
  const RadioView({super.key});

  @override
  State<RadioView> createState() => _RadioViewState();
}

// ✅ FIX: AutomaticKeepAliveClientMixin يمنع إعادة بناء الـ View عند تبديل التابس
class _RadioViewState extends State<RadioView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0;

  @override
  bool get wantKeepAlive => true; // ✅ يحافظ على الـ state

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ مطلوب مع AutomaticKeepAliveClientMixin

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final radioController = Provider.of<RadioController>(context);
    final isDark = theme.brightness == Brightness.dark;

    final allStations = _selectedFilter == 1
        ? radioController.stations
              .where((s) => radioController.isFavorite(s))
              .toList()
        : radioController.stations;

    final filteredStations = allStations.where((station) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isEmpty) return true;
      return station.name.toLowerCase().contains(query) ||
          station.country.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainer
                : theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Now Playing Banner
              if (radioController.activeStation != null &&
                  radioController.isAnyPlaying)
                _buildNowPlayingBanner(context, radioController, l10n),
              if (radioController.activeStation != null &&
                  radioController.isAnyPlaying)
                const SizedBox(height: 10),

              // Search + Refresh
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchRadioStations,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: radioController.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.refresh_rounded,
                              color: theme.colorScheme.primary,
                            ),
                      onPressed: radioController.isLoading
                          ? null
                          : () => radioController.fetchStations(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Chips
              Row(
                children: [
                  _FilterChip(
                    label: l10n.filterAll,
                    icon: Icons.radio_rounded,
                    count: radioController.stations.length,
                    selected: _selectedFilter == 0,
                    onTap: () => setState(() => _selectedFilter = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.filterFavorites,
                    icon: Icons.favorite_rounded,
                    count: radioController.stations
                        .where((s) => radioController.isFavorite(s))
                        .length,
                    selected: _selectedFilter == 1,
                    onTap: () => setState(() => _selectedFilter = 1),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.resultCount(filteredStations.length),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ── Station List ─────────────────────────────────────────
        Expanded(
          child: radioController.isLoading
              ? _buildShimmer(theme)
              : radioController.errorMessage != null
              ? _buildErrorWidget(radioController, l10n)
              : filteredStations.isEmpty
              ? _buildEmptyState(context, l10n)
              : ListView.builder(
                  itemCount: filteredStations.length,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  itemBuilder: (context, index) {
                    return StationCard(
                      station: filteredStations[index],
                      controller: radioController,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Now Playing Banner ─────────────────────────────────────────
  Widget _buildNowPlayingBanner(
    BuildContext context,
    RadioController controller,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final station = controller.activeStation!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE67E22).withValues(alpha: 0.15),
            const Color(0xFFC0392B).withValues(alpha: 0.08),
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE67E22).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.nowPlaying,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(
                        color: const Color(0xFFE67E22),
                        fontWeight: FontWeight.bold,
                      )
                      .merge(AppTheme.uiTextStyle),
                ),
                Text(
                  station.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)
                      .merge(AppTheme.uiTextStyle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.stop_rounded),
            color: const Color(0xFFE67E22),
            onPressed: () => controller.stopStation(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ── Shimmer Loading ────────────────────────────────────────────
  Widget _buildShimmer(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemCount: 8,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 76,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter == 1
                ? Icons.favorite_border_rounded
                : Icons.search_off_rounded,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFilter == 1
                ? l10n.noFavoriteStationsYet
                : l10n.noStationsMatch,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error Widget ───────────────────────────────────────────────
  Widget _buildErrorWidget(RadioController controller, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 34,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.connectionError,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgain),
              onPressed: () => controller.fetchStations(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              '$label ($count)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
