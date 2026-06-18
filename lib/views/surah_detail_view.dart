import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/controllers/quran_controller.dart';
import 'package:islamic_audio_hub/data/models/surah.dart';
import 'package:islamic_audio_hub/data/models/ayah.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';

class SurahDetailView extends StatefulWidget {
  final Surah surah;

  const SurahDetailView({super.key, required this.surah});

  @override
  State<SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<SurahDetailView> {
  late Future<List<Ayah>> _versesFuture;

  final ScrollController _scrollController = ScrollController();
  Timer? _savePositionTimer;
  int _currentVisibleAyah = 1;
  int? _lastReadAyahNumber;

  bool _scrolledToLastRead = false;
  final Map<int, GlobalKey<State<StatefulWidget>>> _ayahKeys = {};

  List<Ayah> _verses = [];

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<QuranController>(context, listen: false);
    _versesFuture = controller.getSurahVerses(widget.surah.number);

    final pos = controller.lastReadingPosition;
    if (pos != null && pos['surahNumber'] == widget.surah.number) {
      _lastReadAyahNumber = pos['ayahNumber'] as int?;
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _savePositionTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // FIX: Replaced inaccurate pixel-based tracking (offset / 100) with
  // RenderBox-based tracking that finds the first ayah actually visible
  // on screen. The old approach assumed each ayah was exactly 100px tall,
  // causing the saved position to be completely wrong for most surahs.
  void _updateCurrentVisibleAyah() {
    if (!mounted || _verses.isEmpty) return;
    for (final ayah in _verses) {
      final key = _ayahKeys[ayah.number];
      if (key?.currentContext == null) continue;
      final renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) continue;
      final position = renderBox.localToGlobal(Offset.zero);
      // First ayah whose bottom edge is still visible below the AppBar (~100px)
      if (position.dy + renderBox.size.height > 100) {
        _currentVisibleAyah = ayah.number;
        return;
      }
    }
  }

  void _onScroll() {
    // Track the first visible ayah accurately using RenderBox
    _updateCurrentVisibleAyah();

    // Debounced save: wait 1 second after user stops scrolling
    _savePositionTimer?.cancel();
    _savePositionTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final controller = Provider.of<QuranController>(context, listen: false);
      controller.saveReadingPosition(
        surahNumber: widget.surah.number,
        ayahNumber: _currentVisibleAyah,
        surahName: widget.surah.name,
      );
    });
  }

  void _scrollToLastRead(List<Ayah> verses) {
    if (_scrolledToLastRead || _lastReadAyahNumber == null) return;
    _scrolledToLastRead = true;

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final key = _ayahKeys[_lastReadAyahNumber!];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  void _showTafsirSheet(BuildContext context, Ayah ayah) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = Provider.of<QuranController>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.primary,
                    child: Text(
                      '\u06dd${ayah.number}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${l10n.tafsirTitle} — ${widget.surah.name}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined),
                    tooltip: l10n.copyAyah,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: '${ayah.text}\n\n${ayah.translation}',
                        ),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.ayahCopied)));
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: FutureBuilder<List<Ayah>>(
                future: controller.getAyahTafsir(
                  widget.surah.number,
                  ayah.number,
                ),
                builder: (context, snapshot) {
                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ayah.text,
                          style: AppTheme.quranTextStyle.copyWith(
                            fontSize: 24,
                            height: 2.0,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.translationLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ayah.translation,
                        style: theme.textTheme.bodyLarge
                            ?.merge(AppTheme.uiTextStyle)
                            .copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.tafsirLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (snapshot.hasError ||
                          snapshot.data == null ||
                          snapshot.data!.isEmpty ||
                          snapshot.data!.first.tafsir.isEmpty)
                        Text(
                          l10n.tafsirUnavailable,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            snapshot.data!.first.tafsir,
                            style: theme.textTheme.bodyLarge
                                ?.merge(AppTheme.uiTextStyle)
                                .copyWith(height: 1.7),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? widget.surah.name : widget.surah.englishName,
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_numbered_rounded),
            tooltip: l10n.jumpToAyah,
            onPressed: () => _showJumpToAyahDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Ayah>>(
        future: _versesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
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
                      snapshot.error
                          .toString()
                          .replaceAll('Exception:', '')
                          .trim(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.tryAgain),
                      onPressed: () {
                        setState(() {
                          final ctrl = Provider.of<QuranController>(
                            context,
                            listen: false,
                          );
                          _versesFuture = ctrl.getSurahVerses(
                            widget.surah.number,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          final verses = snapshot.data ?? [];
          if (verses.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noVersesFound),
            );
          }

          _verses = verses;

          // Auto-scroll to last read position once after first render.
          // Using a flag (_scrolledToLastRead) prevents repeated scrolling
          // on every rebuild.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToLastRead(verses),
          );

          return Stack(
            children: [
              ListView.separated(
                controller: _scrollController,
                itemCount: verses.length,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                separatorBuilder: (context, index) =>
                    Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
                itemBuilder: (context, index) {
                  final ayah = verses[index];
                  final isLastRead = ayah.number == _lastReadAyahNumber;

                  final itemKey = _ayahKeys.putIfAbsent(
                    ayah.number,
                    () => GlobalKey<State<StatefulWidget>>(),
                  );

                  return InkWell(
                    key: itemKey,
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showTafsirSheet(context, ayah),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isLastRead
                            ? theme.colorScheme.tertiaryContainer.withValues(
                                alpha: 0.35,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isLastRead
                            ? Border.all(
                                color: theme.colorScheme.tertiary.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '\u06dd${ayah.number}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isLastRead)
                                Chip(
                                  label: Text(
                                    l10n.lastReadLabel,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  avatar: Icon(
                                    Icons.bookmark_rounded,
                                    size: 14,
                                    color: theme.colorScheme.tertiary,
                                  ),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: theme
                                      .colorScheme
                                      .tertiaryContainer
                                      .withValues(alpha: 0.5),
                                ),
                              if (!isLastRead)
                                Icon(
                                  Icons.touch_app_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.35),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            ayah.text,
                            style: AppTheme.quranTextStyle,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            ayah.translation,
                            style: theme.textTheme.bodyMedium
                                ?.merge(AppTheme.uiTextStyle)
                                .copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Floating "scroll to top" button
              Positioned(
                bottom: 100,
                right: 16,
                child: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    final show =
                        _scrollController.hasClients &&
                        _scrollController.offset > 300;
                    return AnimatedOpacity(
                      opacity: show ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: show
                          ? FloatingActionButton.small(
                              heroTag: 'scrollTop',
                              onPressed: () {
                                _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Icon(
                                Icons.keyboard_arrow_up_rounded,
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showJumpToAyahDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.jumpToAyah),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.ayahNumberHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) => _jumpToAyah(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => _jumpToAyah(ctx, int.tryParse(ctrl.text)),
            child: Text(l10n.go),
          ),
        ],
      ),
    );
  }

  void _jumpToAyah(BuildContext ctx, int? ayahNum) {
    Navigator.pop(ctx);
    if (ayahNum == null || _verses.isEmpty) return;

    final key = _ayahKeys[ayahNum];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }
}
