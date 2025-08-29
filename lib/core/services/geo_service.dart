import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for geographical calculations
class GeoService {
  /// Earth's radius in kilometers
  static const double _earthRadiusKm = 6371.0;

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    // Convert latitude and longitude from degrees to radians
    final double lat1Rad = _degreesToRadians(lat1);
    final double lng1Rad = _degreesToRadians(lng1);
    final double lat2Rad = _degreesToRadians(lat2);
    final double lng2Rad = _degreesToRadians(lng2);

    // Haversine formula
    final double deltaLat = lat2Rad - lat1Rad;
    final double deltaLng = lng2Rad - lng1Rad;

    final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Distance in kilometers
    final double distance = _earthRadiusKm * c;

    debugPrint('Distance calculated: ${distance.toStringAsFixed(2)} km between ($lat1, $lng1) and ($lat2, $lng2)');
    
    return distance;
  }

  /// Calculate distance with null safety
  /// Returns null if any coordinate is missing
  static double? calculateDistanceSafe({
    required double? lat1,
    required double? lng1,
    required double? lat2,
    required double? lng2,
  }) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return null;
    }

    return calculateDistance(
      lat1: lat1,
      lng1: lng1,
      lat2: lat2,
      lng2: lng2,
    );
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * (180.0 / pi);
  }

  /// Check if coordinates are valid
  static bool areCoordinatesValid(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    
    // Check latitude bounds (-90 to 90)
    if (latitude < -90.0 || latitude > 90.0) return false;
    
    // Check longitude bounds (-180 to 180)
    if (longitude < -180.0 || longitude > 180.0) return false;
    
    return true;
  }

  /// Get distance category for UI display
  static String getDistanceCategory(double distanceKm) {
    if (distanceKm < 5) return 'Very Close';
    if (distanceKm < 15) return 'Nearby';
    if (distanceKm < 30) return 'Close';
    if (distanceKm < 50) return 'Moderate Distance';
    if (distanceKm < 100) return 'Far';
    return 'Very Far';
  }

  /// Get distance display string
  static String getDistanceDisplay(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km away';
    } else {
      return '${distanceKm.round()} km away';
    }
  }

  /// Calculate bearing between two points (direction)
  /// Returns bearing in degrees (0-360)
  static double calculateBearing({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    final double lat1Rad = _degreesToRadians(lat1);
    final double lat2Rad = _degreesToRadians(lat2);
    final double deltaLng = _degreesToRadians(lng2 - lng1);

    final double y = sin(deltaLng) * cos(lat2Rad);
    final double x = cos(lat1Rad) * sin(lat2Rad) - 
        sin(lat1Rad) * cos(lat2Rad) * cos(deltaLng);

    double bearing = _radiansToDegrees(atan2(y, x));
    
    // Normalize to 0-360 degrees
    bearing = (bearing + 360) % 360;
    
    return bearing;
  }

  /// Get compass direction from bearing
  static String getCompassDirection(double bearing) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW'
    ];
    
    final int index = ((bearing + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  /// Check if location is within radius
  static bool isWithinRadius({
    required double centerLat,
    required double centerLng,
    required double targetLat,
    required double targetLng,
    required double radiusKm,
  }) {
    final double distance = calculateDistance(
      lat1: centerLat,
      lng1: centerLng,
      lat2: targetLat,
      lng2: targetLng,
    );
    
    return distance <= radiusKm;
  }

  /// Get approximate coordinates for a city/location name
  /// This is a simple lookup - in production, use proper geocoding
  static Map<String, double>? getApproximateCoordinates(String location) {
    final locationLower = location.toLowerCase();
    
    // Simple lookup for common cities (expand as needed)
    final Map<String, Map<String, double>> cityCoordinates = {
      'new york': {'lat': 40.7128, 'lng': -74.0060},
      'los angeles': {'lat': 34.0522, 'lng': -118.2437},
      'chicago': {'lat': 41.8781, 'lng': -87.6298},
      'houston': {'lat': 29.7604, 'lng': -95.3698},
      'phoenix': {'lat': 33.4484, 'lng': -112.0740},
      'philadelphia': {'lat': 39.9526, 'lng': -75.1652},
      'san antonio': {'lat': 29.4241, 'lng': -98.4936},
      'san diego': {'lat': 32.7157, 'lng': -117.1611},
      'dallas': {'lat': 32.7767, 'lng': -96.7970},
      'san jose': {'lat': 37.3382, 'lng': -121.8863},
      'austin': {'lat': 30.2672, 'lng': -97.7431},
      'jacksonville': {'lat': 30.3322, 'lng': -81.6557},
      'san francisco': {'lat': 37.7749, 'lng': -122.4194},
      'columbus': {'lat': 39.9612, 'lng': -82.9988},
      'charlotte': {'lat': 35.2271, 'lng': -80.8431},
      'fort worth': {'lat': 32.7555, 'lng': -97.3308},
      'indianapolis': {'lat': 39.7684, 'lng': -86.1581},
      'seattle': {'lat': 47.6062, 'lng': -122.3321},
      'denver': {'lat': 39.7392, 'lng': -104.9903},
      'boston': {'lat': 42.3601, 'lng': -71.0589},
      'el paso': {'lat': 31.7619, 'lng': -106.4850},
      'nashville': {'lat': 36.1627, 'lng': -86.7816},
      'detroit': {'lat': 42.3314, 'lng': -83.0458},
      'oklahoma city': {'lat': 35.4676, 'lng': -97.5164},
      'portland': {'lat': 45.5152, 'lng': -122.6784},
      'las vegas': {'lat': 36.1699, 'lng': -115.1398},
      'memphis': {'lat': 35.1495, 'lng': -90.0490},
      'louisville': {'lat': 38.2527, 'lng': -85.7585},
      'baltimore': {'lat': 39.2904, 'lng': -76.6122},
      'milwaukee': {'lat': 43.0389, 'lng': -87.9065},
      'albuquerque': {'lat': 35.0844, 'lng': -106.6504},
      'tucson': {'lat': 32.2226, 'lng': -110.9747},
      'fresno': {'lat': 36.7378, 'lng': -119.7871},
      'mesa': {'lat': 33.4152, 'lng': -111.8315},
      'sacramento': {'lat': 38.5816, 'lng': -121.4944},
      'atlanta': {'lat': 33.7490, 'lng': -84.3880},
      'kansas city': {'lat': 39.0997, 'lng': -94.5786},
      'colorado springs': {'lat': 38.8339, 'lng': -104.8214},
      'omaha': {'lat': 41.2565, 'lng': -95.9345},
      'raleigh': {'lat': 35.7796, 'lng': -78.6382},
      'miami': {'lat': 25.7617, 'lng': -80.1918},
      'long beach': {'lat': 33.7701, 'lng': -118.1937},
      'virginia beach': {'lat': 36.8529, 'lng': -76.1224},
      'minneapolis': {'lat': 44.9778, 'lng': -93.2650},
      'tampa': {'lat': 27.9506, 'lng': -82.4572},
      'oakland': {'lat': 37.8044, 'lng': -122.2712},
      'tulsa': {'lat': 36.1540, 'lng': -95.9928},
      'arlington': {'lat': 32.7357, 'lng': -97.1081},
      'wichita': {'lat': 37.6872, 'lng': -97.3301},
    };
    
    // Try exact match first
    if (cityCoordinates.containsKey(locationLower)) {
      return cityCoordinates[locationLower];
    }
    
    // Try partial matches
    for (final city in cityCoordinates.keys) {
      if (locationLower.contains(city) || city.contains(locationLower)) {
        return cityCoordinates[city];
      }
    }
    
    return null;
  }
}

