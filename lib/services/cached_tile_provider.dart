import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

/// Fournisseur de tuiles avec cache disque persistant.
///
/// Les tuiles déjà vues s'affichent instantanément (même hors ligne) au lieu
/// d'être retéléchargées depuis OpenStreetMap à chaque ouverture de la carte.
/// Un cache dédié évite d'évincer les photos des lieux du cache d'images global.
class CachedTileProvider extends TileProvider {
  CachedTileProvider({super.headers});

  static final CacheManager _tileCache = CacheManager(
    Config(
      'voyagoMapTiles',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 4000,
    ),
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      headers: headers,
      cacheManager: _tileCache,
    );
  }
}
