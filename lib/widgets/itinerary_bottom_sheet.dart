import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart';
import '../models/poi.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/route_service.dart';
import '../theme.dart';

/// Draggable bottom sheet showing the traveler dashboard & day POI timeline.
/// Faithful adaptation of the HTML template right sidebar for mobile.
class ItineraryBottomSheet extends ConsumerWidget {
  final List<POI> pois;
  final int selectedDay;
  final int totalDays;
  final String destination;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<POI>? onPoiTap;

  /// Position GPS en temps réel de l'utilisateur connecté.
  final LatLng? userPosition;

  /// Distances calculées depuis la position GPS vers chaque POI (index -> RouteResult).
  final Map<int, RouteResult>? poiDistances;

  /// Distances calculées entre POIs consécutifs (index du premier POI -> RouteResult).
  final Map<int, RouteResult>? transitRoutes;

  /// Callback pour lancer la navigation vers un POI.
  final ValueChanged<POI>? onNavigateToPoi;

  const ItineraryBottomSheet({
    super.key,
    required this.pois,
    required this.selectedDay,
    required this.totalDays,
    required this.destination,
    required this.onDayChanged,
    this.onPoiTap,
    this.userPosition,
    this.poiDistances,
    this.transitRoutes,
    this.onNavigateToPoi,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final profileAsync = user != null ? ref.watch(profileProvider(user.userId)) : null;
    final profile = profileAsync?.valueOrNull;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.15,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.15, 0.45, 0.88],
      builder: (ctx, controller) {
        return Container(
          decoration: BoxDecoration(
            color: VoyagoColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
            border: Border(
              top: BorderSide(color: VoyagoColors.cardBorder.withValues(alpha: 0.5)),
            ),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VoyagoColors.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // === PROFILE & GAMIFICATION HEADER (from HTML mockup) ===
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar with Level badge
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: VoyagoColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                user?.avatarDisplay ?? '✈️',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: VoyagoColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: VoyagoColors.surface, width: 2),
                                ),
                                child: Text(
                                  'Lvl ${profile?.level ?? 12}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Name & subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Alex Traveler',
                                style: const TextStyle(
                                  color: VoyagoColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Explorateur · $destination',
                                style: TextStyle(
                                  color: VoyagoColors.muted.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Notification / Share action
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: VoyagoColors.muted, size: 22),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Aucune nouvelle notification de voyage'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 2 Stat cards (XP Earned & Streak)
                    Row(
                      children: [
                        // XP Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: VoyagoColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: VoyagoColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.star, color: VoyagoColors.yellow, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'XP GAGNÉS',
                                      style: TextStyle(
                                        color: VoyagoColors.yellow,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile != null ? '${profile.xp}' : '2,450',
                                  style: const TextStyle(
                                    color: VoyagoColors.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Streak Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: VoyagoColors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: VoyagoColors.orange.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.local_fire_department, color: VoyagoColors.orange, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'STREAK',
                                      style: TextStyle(
                                        color: VoyagoColors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${profile?.streak ?? 14} Jours',
                                  style: const TextStyle(
                                    color: VoyagoColors.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(color: VoyagoColors.cardBorder, height: 1),

              // === DAY HEADER & CONTROLS ===
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jour $selectedDay',
                            style: const TextStyle(
                              color: VoyagoColors.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pois.length} activités · Étape à $destination',
                            style: const TextStyle(
                              color: VoyagoColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Day navigation arrows
                    Container(
                      decoration: BoxDecoration(
                        color: VoyagoColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: VoyagoColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DayArrow(
                            icon: Icons.chevron_left,
                            enabled: selectedDay > 1,
                            onTap: () => onDayChanged(selectedDay - 1),
                          ),
                          Container(width: 1, height: 24, color: VoyagoColors.cardBorder),
                          _DayArrow(
                            icon: Icons.chevron_right,
                            enabled: selectedDay < totalDays,
                            onTap: () => onDayChanged(selectedDay + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Day pills horizontal list
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: totalDays,
                  itemBuilder: (_, i) {
                    final day = i + 1;
                    final isActive = day == selectedDay;
                    return GestureDetector(
                      onTap: () => onDayChanged(day),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: isActive ? VoyagoColors.primary : VoyagoColors.background,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isActive ? VoyagoColors.primary : VoyagoColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          'Jour $day',
                          style: TextStyle(
                            color: isActive ? Colors.white : VoyagoColors.muted,
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // === TIMELINE ===
              // === BADGE DISTANCE DEPUIS POSITION GPS (1er POI seulement) ===
              if (userPosition != null && poiDistances != null && poiDistances!.containsKey(0) && pois.isNotEmpty)
                _UserToFirstPoiBadge(
                  distance: poiDistances![0]!,
                  poiName: pois.first.name,
                  onNavigate: onNavigateToPoi != null ? () => onNavigateToPoi!(pois.first) : null,
                ),

              if (pois.isEmpty)
                _EmptyState()
              else
                ...pois.asMap().entries.expand((entry) {
                  final i = entry.key;
                  final poi = entry.value;
                  final isLast = i == pois.length - 1;
                  return [
                    _TimelinePOI(
                      poi: poi,
                      index: i,
                      isFirst: i == 0,
                      onTap: () => onPoiTap?.call(poi),
                      distanceFromUser: poiDistances?[i],
                      onNavigate: onNavigateToPoi != null ? () => onNavigateToPoi!(poi) : null,
                    ),
                    if (!isLast)
                      _TransitSegment(
                        poi: poi,
                        nextPoi: pois[i + 1],
                        routeResult: transitRoutes?[i],
                      ),
                  ];
                }),

              // Add plan placeholder card at the end of the day
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: VoyagoColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: VoyagoColors.cardBorder,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: VoyagoColors.muted.withValues(alpha: 0.6), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Ajouter une étape personnalisée...',
                        style: TextStyle(
                          color: VoyagoColors.muted.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A single POI item in the timeline
class _TimelinePOI extends StatelessWidget {
  final POI poi;
  final int index;
  final bool isFirst;
  final VoidCallback? onTap;
  final RouteResult? distanceFromUser;
  final VoidCallback? onNavigate;

  const _TimelinePOI({
    required this.poi,
    required this.index,
    this.isFirst = false,
    this.onTap,
    this.distanceFromUser,
    this.onNavigate,
  });

  String get _timeLabel {
    const startHour = 9;
    final totalMinutes = startHour * 60 + (index * (poi.durationMinutes + 20));
    final h = (totalMinutes ~/ 60) % 24;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final aiTip = poi.insiderTip ?? _defaultInsight(poi.category, poi.name);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VoyagoColors.surface,
                        border: Border.all(
                          color: isFirst
                              ? VoyagoColors.primary
                              : VoyagoColors.muted.withValues(alpha: 0.4),
                          width: 3,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: VoyagoColors.cardBorder,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Card content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time badge & category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: VoyagoColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _timeLabel,
                            style: const TextStyle(
                              color: VoyagoColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _categoryLabel(poi.category),
                          style: const TextStyle(
                            color: VoyagoColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // POI Card
                    Container(
                      decoration: BoxDecoration(
                        color: VoyagoColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: VoyagoColors.cardBorder),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: poi.imageUrl != null && poi.imageUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: poi.imageUrl!,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => _imgPlaceholder(),
                                        errorWidget: (_, __, ___) => _imgPlaceholder(),
                                      )
                                    : _imgPlaceholder(),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      poi.name,
                                      style: const TextStyle(
                                        color: VoyagoColors.text,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),

                                    // Rating
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${poi.rating.toStringAsFixed(1)} (${_formatReviews(poi.reviewsCount)})',
                                          style: const TextStyle(
                                            color: VoyagoColors.text,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    Text(
                                      poi.description,
                                      style: const TextStyle(
                                        color: VoyagoColors.muted,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // AI Insight Badge (from HTML mockup)
                          if (aiTip.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: VoyagoColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: VoyagoColors.primary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: VoyagoColors.primary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      aiTip,
                                      style: TextStyle(
                                        color: VoyagoColors.primary.withValues(alpha: 0.9),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Tags + Distance badge
                          Row(
                            children: [
                              _Tag(
                                label: poi.category,
                                color: VoyagoColors.blue,
                              ),
                              const SizedBox(width: 6),
                              _Tag(
                                label: _durationLabel(poi.durationMinutes),
                                color: VoyagoColors.primary,
                              ),
                              if (distanceFromUser != null) ...[
                                const SizedBox(width: 6),
                                _Tag(
                                  label: '📍 ${distanceFromUser!.distanceLabel}',
                                  color: const Color(0xFF4CAF50),
                                ),
                              ],
                              const Spacer(),
                              if (onNavigate != null)
                                GestureDetector(
                                  onTap: onNavigate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: VoyagoColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: VoyagoColors.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.directions_walk, color: VoyagoColors.primary, size: 13),
                                        SizedBox(width: 3),
                                        Text(
                                          'Y aller',
                                          style: TextStyle(
                                            color: VoyagoColors.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: VoyagoColors.cardBorder,
      alignment: Alignment.center,
      child: const Text('📍', style: TextStyle(fontSize: 24)),
    );
  }

  static String _formatReviews(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  static String _defaultInsight(String category, String name) {
    switch (category.toLowerCase()) {
      case 'gastronomie':
      case 'restaurant':
        return 'Goûtez la spécialité maison du chef, un délice incontournable.';
      case 'culture':
      case 'art':
      case 'museum':
        return 'Visite idéale en matinée pour profiter du calme et des meilleures lumières.';
      case 'nature':
      case 'parc':
        return 'Superbe spot photo près de l\'allée principale au coucher du soleil.';
      default:
        return 'Conseil d\'initié : arrivez 15 min avant l\'affluence pour en profiter pleinement.';
    }
  }

  static String _categoryLabel(String cat) {
    switch (cat.toLowerCase()) {
      case 'gastronomie':
        return 'Gastronomie';
      case 'culture':
        return 'Culture';
      case 'nature':
        return 'Nature';
      case 'nightlife':
        return 'Sortie';
      case 'bien_etre':
        return 'Bien-être';
      case 'art':
        return 'Art';
      case 'shopping':
        return 'Shopping';
      default:
        return cat;
    }
  }

  static String _durationLabel(int mins) {
    if (mins < 60) return '${mins}min';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}

/// Transit segment between two POIs
class _TransitSegment extends StatelessWidget {
  final POI poi;
  final POI nextPoi;
  final RouteResult? routeResult;

  const _TransitSegment({
    required this.poi,
    required this.nextPoi,
    this.routeResult,
  });

  @override
  Widget build(BuildContext context) {
    final label = routeResult != null
        ? '${routeResult!.durationLabel} · ${routeResult!.distanceLabel}'
        : '~15 min à pied';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Timeline connector
          SizedBox(
            width: 32,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: VoyagoColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: VoyagoColors.cardBorder),
                ),
                child: Icon(
                  Icons.directions_walk,
                  color: VoyagoColors.muted.withValues(alpha: 0.6),
                  size: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Container(height: 1, width: 24, color: VoyagoColors.cardBorder),
                const SizedBox(width: 8),
                Icon(
                  Icons.directions_walk,
                  color: VoyagoColors.primary.withValues(alpha: 0.5),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: routeResult != null
                        ? VoyagoColors.text.withValues(alpha: 0.7)
                        : VoyagoColors.muted.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: routeResult != null ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: VoyagoColors.cardBorder)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge compact montrant la distance entre l'utilisateur et le premier POI de la journée
class _UserToFirstPoiBadge extends StatelessWidget {
  final RouteResult distance;
  final String poiName;
  final VoidCallback? onNavigate;

  const _UserToFirstPoiBadge({
    required this.distance,
    required this.poiName,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GestureDetector(
        onTap: onNavigate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VoyagoColors.primary.withValues(alpha: 0.12),
                VoyagoColors.blue.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: VoyagoColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: VoyagoColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: VoyagoColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vers ${poiName.length > 22 ? '${poiName.substring(0, 20)}…' : poiName}',
                      style: const TextStyle(
                        color: VoyagoColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${distance.durationLabel} à pied · ${distance.distanceLabel}',
                      style: TextStyle(
                        color: VoyagoColors.muted.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: VoyagoColors.primary,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small colored tag
class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Day arrow button
class _DayArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _DayArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          color: enabled ? VoyagoColors.text : VoyagoColors.muted.withValues(alpha: 0.3),
          size: 20,
        ),
      ),
    );
  }
}

/// Empty state when no POIs
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: VoyagoColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VoyagoColors.cardBorder),
      ),
      child: const Column(
        children: [
          Text('📍', style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(
            'Aucune activité pour ce jour',
            style: TextStyle(
              color: VoyagoColors.muted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
