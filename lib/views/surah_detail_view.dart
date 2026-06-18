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

  void _updateCurrentVisibleAyah() {
    if (!mounted || _verses.isEmpty) return;
    for (final ayah in _verses) {
      final key = _ayahKeys[ayah.number];
      if (key?.currentContext == null) continue;
      final renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) continue;
      final position = renderBox.localToGlobal(Offset.zero);
      if (position.dy + renderBox.size.height > 100) {
        _currentVisibleAyah = ayah.number;
        return;
      }
    }
  }

  void _onScroll() {
    _updateCurrentVisibleAyah();
    _savePositionTimer?.cancel();
    _savePositionTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final controller = Provider.of<QuranController>(context, listen: false);
      controller.saveReadingPosition(
        surahNumber: widget.surah.number,
        ayahNumber: _currentVisibleAyah,
        surahName: widget.surah.name,
        scrollOffset: _scrollController.offset, // ← احفظ الموضع الفعلي
      );
    });
  }

  void _scrollToLastRead(List<Ayah> verses) {
    if (_scrolledToLastRead || _lastReadAyahNumber == null) return;
    _scrolledToLastRead = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final controller = Provider.of<QuranController>(context, listen: false);
      final pos = controller.lastReadingPosition;

      // ── الخطوة 1: استخدم الـ offset المحفوظ إن وُجد ──────────
      final savedOffset = (pos?['scrollOffset'] as num?)?.toDouble();

      if (savedOffset != null && savedOffset > 0) {
        // رجع على نفس الموضع بالضبط
        final safeOffset = savedOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(safeOffset);

        // بعدها دقق الموضع باستخدام ensureVisible
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          final key = _ayahKeys[_lastReadAyahNumber!];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: 0.0,
            );
          }
        });
      } else {
        // ── Fallback: تقدير بارتفاع أعلى (280px للآية) ──────────
        final estimatedOffset = (_lastReadAyahNumber! - 1) * 280.0;
        final safeOffset = estimatedOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(safeOffset);

        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          final key = _ayahKeys[_lastReadAyahNumber!];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              alignment: 0.0,
            );
          }
        });
      }
    });
  }

  // ── Tafsir Sheet ────────────────────────────────────────────────
  void _showTafsirSheet(BuildContext context, Ayah ayah, bool isArabic) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = Provider.of<QuranController>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        height: MediaQuery.of(context).size.height * 0.82,
        child: DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '\u06dd${ayah.number}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.tafsirTitle} — ${widget.surah.name}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${l10n.ayahLabel} ${ayah.number}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      tooltip: l10n.copyAyah,
                      onPressed: () {
                        final copyText = isArabic
                            ? ayah.text
                            : '${ayah.text}\n\n${ayah.translation}';
                        Clipboard.setData(ClipboardData(text: copyText));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.ayahCopied)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: FutureBuilder<List<Ayah>>(
                  future: controller.getAyahTafsir(
                    widget.surah.number,
                    ayah.number,
                  ),
                  builder: (context, snapshot) {
                    return ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      children: [
                        // ── النص القرآني ──────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.25,
                                ),
                                theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.05,
                                ),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: Text(
                            ayah.text,
                            style: AppTheme.quranTextStyle.copyWith(
                              fontSize: 24,
                              height: 2.2,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── الترجمة (إنجليزي فقط) ─────────────────
                        if (!isArabic && ayah.translation.isNotEmpty) ...[
                          _sectionLabel(
                            context,
                            l10n.translationLabel,
                            Icons.translate_rounded,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              ayah.translation,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.7,
                                color: theme.colorScheme.onSurface,
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── التفسير ───────────────────────────────
                        _sectionLabel(
                          context,
                          l10n.tafsirLabel,
                          Icons.menu_book_rounded,
                        ),
                        const SizedBox(height: 8),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (snapshot.hasError ||
                            snapshot.data == null ||
                            snapshot.data!.isEmpty ||
                            snapshot.data!.first.tafsir.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.tafsirUnavailable,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              snapshot.data!.first.tafsir,
                              style: theme.textTheme.bodyLarge
                                  ?.merge(AppTheme.uiTextStyle)
                                  .copyWith(height: 1.9),
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
      ),
    );
  }

  // ── Section Label Helper ────────────────────────────────────────
  Widget _sectionLabel(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? widget.surah.name : widget.surah.englishName,
              style: theme.appBarTheme.titleTextStyle,
            ),
            Text(
              '${widget.surah.numberOfAyahs} ${l10n.verses}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
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
                      onPressed: () => setState(() {
                        final ctrl = Provider.of<QuranController>(
                          context,
                          listen: false,
                        );
                        _versesFuture = ctrl.getSurahVerses(
                          widget.surah.number,
                        );
                      }),
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
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToLastRead(verses),
          );

          return Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                itemCount: verses.length,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                itemBuilder: (context, index) {
                  final ayah = verses[index];
                  final isLastRead = ayah.number == _lastReadAyahNumber;

                  final itemKey = _ayahKeys.putIfAbsent(
                    ayah.number,
                    () => GlobalKey<State<StatefulWidget>>(),
                  );

                  return _AyahCard(
                    key: itemKey,
                    ayah: ayah,
                    isLastRead: isLastRead,
                    isArabic: isArabic,
                    l10n: l10n,
                    onTap: () => _showTafsirSheet(context, ayah, isArabic),
                  );
                },
              ),

              // Scroll to top FAB
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
                              onPressed: () => _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              ),
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

  // ── Jump to Ayah Dialog ─────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────
// Ayah Card Widget
// ─────────────────────────────────────────────────────────────────
class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  final bool isLastRead;
  final bool isArabic;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _AyahCard({
    super.key,
    required this.ayah,
    required this.isLastRead,
    required this.isArabic,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isLastRead
                  ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
                  : isDark
                  ? theme.colorScheme.surfaceContainerLow
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLastRead
                    ? theme.colorScheme.tertiary.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: isLastRead ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Row ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ayah number badge
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '\u06dd${ayah.number}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      // Last read badge OR tap hint
                      if (isLastRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark_rounded,
                                size: 12,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.lastReadLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Icon(
                          Icons.touch_app_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Arabic Quran Text ───────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    ayah.text,
                    style: AppTheme.quranTextStyle.copyWith(
                      fontSize: 22,
                      height: 2.1,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.justify,
                  ),
                ),

                // ── Translation (English only — hide in Arabic) ─
                if (!isArabic && ayah.translation.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      ayah.translation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.6,
                        fontSize: 13,
                      ),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ] else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
