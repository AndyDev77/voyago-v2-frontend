import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../models/trip.dart';
import '../models/poi.dart';
import '../models/day_weather.dart';
import '../providers/auth_provider.dart';
import '../providers/trips_provider.dart';
import '../services/live_weather_service.dart';
import '../services/map_ambiance_service.dart';
import '../theme.dart';
import '../widgets/weather_overlay.dart';
import '../widgets/itinerary_bottom_sheet.dart';
import '../widgets/map_poi_pin.dart';
import '../widgets/traveler_drawer.dart';
import '../widgets/map_ambiance_overlay.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  final String tripId;
  final Trip? trip;

  const ItineraryScreen({super.key, required this.tripId, this.trip});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimatedMapController _animatedMapController;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  int _selectedDay = 1;
  int? _activePoiIndex;
  Trip? _currentTrip;
  String _activeCityName = '';
  List<DayWeather>? _dynamicWeather;
  List<CityLocation> _searchResults = [];
  bool _isSearching = false;
  bool _showWeatherCard = true;
  bool _isWeatherMinimized = false;
  bool _forceDayMap = false;
  LatLng? _currentCenter;
  LatLng? _liveUserPosition;
  StreamSubscription<Position>? _userPositionSub;
  Timer? _ambianceRefreshTimer;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    if (widget.trip != null) {
      _currentTrip = widget.trip;
      _activeCityName = widget.trip!.destination;
    }
    // Mise à jour automatique minute par minute de l'ambiance solaire (comme hellobarber)
    _ambianceRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLiveLocationAndWeather();
      _bootstrapLiveWeather();
    });
  }

  @override
  void didUpdateWidget(covariant ItineraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trip != null && widget.trip != oldWidget.trip) {
      setState(() {
        _currentTrip = widget.trip;
        _activeCityName = widget.trip!.destination;
        _selectedDay = 1;
        _activePoiIndex = null;
        _dynamicWeather = null;
        _currentCenter = null;
      });
      _bootstrapLiveWeather();
    } else if (widget.tripId.isNotEmpty && widget.tripId != oldWidget.tripId) {
      setState(() {
        _currentTrip = null;
        _selectedDay = 1;
        _activePoiIndex = null;
        _dynamicWeather = null;
        _currentCenter = null;
      });
    }
  }

  void _showSafeSnackBar(SnackBar snackBar) {
    if (!mounted) return;
    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(snackBar);
    } catch (_) {}
  }

  /// Initialise la géolocalisation en temps réel de l'utilisateur (comme sur hellobarber)
  /// et récupère automatiquement la météo dynamique correspondant à sa position réelle.
  Future<void> _initLiveLocationAndWeather({bool centerOnUser = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (centerOnUser) {
          _showSafeSnackBar(
            const SnackBar(
              content: Text('Veuillez activer le GPS pour vous localiser.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (centerOnUser) {
            _showSafeSnackBar(
              const SnackBar(
                content: Text('Permission de localisation requise pour la position en temps réel.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (centerOnUser) {
          _showSafeSnackBar(
            const SnackBar(
              content: Text('La localisation est désactivée dans les paramètres de votre appareil.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // 1. Tenter la dernière position connue pour une réactivité instantanée
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // 2. Obtenir la position actuelle précise
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final userCoords = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      setState(() {
        _liveUserPosition = userCoords;
      });

      // Si l'utilisateur clique sur le bouton de position, ou si aucun voyage n'a encore fixé le centre
      if (centerOnUser || (_currentTrip == null && _currentCenter == null)) {
        setState(() {
          _currentCenter = userCoords;
        });
        _animatedMapController.animateTo(dest: userCoords, zoom: 15.5);
      }

      // 3. Écouter les mises à jour en continu en temps réel (comme hellobarber)
      _subscribeUserPositionUpdates();

      // 4. Charger la météo dynamique en direct selon la position GPS exacte
      await _updateWeatherForPosition(
        userCoords.latitude,
        userCoords.longitude,
        autoUpdateCity: _currentTrip == null || _activeCityName.isEmpty,
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation GPS : $e');
    }
  }

  void _subscribeUserPositionUpdates() {
    _userPositionSub?.cancel();
    _userPositionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 15,
      ),
    ).listen(
      (Position p) {
        if (!mounted) return;
        setState(() {
          _liveUserPosition = LatLng(p.latitude, p.longitude);
        });
      },
      onError: (_) {},
    );
  }

  Future<void> _updateWeatherForPosition(
    double lat,
    double lng, {
    bool autoUpdateCity = false,
  }) async {
    final weatherList = await LiveWeatherService.instance.fetchWeather(lat, lng);
    if (!mounted) return;
    setState(() {
      _dynamicWeather = weatherList;
      _showWeatherCard = true;
    });

    if (autoUpdateCity) {
      final city = await LiveWeatherService.instance.reverseGeocode(lat, lng);
      if (city != null && city.isNotEmpty && mounted) {
        setState(() {
          _activeCityName = city;
        });
      }
    }
  }

  Future<void> _bootstrapLiveWeather() async {
    final trip = _currentTrip;
    if (trip != null) {
      final pois = trip.poisForDay(1);
      final lat = pois.isNotEmpty ? pois.first.lat : (_liveUserPosition?.latitude ?? 48.8566);
      final lng = pois.isNotEmpty ? pois.first.lng : (_liveUserPosition?.longitude ?? 2.3522);
      final weather = await LiveWeatherService.instance.fetchWeather(lat, lng);
      if (mounted) {
        setState(() => _dynamicWeather = weather);
      }
    } else if (_liveUserPosition != null) {
      await _updateWeatherForPosition(
        _liveUserPosition!.latitude,
        _liveUserPosition!.longitude,
        autoUpdateCity: true,
      );
    }
  }

  @override
  void dispose() {
    _ambianceRefreshTimer?.cancel();
    _userPositionSub?.cancel();
    _animatedMapController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await LiveWeatherService.instance.searchCities(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _selectCity(CityLocation city) async {
    final target = LatLng(city.lat, city.lng);
    setState(() {
      _currentCenter = target;
      _activeCityName = city.name;
      _searchResults = [];
      _isSearching = false;
      _forceDayMap = false; // Réinitialise pour appliquer l'ambiance astronomique réelle du lieu recherché
      _searchCtrl.text = city.displayName;
    });

    // Move map to city coordinates
    _animatedMapController.animateTo(dest: target, zoom: 13.5);

    // Fetch dynamic live weather
    final weatherList = await LiveWeatherService.instance.fetchWeather(city.lat, city.lng);
    if (mounted) {
      setState(() {
        _dynamicWeather = weatherList;
        _showWeatherCard = true;
      });
      _showSafeSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text('Météo actualisée pour ${city.name}'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTrip != null) {
      return _buildScreen(_currentTrip!);
    }

    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Si aucun tripId n'est fourni, charger dynamiquement le dernier voyage créé de l'utilisateur connecté
    if (widget.tripId.isEmpty) {
      if (user != null) {
        final userTripsAsync = ref.watch(tripsProvider(user.userId));
        return userTripsAsync.when(
          data: (trips) {
            if (trips.isNotEmpty) {
              _currentTrip ??= trips.first;
              if (_activeCityName.isEmpty) _activeCityName = trips.first.destination;
              return _buildScreen(trips.first);
            }
            return _buildScreen(_createDemoTrip());
          },
          loading: () => _buildLoadingScreen(),
          error: (_, __) => _buildScreen(_createDemoTrip()),
        );
      }
      return _buildScreen(_createDemoTrip());
    }

    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));
    return tripAsync.when(
      data: (trip) {
        _currentTrip = trip;
        if (_activeCityName.isEmpty) _activeCityName = trip.destination;
        return _buildScreen(trip);
      },
      loading: () => _buildLoadingScreen(),
      error: (e, _) => _buildErrorScreen(e),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: VoyagoColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: VoyagoColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: VoyagoColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chargement de l\'itinéraire...',
              style: TextStyle(
                color: VoyagoColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object e) {
    return Scaffold(
      backgroundColor: VoyagoColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🧭', style: TextStyle(fontSize: 48)),
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
                style: const TextStyle(
                  color: VoyagoColors.muted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(tripDetailProvider(widget.tripId)),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() => _currentTrip = _createDemoTrip());
                },
                child: const Text('Explorer la carte en mode démo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(Trip trip) {
    final dayPois = trip.poisForDay(_selectedDay);
    final center = _currentCenter ??
        (dayPois.isNotEmpty
            ? LatLng(dayPois.first.lat, dayPois.first.lng)
            : (_liveUserPosition ?? const LatLng(48.8566, 2.3522)));

    // Dynamic weather if city was searched, else trip's weather
    DayWeather? activeWeather;
    if (_dynamicWeather != null && _dynamicWeather!.isNotEmpty) {
      activeWeather = _dynamicWeather![
          (_selectedDay - 1).clamp(0, _dynamicWeather!.length - 1)];
    } else if (trip.weather.isNotEmpty) {
      activeWeather = trip.weather[
          (_selectedDay - 1).clamp(0, trip.weather.length - 1)];
    }

    // Résolution 100% automatique Jour / Nuit / Heure Dorée / Crépuscule (comme hellobarber)
    final ambiance = MapAmbiance.resolve(
      center: center,
      weatherCode: activeWeather?.weatherCode,
    );

    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: VoyagoColors.background,
      drawer: TravelerDrawer(
        currentTripId: trip.id,
        onTripSelected: (newTrip) {
          setState(() {
            _currentTrip = newTrip;
            _activeCityName = newTrip.destination;
            _selectedDay = 1;
            _activePoiIndex = null;
            _dynamicWeather = null;
            _searchCtrl.clear();
          });
          final pois = newTrip.poisForDay(1);
          if (pois.isNotEmpty) {
            final target = LatLng(pois.first.lat, pois.first.lng);
            setState(() => _currentCenter = target);
            _animatedMapController.animateTo(dest: target, zoom: 13.5);
          }
        },
      ),
      body: Stack(
        children: [
          // === 1. FULL-SCREEN LEAFLET MAP (DYNAMIQUE JOUR / NUIT 100% GRATUIT) ===
          Positioned.fill(
            child: FlutterMap(
              mapController: _animatedMapController.mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.5,
                maxZoom: 18,
                minZoom: 3,
                onTap: (_, __) {
                  setState(() {
                    _activePoiIndex = null;
                    _searchResults = [];
                    _isSearching = false;
                  });
                  _searchFocus.unfocus();
                },
              ),
              children: [
                // Tuiles OpenStreetMap 100% gratuites sans API Key ni filigrane (haute définition, rues, édifices)
                TileLayer(
                  key: ValueKey('${ambiance.phase}_${ambiance.tileUrlTemplate}_$_forceDayMap'),
                  urlTemplate: ambiance.tileUrlTemplate,
                  userAgentPackageName: 'com.voyago.app',
                  maxNativeZoom: 19,
                  panBuffer: 1,
                  tileBuilder: (_forceDayMap || ambiance.tileColorFilter == null)
                      ? null
                      : (context, tileWidget, tile) => ColorFiltered(
                          colorFilter: ambiance.tileColorFilter!,
                          child: tileWidget,
                        ),
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(ambiance.attribution),
                  ],
                ),

                // Route polyline connecting the day's POIs
                if (dayPois.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: dayPois
                            .map((p) => LatLng(p.lat, p.lng))
                            .toList(),
                        strokeWidth: 3.5,
                        color: ambiance.isNight
                            ? VoyagoColors.primary.withValues(alpha: 0.9)
                            : VoyagoColors.primary,
                        pattern: const StrokePattern.dotted(),
                      ),
                    ],
                  ),

                // POI pins on map
                MarkerLayer(
                  markers: dayPois.asMap().entries.map((entry) {
                    final i = entry.key;
                    final poi = entry.value;
                    return Marker(
                      point: LatLng(poi.lat, poi.lng),
                      width: _activePoiIndex == i ? 180 : 46,
                      height: _activePoiIndex == i ? 80 : 46,
                      child: MapPoiPin(
                        poi: poi,
                        index: i,
                        isActive: _activePoiIndex == i,
                        onTap: () {
                          setState(() {
                            _activePoiIndex =
                                _activePoiIndex == i ? null : i;
                          });
                          _animatedMapController.animateTo(
                            dest: LatLng(poi.lat, poi.lng),
                            zoom: 15,
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),

                // === POSITION GPS EN TEMPS RÉEL DE L'UTILISATEUR ===
                CurrentLocationLayer(
                  alignPositionOnUpdate: AlignOnUpdate.never,
                  alignDirectionOnUpdate: AlignOnUpdate.never,
                  style: LocationMarkerStyle(
                    marker: const DefaultLocationMarker(
                      color: VoyagoColors.primary,
                      child: Icon(Icons.navigation_rounded, color: Colors.white, size: 14),
                    ),
                    markerSize: const Size.square(32),
                    accuracyCircleColor: VoyagoColors.primary.withValues(alpha: 0.12),
                    headingSectorColor: VoyagoColors.primary.withValues(alpha: 0.5),
                    headingSectorRadius: 60,
                  ),
                ),
              ],
            ),
          ),

          // === CALQUE ATMOSPHÉRIQUE D'AMBIANCE (COMME HELLOBARBER, 100% IGNOREPOINTER) ===
          Positioned.fill(
            child: MapAmbianceOverlay(
              ambiance: ambiance,
              weather: activeWeather,
              topInset: MediaQuery.of(context).padding.top,
              forceDay: _forceDayMap,
            ),
          ),

          // === 2. TOP FLOATING SEARCH & MENU BAR ===
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 12,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VoyagoColors.background.withValues(alpha: 0.95),
                    VoyagoColors.background.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // 3-bars hamburger menu button (menu en 3 traits en haut à gauche)
                      _MapButton(
                        icon: Icons.menu,
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      const SizedBox(width: 8),

                      // Floating Search Bar (from HTML template)
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: VoyagoColors.surface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: VoyagoColors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.search,
                                  color: VoyagoColors.muted,
                                  size: 20,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  focusNode: _searchFocus,
                                  onChanged: _onSearchChanged,
                                  onSubmitted: (q) async {
                                    if (_searchResults.isNotEmpty) {
                                      _selectCity(_searchResults.first);
                                    } else if (q.trim().isNotEmpty) {
                                      final list = await LiveWeatherService.instance.searchCities(q);
                                      if (list.isNotEmpty) _selectCity(list.first);
                                    }
                                  },
                                  style: const TextStyle(
                                    color: VoyagoColors.text,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _activeCityName.isNotEmpty
                                        ? 'Rechercher lieu à $_activeCityName...'
                                        : 'Rechercher une ville, lieu...',
                                    hintStyle: TextStyle(
                                      color: VoyagoColors.muted.withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              if (_isSearching)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: VoyagoColors.primary,
                                    ),
                                  ),
                                )
                              else if (_searchCtrl.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _isSearching = false;
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.close, color: VoyagoColors.muted, size: 18),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(
                                    Icons.tune,
                                    color: VoyagoColors.primary.withValues(alpha: 0.8),
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // User profile button / avatar
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: VoyagoColors.surface.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: VoyagoColors.primary.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user?.avatarDisplay ?? '👤',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Search Suggestions Dropdown
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: VoyagoColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VoyagoColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _searchResults.take(4).map((city) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.location_city,
                              color: VoyagoColors.primary,
                              size: 18,
                            ),
                            title: Text(
                              city.displayName,
                              style: const TextStyle(
                                color: VoyagoColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: VoyagoColors.muted,
                              size: 12,
                            ),
                            onTap: () => _selectCity(city),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // === 3. DYNAMIC WEATHER OVERLAY (TRANSPARENT, SANS FOND OPAQUE, MINIFIABLE) ===
          if (activeWeather != null && _showWeatherCard)
            Positioned(
              top: MediaQuery.of(context).padding.top + 68,
              left: 0,
              right: 0,
              child: WeatherOverlay(
                weather: activeWeather,
                dayNumber: _selectedDay,
                ambianceLabel: ambiance.phaseLabel,
                ambianceIcon: ambiance.phaseIcon,
                isMinimized: _isWeatherMinimized,
                onToggleMinimize: () {
                  setState(() => _isWeatherMinimized = !_isWeatherMinimized);
                },
                aiTip: getWeatherAiTip(
                  activeWeather,
                  ref.watch(currentUserProvider)?.thermalSensitivity,
                ),
              ),
            ),

          // === 4. MAP CONTROLS (Right Side) ===
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.46 + 12,
            child: Column(
              children: [
                // Bascule Style Carte : Plein Jour forcé ou Ambiance Réelle Dynamique (comme hellobarber)
                _MapButton(
                  icon: _forceDayMap ? Icons.wb_sunny_rounded : ambiance.phaseIcon,
                  onTap: () {
                    setState(() => _forceDayMap = !_forceDayMap);
                    _showSafeSnackBar(
                      SnackBar(
                        content: Text(
                          _forceDayMap
                              ? '☀️ Mode Plein Jour forcé'
                              : '✨ Ambiance solaire dynamique rétablie (${ambiance.phaseLabel})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.my_location,
                  onTap: () async {
                    setState(() => _forceDayMap = false); // Rétablit l'ambiance réelle de la position utilisateur
                    if (_liveUserPosition != null) {
                      _animatedMapController.animateTo(
                        dest: _liveUserPosition!,
                        zoom: 16.0,
                      );
                      _updateWeatherForPosition(
                        _liveUserPosition!.latitude,
                        _liveUserPosition!.longitude,
                      );
                      _showSafeSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.gps_fixed, color: VoyagoColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text('Centré sur votre position GPS en temps réel'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      // Demande et acquisition en direct de la position GPS
                      await _initLiveLocationAndWeather(centerOnUser: true);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: VoyagoColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VoyagoColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _MapButton(
                        icon: Icons.add,
                        onTap: () {
                          final zoom = _animatedMapController.mapController.camera.zoom;
                          _animatedMapController.animateTo(
                            dest: _animatedMapController.mapController.camera.center,
                            zoom: (zoom + 1).clamp(3, 18).toDouble(),
                          );
                        },
                        noBg: true,
                      ),
                      Container(
                        width: 28,
                        height: 1,
                        color: VoyagoColors.cardBorder,
                      ),
                      _MapButton(
                        icon: Icons.remove,
                        onTap: () {
                          final zoom = _animatedMapController.mapController.camera.zoom;
                          _animatedMapController.animateTo(
                            dest: _animatedMapController.mapController.camera.center,
                            zoom: (zoom - 1).clamp(3, 18).toDouble(),
                          );
                        },
                        noBg: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // === 5. ITINERARY BOTTOM SHEET ===
          ItineraryBottomSheet(
            pois: dayPois,
            selectedDay: _selectedDay,
            totalDays: trip.durationDays,
            destination: _activeCityName.isNotEmpty ? _activeCityName : trip.destination,
            onDayChanged: (day) {
              setState(() {
                _selectedDay = day;
                _activePoiIndex = null;
              });
              final newPois = trip.poisForDay(day);
              if (newPois.isNotEmpty) {
                final target = LatLng(newPois.first.lat, newPois.first.lng);
                setState(() => _currentCenter = target);
                _animatedMapController.animateTo(dest: target, zoom: 13.5);
              }
            },
            onPoiTap: (poi) {
              final idx = dayPois.indexOf(poi);
              setState(() => _activePoiIndex = idx >= 0 ? idx : null);
              _animatedMapController.animateTo(dest: LatLng(poi.lat, poi.lng), zoom: 15);
            },
          ),
        ],
      ),
    );
  }

  Trip _createDemoTrip() {
    return Trip(
      id: 'demo-paris',
      userId: 'guest',
      destination: 'Paris',
      durationDays: 3,
      pace: 'modéré',
      budget: 'moyen',
      transports: ['marche', 'métro'],
      interests: ['gastronomie', 'culture', 'art'],
      pois: [
        const POI(
          name: 'Café de Flore',
          description: 'Café littéraire historique de Saint-Germain-des-Prés.',
          category: 'gastronomie',
          imageQuery: 'Cafe de Flore',
          lat: 48.8541,
          lng: 2.3328,
          day: 1,
          order: 1,
          durationMinutes: 45,
          rating: 4.8,
          reviewsCount: 2400,
          insiderTip: 'Dégustez leur fameux chocolat chaud à l\'ancienne.',
          imageUrl:
              'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?w=600&auto=format&fit=crop&q=80',
        ),
        const POI(
          name: 'Musée du Louvre',
          description: 'Le plus grand musée d\'art et d\'antiquités du monde.',
          category: 'culture',
          imageQuery: 'Louvre Museum',
          lat: 48.8606,
          lng: 2.3376,
          day: 1,
          order: 2,
          durationMinutes: 120,
          rating: 4.9,
          reviewsCount: 12400,
          insiderTip: 'Entrez par le Carrousel du Louvre pour éviter la file principale.',
          imageUrl:
              'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=600&auto=format&fit=crop&q=80',
        ),
        const POI(
          name: 'Jardin des Tuileries',
          description: 'Flânerie royale au cœur de la capitale.',
          category: 'nature',
          imageQuery: 'Tuileries Garden',
          lat: 48.8634,
          lng: 2.3275,
          day: 1,
          order: 3,
          durationMinutes: 60,
          rating: 4.7,
          reviewsCount: 5600,
          insiderTip: 'Profitez des chaises vertes au bord du grand bassin octogonal.',
          imageUrl:
              'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600&auto=format&fit=crop&q=80',
        ),
      ],
      weather: [
        const DayWeather(
          date: 'Jour 1',
          icon: '⛅',
          summary: 'Partiellement nuageux',
          weatherCode: 1,
          tempMax: 18.0,
          tempMin: 12.0,
        ),
        const DayWeather(
          date: 'Jour 2',
          icon: '☀️',
          summary: 'Ensoleillé',
          weatherCode: 0,
          tempMax: 21.0,
          tempMin: 14.0,
        ),
        const DayWeather(
          date: 'Jour 3',
          icon: '🌦️',
          summary: 'Averses éparses',
          weatherCode: 61,
          tempMax: 17.0,
          tempMin: 13.0,
        ),
      ],
      likes: 42,
      isPublic: false,
      createdAt: DateTime.now(),
    );
  }
}

/// Circular floating map button
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool noBg;

  const _MapButton({
    required this.icon,
    required this.onTap,
    this.noBg = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: noBg
            ? null
            : BoxDecoration(
                color: VoyagoColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VoyagoColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
        alignment: Alignment.center,
        child: Icon(icon, color: VoyagoColors.text, size: 20),
      ),
    );
  }
}
