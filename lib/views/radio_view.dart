import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/controllers/radio_controller.dart';
import 'package:islamic_audio_hub/widgets/station_card.dart';

class RadioView extends StatefulWidget {
  const RadioView({super.key});

  @override
  State<RadioView> createState() => _RadioViewState();
}

class _RadioViewState extends State<RadioView> {
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
    final radioController = Provider.of<RadioController>(context);

    // Filter stations based on search query
    final filteredStations = radioController.stations.where((station) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isEmpty) return true;
      return station.name.toLowerCase().contains(query) ||
          station.country.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchRadioStations,
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
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: l10n.refreshStations,
                  onPressed: radioController.isLoading
                      ? null
                      : () => radioController.fetchStations(),
                ),
              ],
            ),
          ),

          // Main List / State Handlers
          Expanded(
            child: radioController.isLoading
                ? const Center(child: CircularProgressIndicator())
                : radioController.errorMessage != null
                    ? _buildErrorWidget(radioController, l10n)
                    : filteredStations.isEmpty
                        ? Center(child: Text(l10n.noStationsMatch))
                        : ListView.builder(
                            itemCount: filteredStations.length,
                            padding: const EdgeInsets.only(bottom: 100),
                            itemBuilder: (context, index) {
                              final station = filteredStations[index];
                              return StationCard(
                                station: station,
                                controller: radioController,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(RadioController controller, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              l10n.connectionError,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
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
