import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api_exceptions.dart';
import '../models/place_stats.dart';
import '../models/poi.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/place_stats_provider.dart';
import '../providers/profile_provider.dart';
import '../services/app_rating_service.dart';
import '../theme.dart';

/// Lieu à noter : depuis une carte de l'itinéraire ou une notification d'arrivée.
class ReviewTarget {
  final String name;
  final double lat;
  final double lng;
  final String? imageUrl;
  final String? destination;
  final String? tripId;

  const ReviewTarget({
    required this.name,
    required this.lat,
    required this.lng,
    this.imageUrl,
    this.destination,
    this.tripId,
  });

  factory ReviewTarget.fromPoi(POI poi, {String? destination, String? tripId}) => ReviewTarget(
        name: poi.name,
        lat: poi.lat,
        lng: poi.lng,
        imageUrl: poi.imageUrl,
        destination: destination,
        tripId: tripId,
      );
}

/// Ouvre la feuille d'avis (étoiles, like, commentaire) d'un lieu.
Future<void> showPlaceReviewSheet(BuildContext context, ReviewTarget target, {bool fromArrival = false}) async {
  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlaceReviewSheet(target: target, fromArrival: fromArrival),
  );
  // Après un avis réussi, moment idéal pour proposer de noter l'app sur le store
  if (submitted == true && context.mounted) {
    await AppRatingService.instance.maybeAskForStoreRating(context);
  }
}

class _PlaceReviewSheet extends ConsumerStatefulWidget {
  final ReviewTarget target;
  final bool fromArrival;

  const _PlaceReviewSheet({required this.target, required this.fromArrival});

  @override
  ConsumerState<_PlaceReviewSheet> createState() => _PlaceReviewSheetState();
}

