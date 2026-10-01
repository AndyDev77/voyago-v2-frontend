import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/api_exceptions.dart';
import '../../models/journal.dart';
import '../../providers/journal_provider.dart';
import '../../theme.dart';

const _moodPresets = ['Émerveillé', 'Gourmand', 'Serein', 'Romantique', 'Aventure', 'Culture', 'Festif', 'Nature'];
const _maxMoods = 6;
const _maxPhotos = 6;

/// Écrit ou complète le souvenir d'un lieu : note, humeurs, visité, photos.
Future<void> showJournalEntrySheet(BuildContext context, {required String tripId, required JournalPlace place}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _JournalEntrySheet(tripId: tripId, place: place),
  );
  // Photos envoyées immédiatement, souvenir enregistré : le journal se met à jour à la fermeture
  container.invalidate(journalDetailProvider(tripId));
  container.invalidate(journalListProvider);
}

class _JournalEntrySheet extends ConsumerStatefulWidget {
  final String tripId;
  final JournalPlace place;

  const _JournalEntrySheet({required this.tripId, required this.place});

  @override
  ConsumerState<_JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends ConsumerState<_JournalEntrySheet> {
  late final TextEditingController _noteCtrl;
  final TextEditingController _customMoodCtrl = TextEditingController();
  late Set<String> _moods;
  late bool _visited;
  late List<JournalPhoto> _photos;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  JournalPlace get _place => widget.place;

  @override
  void initState() {
    super.initState();
    final entry = _place.entry;
    _noteCtrl = TextEditingController(text: entry?.note ?? '');
    _moods = {...?entry?.moodTags};
    _visited = _place.visited;
    _photos = [...?entry?.photos];
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _customMoodCtrl.dispose();
    super.dispose();
  }

  void _toggleMood(String mood) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_moods.contains(mood)) {
        _moods.remove(mood);
      } else if (_moods.length < _maxMoods) {
        _moods.add(mood);
      }
    });
  }

  void _addCustomMood() {
    final mood = _customMoodCtrl.text.trim().replaceAll('#', '');
    if (mood.isEmpty || _moods.length >= _maxMoods) return;
    setState(() => _moods.add(mood.length > 30 ? mood.substring(0, 30) : mood));
    _customMoodCtrl.clear();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= _maxPhotos || _uploading) return;
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 82);
    if (picked == null || !mounted) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final entry = await ref.read(journalApiProvider).addPhoto(
            tripId: widget.tripId,
            poiName: _place.poi.name,
            day: _place.poi.day,
            filePath: picked.path,
          );
      if (!mounted) return;
      setState(() => _photos = entry.photos);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Envoi de la photo impossible. Réessaie.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto(JournalPhoto photo) async {
    final previous = _photos;
    setState(() => _photos = _photos.where((p) => p.key != photo.key).toList());
    try {
      await ref.read(journalApiProvider).removePhoto(tripId: widget.tripId, key: photo.key);
    } catch (_) {
      if (mounted) setState(() => _photos = previous);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(journalApiProvider).saveEntry(
            tripId: widget.tripId,
            poiName: _place.poi.name,
            day: _place.poi.day,
            note: _noteCtrl.text.trim(),
            moodTags: _moods.toList(),
            visited: _visited,
          );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Enregistrement impossible. Réessaie.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: VoyagoColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: VoyagoColors.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('MON SOUVENIR',
                    style: TextStyle(color: VoyagoColors.yellow, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(_place.poi.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: VoyagoColors.text, fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),

                _sectionLabel('Photos (${_photos.length}/$_maxPhotos)'),
                _photosStrip(),
                const SizedBox(height: 18),

                _sectionLabel('Ce que tu en retiens'),
                TextField(
                  controller: _noteCtrl,
                  maxLength: 1000,
                  maxLines: 4,
                  minLines: 3,
                  style: const TextStyle(color: VoyagoColors.text, fontSize: 14, height: 1.4),
                  decoration: _inputDecoration('« Le silence absolu avant le réveil de la ville… »'),
                ),
                const SizedBox(height: 10),

                _sectionLabel('Humeurs'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final mood in {..._moodPresets, ..._moods})
                      _MoodChip(label: mood, selected: _moods.contains(mood), onTap: () => _toggleMood(mood)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customMoodCtrl,
                  maxLength: 30,
                  style: const TextStyle(color: VoyagoColors.text, fontSize: 13),
                  onSubmitted: (_) => _addCustomMood(),
                  decoration: _inputDecoration('Ajouter ta propre humeur').copyWith(
                    counterText: '',
                    prefixIcon: const Icon(Icons.tag_rounded, color: VoyagoColors.muted, size: 18),
                    suffixIcon: IconButton(
                      onPressed: _addCustomMood,
                      icon: const Icon(Icons.add_circle_rounded, color: VoyagoColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  decoration: BoxDecoration(
                    color: VoyagoColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VoyagoColors.cardBorder),
                  ),
                  child: SwitchListTile(
                    value: _visited,
                    onChanged: (v) => setState(() => _visited = v),
                    activeThumbColor: VoyagoColors.primary,
                    title: const Text('J\'ai visité ce lieu',
                        style: TextStyle(color: VoyagoColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Compté dans tes lieux visités',
                        style: TextStyle(color: VoyagoColors.muted, fontSize: 11)),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: VoyagoColors.coral, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VoyagoColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Enregistrer mon souvenir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photosStrip() {
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final photo in _photos)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(imageUrl: photo.url, width: 84, height: 84, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(photo),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_photos.length < _maxPhotos) ...[
            _AddPhotoButton(
              icon: Icons.photo_library_rounded,
              label: 'Galerie',
              loading: _uploading,
              onTap: () => _pickPhoto(ImageSource.gallery),
            ),
            const SizedBox(width: 8),
            _AddPhotoButton(
              icon: Icons.photo_camera_rounded,
              label: 'Photo',
              loading: false,
              onTap: () => _pickPhoto(ImageSource.camera),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(color: VoyagoColors.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: VoyagoColors.muted.withValues(alpha: 0.8), fontSize: 13, fontStyle: FontStyle.italic),
        filled: true,
        fillColor: VoyagoColors.background,
        counterStyle: const TextStyle(color: VoyagoColors.muted, fontSize: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VoyagoColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VoyagoColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VoyagoColors.primary),
        ),
      );
}

class _MoodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? VoyagoColors.primary.withValues(alpha: 0.16) : VoyagoColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? VoyagoColors.primary : VoyagoColors.cardBorder),
        ),
        child: Text('#$label',
            style: TextStyle(
              color: selected ? VoyagoColors.primary : VoyagoColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _AddPhotoButton({required this.icon, required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: VoyagoColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VoyagoColors.primary.withValues(alpha: 0.4)),
        ),
        child: loading
            ? const Center(
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: VoyagoColors.primary)))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: VoyagoColors.primary, size: 22),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(color: VoyagoColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}
