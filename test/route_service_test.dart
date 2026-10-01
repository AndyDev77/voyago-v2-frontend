import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:voyago/services/route_service.dart';

void main() {
  group('TravelMode.forTrip', () {
    test('marche privilégiée pour un court trajet', () {
      expect(TravelMode.forTrip(['marche', 'transport'], 600), TravelMode.walk);
    });

    test('transport en commun au-delà de la distance de marche', () {
      expect(TravelMode.forTrip(['marche', 'transport'], 3500), TravelMode.transit);
    });

    test('marche seule : toujours à pied', () {
      expect(TravelMode.forTrip(['marche'], 5000), TravelMode.walk);
    });

    test('voiture prioritaire sur transport', () {
      expect(TravelMode.forTrip(['transport', 'voiture'], 4000), TravelMode.car);
    });

    test('alias métro / vélo et liste vide', () {
      expect(TravelMode.forTrip(['métro'], 4000), TravelMode.transit);
      expect(TravelMode.forTrip(['velo'], 4000), TravelMode.bike);
      expect(TravelMode.forTrip([], 4000), TravelMode.walk);
    });
  });

  group('RouteService.estimate', () {
    const louvre = LatLng(48.8606, 2.3376);
    const notreDame = LatLng(48.8530, 2.3499);

    test('les durées respectent la vitesse de chaque mode', () {
      final walk = RouteService.estimate(louvre, notreDame, TravelMode.walk);
      final bike = RouteService.estimate(louvre, notreDame, TravelMode.bike);
      final transit = RouteService.estimate(louvre, notreDame, TravelMode.transit);

      expect(walk.isEstimate, isTrue);
      expect(walk.mode, TravelMode.walk);
      // ~1,2 km à vol d'oiseau : ~20-25 min à pied, bien moins à vélo
      expect(walk.durationMinutes, inInclusiveRange(18, 28));
      expect(bike.durationMinutes, lessThan(walk.durationMinutes));
      // Le transport inclut l'attente : jamais instantané
      expect(transit.durationMinutes, greaterThanOrEqualTo(5));
    });
  });
}
