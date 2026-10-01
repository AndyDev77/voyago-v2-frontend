import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../models/auth_user.dart';
import '../../models/journal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme.dart';
import 'journal_ui.dart';

/// Story Studio : story 9:16 du voyage, partage image, PDF souvenir et communauté.
Future<void> showJournalStoryStudio(BuildContext context, JournalDetail journal) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StoryStudioSheet(journal: journal),
  );
}

class _StoryStudioSheet extends ConsumerStatefulWidget {
  final JournalDetail journal;

  const _StoryStudioSheet({required this.journal});

  @override
  ConsumerState<_StoryStudioSheet> createState() => _StoryStudioSheetState();
}

class _StoryStudioSheetState extends ConsumerState<_StoryStudioSheet> {
  final GlobalKey _storyKey = GlobalKey();
  String? _busy; // 'story' | 'pdf' | 'community'
  late bool _shared = widget.journal.journalShared;

  JournalDetail get _j => widget.journal;

  /// Rendu haute définition (1080 px de large) de la story affichée.
  Future<Uint8List?> _captureStory() async {
    final boundary = _storyKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 1080 / boundary.size.width);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<File> _tempFile(String name) async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/$name');
  }

  String get _fileSlug => _j.shortDestination.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  Future<void> _shareStory() async {
    await _run('story', () async {
      final png = await _captureStory();
      if (png == null) return;
      final file = await _tempFile('voyago_story_$_fileSlug.png');
      await file.writeAsBytes(png);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: '${_j.shortDestination} : ${_j.durationDays} jours inoubliables avec Voyagooo 🦜',
        sharePositionOrigin: _shareOrigin(),
      ));
    });
  }

  Future<void> _exportPdf() async {
    await _run('pdf', () async {
      final png = await _captureStory();
      final bytes = await _buildPdf(_j, png);
      final file = await _tempFile('voyago_journal_$_fileSlug.pdf');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Mon journal de voyage — ${_j.shortDestination}',
        sharePositionOrigin: _shareOrigin(),
      ));
    });
  }

  Future<void> _shareToCommunity() async {
    await _run('community', () async {
      final xp = await ref.read(journalApiProvider).share(_j.tripId);
      if (!mounted) return;
      setState(() => _shared = true);
      ref.invalidate(journalDetailProvider(_j.tripId));
      ref.invalidate(journalListProvider);
      final user = ref.read(currentUserProvider);
      if (user != null && xp > 0) ref.invalidate(profileProvider(user.userId));
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(xp > 0 ? 'Journal partagé à la communauté ! +$xp XP 🎉' : 'Journal déjà partagé à la communauté'),
      ));
    });
  }

  Future<void> _run(String key, Future<void> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    try {
      await action();
    } catch (e) {
      debugPrint('Story studio ($key) error: $e');
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Action impossible pour le moment. Réessaie.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final height = MediaQuery.of(context).size.height;
    final storyWidth = (height * 0.5 * 9 / 16).clamp(220.0, 300.0);

    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.94),
      decoration: const BoxDecoration(
        color: VoyagoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: VoyagoColors.muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(Icons.smart_display_rounded, color: VoyagoColors.yellow, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Story Studio', style: TextStyle(color: VoyagoColors.text, fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  JournalPill(label: 'FORMAT 9:16', color: VoyagoColors.blue),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Ta story est générée à partir de ton voyage : lieux, avis, souvenirs et badge.',
                style: TextStyle(color: VoyagoColors.muted, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: VoyagoColors.background,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: VoyagoColors.cardBorder, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 40, offset: const Offset(0, 18)),
                    BoxShadow(color: VoyagoColors.yellow.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: -6),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    width: storyWidth,
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: RepaintBoundary(key: _storyKey, child: JournalStoryCard(journal: _j, user: user)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _PrimaryAction(
                icon: Icons.ios_share_rounded,
                label: 'Partager ma story',
                loading: _busy == 'story',
                onTap: _shareStory,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SecondaryAction(
                      icon: Icons.download_rounded,
                      color: VoyagoColors.blue,
                      label: 'Image HD (9:16)',
                      loading: _busy == 'story',
                      onTap: _shareStory,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SecondaryAction(
                      icon: Icons.menu_book_rounded,
                      color: VoyagoColors.yellow,
                      label: 'PDF souvenir',
                      loading: _busy == 'pdf',
                      onTap: _exportPdf,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _SecondaryAction(
                icon: _shared ? Icons.check_circle_rounded : Icons.groups_rounded,
                color: VoyagoColors.primary,
                label: _shared ? 'Partagé à la communauté Voyagooo' : 'Partager à la communauté (+5 XP)',
                loading: _busy == 'community',
                onTap: _shared ? null : _shareToCommunity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La story elle-même (aussi utilisée pour l'image et la 1re page du PDF).
class JournalStoryCard extends StatelessWidget {
  final JournalDetail journal;
  final AuthUser? user;

  const JournalStoryCard({super.key, required this.journal, this.user});

  @override
  Widget build(BuildContext context) {
    final s = journal.stats;
    final name = user?.pseudo?.isNotEmpty == true ? user!.pseudo! : (user?.name ?? 'Voyageur Voyagooo');

    return Stack(
      fit: StackFit.expand,
      children: [
        if (journal.coverImageUrl != null && journal.coverImageUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: journal.coverImageUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: VoyagoColors.background),
          )
        else
          Container(color: VoyagoColors.background),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC0F1117), Color(0x220F1117), Color(0xF50F1117)],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VoyagoColors.surface,
                      border: Border.all(color: VoyagoColors.yellow, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: user?.picture?.isNotEmpty == true
                        ? CachedNetworkImage(imageUrl: user!.picture!, fit: BoxFit.cover, width: 30, height: 30)
                        : Text(user?.avatarEmoji ?? '🦜', style: const TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: VoyagoColors.text, fontSize: 12, fontWeight: FontWeight.w800)),
                        const Text('Journal Voyagooo', style: TextStyle(color: VoyagoColors.yellow, fontSize: 9.5)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: VoyagoColors.background.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VoyagoColors.cardBorder),
                    ),
                    child: Text('${journal.durationDays} JOUR${journal.durationDays > 1 ? 'S' : ''}',
                        style: const TextStyle(color: VoyagoColors.muted, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VoyagoColors.background.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: VoyagoColors.yellow.withValues(alpha: 0.5)),
                  boxShadow: [BoxShadow(color: VoyagoColors.yellow.withValues(alpha: 0.3), blurRadius: 22, spreadRadius: -4)],
                ),
                child: Icon(journalBadgeIcon(journal.badge.icon), color: VoyagoColors.yellow, size: 34),
              ),
              const SizedBox(height: 10),
              Text(
                journal.shortDestination,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: VoyagoColors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                ),
              ),
              Text(
                journalDateRange(journal.startDate, journal.endDate).isNotEmpty
                    ? journalDateRange(journal.startDate, journal.endDate)
                    : 'Voyage terminé',
                style: const TextStyle(color: VoyagoColors.yellow, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.4),
              ),
              const Spacer(),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 5,
                runSpacing: 5,
                children: [
                  _StoryPill(icon: Icons.navigation_rounded, color: VoyagoColors.yellow, text: '${s.distanceLabel} parcourus'),
                  _StoryPill(icon: Icons.pin_drop_rounded, color: VoyagoColors.primary, text: '${s.placesCount} lieux'),
                  if (s.hiddenGems > 0)
                    _StoryPill(icon: Icons.diamond_rounded, color: VoyagoColors.blue, text: '${s.hiddenGems} pépites')
                  else if (s.favoritesCount > 0)
                    _StoryPill(icon: Icons.favorite_rounded, color: VoyagoColors.coral, text: '${s.favoritesCount} coups de cœur'),
                  if (s.avgRatingGiven != null)
                    _StoryPill(icon: Icons.star_rounded, color: VoyagoColors.yellow, text: '${s.avgRatingGiven!.toStringAsFixed(1)} / 5'),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [VoyagoColors.orange, VoyagoColors.yellow]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: VoyagoColors.background, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Badge débloqué : ${journal.badge.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: VoyagoColors.background, fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoryPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StoryPill({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: VoyagoColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VoyagoColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(color: VoyagoColors.text, fontSize: 9.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _PrimaryAction({required this.icon, required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [VoyagoColors.primaryDark, VoyagoColors.primaryLight]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: VoyagoColors.primary.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: -4)],
        ),
        child: ElevatedButton.icon(
          onPressed: loading ? null : onTap,
          icon: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : Icon(icon, size: 19),
          label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _SecondaryAction({required this.icon, required this.color, required this.label, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap == null ? 0.06 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loading
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PDF souvenir
// ---------------------------------------------------------------------------

/// Les polices PDF standard (WinAnsi) n'ont ni emojis ni étoiles : on remplace.
String _pdfSafe(String input) {
  const winAnsiExtras = '€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    if (rune < 256 || winAnsiExtras.contains(char)) {
      buffer.write(char);
    } else if (char == '★') {
      buffer.write('*');
    }
  }
  return buffer.toString().replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

Future<Uint8List> _buildPdf(JournalDetail j, Uint8List? storyPng) async {
  final doc = pw.Document(title: 'Journal de voyage — ${j.shortDestination}', author: 'Voyagooo');
  const green = PdfColor.fromInt(0xFF58CC02);
  const muted = PdfColor.fromInt(0xFF6B6B7B);
  final s = j.stats;

  if (storyPng != null) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(storyPng), height: 680)),
    ));
  }

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
    footer: (ctx) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('Voyagooo - ${ctx.pageNumber}/${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: muted)),
    ),
    build: (_) => [
      pw.Text(_pdfSafe('Journal de voyage'), style: pw.TextStyle(fontSize: 11, color: green, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Text(_pdfSafe(j.destination), style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
      pw.Text(
        _pdfSafe('${journalDateRange(j.startDate, j.endDate)}  -  ${j.durationDays} jour(s)  -  Badge : ${j.badge.title}'),
        style: const pw.TextStyle(fontSize: 11, color: muted),
      ),
      pw.SizedBox(height: 14),
      pw.Row(children: [
        for (final (label, value) in [
          ('Distance', s.distanceLabel),
          ('Lieux visites', '${s.visitedCount}/${s.placesCount}'),
          ('Coups de coeur', '${s.favoritesCount}'),
          ('Pepites', '${s.hiddenGems}'),
        ])
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(right: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: muted)),
                pw.Text(_pdfSafe(value), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
          ),
      ]),
      for (final day in j.days) ...[
        pw.SizedBox(height: 18),
        pw.Text(
          _pdfSafe('Jour ${day.day}  -  ${day.theme}${day.weather != null ? '  -  ${day.weather!.tempMax.round()}°C ${day.weather!.summary}' : ''}'),
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: green),
        ),
        pw.Divider(color: PdfColors.grey300),
        for (final place in day.places)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(
                _pdfSafe('${journalSlot(place.poi.order, day.places.length).label}  -  ${place.poi.name}'
                    '${place.myRating != null ? '  (${place.myRating}/5)' : ''}${place.poi.hiddenGem ? '  - Pepite' : ''}'),
                style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
              ),
              if ((place.entry?.note ?? '').isNotEmpty)
                pw.Text(_pdfSafe('« ${place.entry!.note} »'),
                    style: pw.TextStyle(fontSize: 10.5, fontStyle: pw.FontStyle.italic))
              else
                pw.Text(_pdfSafe(place.poi.description), style: const pw.TextStyle(fontSize: 10, color: muted)),
              if (place.entry?.moodTags.isNotEmpty ?? false)
                pw.Text(_pdfSafe(place.entry!.moodTags.map((t) => '#$t').join('  ')),
                    style: const pw.TextStyle(fontSize: 9, color: muted)),
            ]),
          ),
      ],
    ],
  ));

  return doc.save();
}