class _PlaceReviewSheetState extends ConsumerState<_PlaceReviewSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  double _rating = 0;
  bool _liked = false;
  bool _submitting = false;
  String? _error;
  late final Future<List<PlaceReview>> _reviewsFuture;

  ReviewTarget get _t => widget.target;

  @override
  void initState() {
    super.initState();
    final stats = ref.read(placeStatsProvider)[placeCacheKey(_t.name, _t.lat, _t.lng)];
    // Modification d'un avis existant : on repart de la note donnée
    if (stats?.myRating != null) _rating = stats!.myRating!.toDouble();
    _liked = stats?.myLiked ?? false;
    _reviewsFuture = ref
        .read(placesApiProvider)
        .latestReviews(name: _t.name, lat: _t.lat, lng: _t.lng, limit: 3)
        .catchError((_) => <PlaceReview>[]);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final comment = _commentCtrl.text.trim();
      final res = await ref.read(placesApiProvider).review(
            placeName: _t.name,
            lat: _t.lat,
            lng: _t.lng,
            rating: _rating.round(),
            comment: comment.isEmpty ? null : comment,
            liked: _liked,
            destination: _t.destination,
            tripId: _t.tripId,
          );
      ref.read(placeStatsProvider.notifier).put(_t.name, _t.lat, _t.lng, res.stats);
      ref.read(notificationsProvider.notifier).markPlaceReviewed(_t.name);
      final user = ref.read(currentUserProvider);
      if (user != null && res.isNew) ref.invalidate(profileProvider(user.userId));
      HapticFeedback.mediumImpact();

      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop(true);
      messenger?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: VoyagoColors.surface,
          content: Text(
            res.isNew ? 'Merci pour ton avis ! +2 XP ⭐' : 'Ton avis a été mis à jour ⭐',
            style: const TextStyle(color: VoyagoColors.text, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible d\'envoyer ton avis. Réessaie.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isAuthenticatedProvider);
    final stats = ref.watch(placeStatsProvider)[placeCacheKey(_t.name, _t.lat, _t.lng)];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
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
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 18),
                _header(stats),
                const SizedBox(height: 20),
                if (!isLoggedIn)
                  _guestPrompt()
                else ...[
                  Center(
                    child: Text(
                      _rating == 0 ? 'Touche les étoiles pour noter' : _ratingLabel(_rating.round()),
                      style: TextStyle(
                        color: _rating == 0 ? VoyagoColors.muted : VoyagoColors.yellow,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: RatingBar(
                      key: ValueKey('rating_${stats?.myRating}'),
                      initialRating: _rating,
                      filledIcon: Icons.star_rounded,
                      emptyIcon: Icons.star_outline_rounded,
                      filledColor: VoyagoColors.yellow,
                      emptyColor: VoyagoColors.muted.withValues(alpha: 0.5),
                      alignment: Alignment.center,
                      size: 44,
                      onRatingChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() => _rating = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _likeToggle(),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _commentCtrl,
                    maxLength: 500,
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(color: VoyagoColors.text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Un conseil pour les prochains voyageurs ? (facultatif)',
                      hintStyle: TextStyle(color: VoyagoColors.muted.withValues(alpha: 0.8), fontSize: 13),
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
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Text(_error!, style: const TextStyle(color: VoyagoColors.coral, fontSize: 12)),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _rating >= 1 && !_submitting ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VoyagoColors.primary,
                        disabledBackgroundColor: VoyagoColors.primary.withValues(alpha: 0.25),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              stats?.myRating != null ? 'Mettre à jour mon avis' : 'Publier mon avis',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                _communityReviews(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(PlaceStats? stats) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _t.imageUrl != null && _t.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: _t.imageUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _imagePlaceholder(),
                  placeholder: (_, __) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fromArrival ? 'Tu es arrivé ! 📍' : 'Ton avis compte',
                style: const TextStyle(
                  color: VoyagoColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _t.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: VoyagoColors.text, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              if (stats != null && stats.hasCommunityReviews)
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: VoyagoColors.yellow, size: 15),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${stats.ratingAvg!.toStringAsFixed(1)} · ${stats.reviewsCount} avis voyageurs'
                        '${stats.likesCount > 0 ? ' · ${stats.likesCount} ❤' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: VoyagoColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'Sois le premier voyageur à noter ce lieu',
                  style: TextStyle(color: VoyagoColors.muted, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _likeToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _liked = !_liked);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _liked ? VoyagoColors.coral.withValues(alpha: 0.12) : VoyagoColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _liked ? VoyagoColors.coral.withValues(alpha: 0.5) : VoyagoColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            AnimatedScale(
              scale: _liked ? 1.15 : 1,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _liked ? VoyagoColors.coral : VoyagoColors.muted,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _liked ? 'Coup de cœur ! Je recommande ce lieu' : 'J\'ai adoré ce lieu',
                style: TextStyle(
                  color: _liked ? VoyagoColors.text : VoyagoColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoyagoColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VoyagoColors.cardBorder),
      ),
      child: Column(
        children: [
          const Text(
            'Connecte-toi pour noter ce lieu et gagner de l\'XP',
            textAlign: TextAlign.center,
            style: TextStyle(color: VoyagoColors.text, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/auth');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VoyagoColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _communityReviews() {
    return FutureBuilder<List<PlaceReview>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <PlaceReview>[];
        if (reviews.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AVIS DES VOYAGEURS',
              style: TextStyle(color: VoyagoColors.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            ...reviews.map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VoyagoColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VoyagoColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(r.authorEmoji ?? '🧳', style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.authorName ?? 'Voyageur',
                            style: const TextStyle(color: VoyagoColors.text, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                        RatingBar.readOnly(
                          initialRating: r.rating.toDouble(),
                          filledIcon: Icons.star_rounded,
                          emptyIcon: Icons.star_outline_rounded,
                          filledColor: VoyagoColors.yellow,
                          emptyColor: VoyagoColors.muted.withValues(alpha: 0.4),
                          size: 14,
                        ),
                        if (r.liked) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.favorite_rounded, color: VoyagoColors.coral, size: 14),
                        ],
                      ],
                    ),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.comment, style: const TextStyle(color: VoyagoColors.muted, fontSize: 12, height: 1.35)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 64,
        height: 64,
        color: VoyagoColors.background,
        child: const Icon(Icons.place_rounded, color: VoyagoColors.primary),
      );

  static String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Décevant';
      case 2:
        return 'Bof';
      case 3:
        return 'Sympa';
      case 4:
        return 'Très bien !';
      default:
        return 'Incontournable ! 🤩';
    }
  }
}
