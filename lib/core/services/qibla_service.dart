import 'dart:math';
import 'dart:developer' as developer;

class QiblaService {
  // Kaaba coordinates
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  /// Calculates the bearing direction in degrees towards the Kaaba (Qibla)
  /// from the user's current latitude and longitude.
  ///
  /// FIX: Made static — QiblaService holds no state; pure math function.
  /// No need to instantiate QiblaService(); call directly:
  ///   QiblaService.calculateQiblaDirection(lat, lng)
  static double calculateQiblaDirection(
      double userLatitude, double userLongitude) {
    developer.log(
      'Calculating Qibla bearing for lat: $userLatitude, lng: $userLongitude',
      name: 'QiblaService',
    );

    final latRad = userLatitude * pi / 180.0;
    final lngRad = userLongitude * pi / 180.0;
    final kaabaLatRad = kaabaLatitude * pi / 180.0;
    final kaabaLngRad = kaabaLongitude * pi / 180.0;

    final diffLongitude = kaabaLngRad - lngRad;

    final y = sin(diffLongitude);
    final x =
        cos(latRad) * tan(kaabaLatRad) - sin(latRad) * cos(diffLongitude);

    final qiblaRad = atan2(y, x);
    final qiblaDeg = qiblaRad * 180.0 / pi;

    return (qiblaDeg + 360.0) % 360.0;
  }
}
