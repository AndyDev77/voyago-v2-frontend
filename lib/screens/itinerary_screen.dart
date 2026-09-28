import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../models/poi.dart';
import '../providers/trips_provider.dart';
import '../theme.dart';
import '../widgets/poi_card.dart';
import '../widgets/weather_strip.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  final String tripId;
  final Trip? trip;

  const ItineraryScreen({super.key, required this.tripId, this.trip});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  int _selectedDay = 1;
  bool _showMap = false;
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trip != null) {
      return _buildItinerary(widget.trip!);
    }

    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));
    return tripAsync.when(
      data: _buildItinerary,
      loading: () => Scaffold(
        backgroundColor: VoyagoColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: VoyagoColors.primary),
              SizedBox(height: 16),
              Text(
                'Chargement de l\'itinéraire...',
                style: TextStyle(color: VoyagoColors.muted),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: VoyagoColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Erreur'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('😕', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'Impossible de charger l\'itinéraire',
                  style: TextStyle(
                    color: VoyagoColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(color: VoyagoColors.muted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(tripDetailProvider(widget.tripId)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItinerary(Trip trip) {
    final dayPois = trip.poisForDay(_selectedDay);

    return Scaffold(
      backgroundColor: VoyagoColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partage bientôt disponible')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(trip),
            ),
          ),
        ],
        body: Column(
          children: [
            // Day tabs
            _DayTabBar(
              totalDays: trip.durationDays,
              selectedDay: _selectedDay,
              onDaySelected: (d) => setState(() => _selectedDay = d),
            ),

            // Weather strip
            if (trip.weather.isNotEmpty)
              WeatherStrip(
                weather: trip.weather,
                selectedDay: _selectedDay,
              ),

            // Map / List toggle
            _ViewToggle(
              showMap: _showMap,
              onToggle: (v) => setState(() => _showMap = v),
            ),

            // Content
            Expanded(
              child: _showMap
                  ? _buildMap(dayPois)
                  : _buildList(dayPois),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Trip trip) {
    final dateStr = DateFormat('MMM yyyy', 'fr').format(trip.createdAt);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [VoyagoColors.background, VoyagoColors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.destination,
            style: const TextStyle(
              color: VoyagoColors.text,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(label: dateStr, icon: '📅'),
              const SizedBox(width: 8),
              _InfoChip(label: '${trip.durationDays} jours', icon: '🗓'),
              const SizedBox(width: 8),
              _InfoChip(label: _paceLabel(trip.pace), icon: ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<POI> pois) {
    if (pois.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📍', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text(
              'Aucun point d\'intérêt pour ce jour',
              style: TextStyle(color: VoyagoColors.muted),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: pois.length,
      itemBuilder: (_, i) => PoiCard(poi: pois[i], index: i),
    );
  }

  Widget _buildMap(List<POI> pois) {
    if (pois.isEmpty) {
      return const Center(
        child: Text(
          'Aucun point d\'intérêt à afficher',
          style: TextStyle(color: VoyagoColors.muted),
        ),
      );
    }

    final center = LatLng(pois.first.lat, pois.first.lng);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.voyago.app',
        ),
        MarkerLayer(
          markers: pois.asMap().entries.map((entry) {
            final i = entry.key;
            final poi = entry.value;
            return Marker(
              point: LatLng(poi.lat, poi.lng),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showPoiPopup(context, poi, i),
                child: CircleAvatar(
                  backgroundColor: VoyagoColors.primary,
                  radius: 18,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showPoiPopup(BuildContext context, POI poi, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VoyagoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: VoyagoColors.primary,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    poi.name,
                    style: const TextStyle(
                      color: VoyagoColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              poi.description,
              style: const TextStyle(color: VoyagoColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Chip(label: poi.category, color: VoyagoColors.blue),
                const SizedBox(width: 8),
                _Chip(
                  label: poi.durationMinutes < 60
                      ? '${poi.durationMinutes} min'
                      : '${poi.durationMinutes ~/ 60}h',
                  color: VoyagoColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _paceLabel(String pace) {
    switch (pace.toLowerCase()) {
      case 'tranquille':
        return '🚶 Tranquille';
      case 'equilibre':
      case 'équilibré':
        return '🚴 Équilibré';
      case 'intensif':
        return '🏃 Intensif';
      default:
        return pace;
    }
  }
}

class _DayTabBar extends StatelessWidget {
  final int totalDays;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const _DayTabBar({
    required this.totalDays,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: VoyagoColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: totalDays,
        itemBuilder: (_, i) {
          final day = i + 1;
          final isSelected = day == selectedDay;
          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? VoyagoColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? VoyagoColors.primary : VoyagoColors.cardBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Jour $day',
                style: TextStyle(
                  color: isSelected ? Colors.white : VoyagoColors.muted,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool showMap;
  final ValueChanged<bool> onToggle;

  const _ViewToggle({required this.showMap, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VoyagoColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !showMap ? VoyagoColors.primary : VoyagoColors.surface,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list,
                      color: !showMap ? Colors.white : VoyagoColors.muted,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Liste',
                      style: TextStyle(
                        color: !showMap ? Colors.white : VoyagoColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: showMap ? VoyagoColors.primary : VoyagoColors.surface,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: showMap ? Colors.white : VoyagoColors.muted,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Carte',
                      style: TextStyle(
                        color: showMap ? Colors.white : VoyagoColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        icon.isNotEmpty ? '$icon $label' : label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
