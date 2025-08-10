import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';

class LocationService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  // TODO: Add your Google Places API key to environment variables or Firebase config
  static const String _apiKey = 'API KEY';

  // Cache for recent searches to reduce API calls
  static final Map<String, List<PlaceSuggestion>> _searchCache = {};
  static const Duration _cacheExpiration = Duration(minutes: 10);
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Search for places based on user input with autocomplete
  /// Returns list of place suggestions for autocomplete dropdown
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.isEmpty || query.length < 2) return [];

    // Check cache first
    if (_isQueryCached(query)) {
      return _searchCache[query]!;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/place/autocomplete/json?input=${Uri.encodeComponent(query)}&types=(cities)&key=$_apiKey',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List<dynamic>? ?? [];
      final suggestions = predictions
          .map((prediction) => PlaceSuggestion.fromGooglePrediction(
              prediction as Map<String, dynamic>))
          .toList();

      // Cache the results
      _cacheSearchResults(query, suggestions);

      return suggestions;
    } catch (e) {
      return [];
    }
  }

  /// Get detailed location data for a specific place ID
  /// This is called when user selects a place from autocomplete
  static Future<LocationData?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      final url = Uri.parse(
        '$_baseUrl/place/details/json?place_id=$placeId&fields=place_id,formatted_address,address_components,geometry&key=$_apiKey',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;

      if (result == null) {
        return null;
      }

      return LocationData.fromGooglePlace(result);
    } catch (e) {
      return null;
    }
  }

  /// Get user's current location using GPS
  /// This enhances the existing GPS button functionality
  static Future<LocationData?> getCurrentLocation() async {
    try {
      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          return null;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      // Reverse geocode to get place name
      final locationData =
          await reverseGeocode(position.latitude, position.longitude);

      if (locationData != null) {
        return locationData;
      } else {
        // Return basic location data with coordinates
        return LocationData(
          displayName: 'Current Location',
          city: 'Unknown',
          country: 'Unknown',
          coordinates: GeoPoint(position.latitude, position.longitude),
        );
      }
    } catch (e) {
      return null;
    }
  }

  /// Reverse geocode coordinates to get place information
  static Future<LocationData?> reverseGeocode(
      double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/geocode/json?latlng=$latitude,$longitude&key=$_apiKey',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      if (results.isEmpty) {
        return null;
      }

      // Find the best result (usually the first locality result)
      Map<String, dynamic>? bestResult;
      for (final result in results) {
        final types = List<String>.from(result['types'] ?? []);
        if (types.contains('locality') || types.contains('political')) {
          bestResult = result as Map<String, dynamic>;
          break;
        }
      }

      bestResult ??= results.first as Map<String, dynamic>;

      return LocationData.fromGooglePlace(bestResult);
    } catch (e) {
      return null;
    }
  }

  /// Validate if API key is configured
  static bool get isConfigured {
    return _apiKey != 'YOUR_GOOGLE_PLACES_API_KEY' && _apiKey.isNotEmpty;
  }

  /// Check if location services are available on device
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get location permission status
  static Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Cache management
  static bool _isQueryCached(String query) {
    if (!_searchCache.containsKey(query)) return false;

    final timestamp = _cacheTimestamps[query];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  static void _cacheSearchResults(
      String query, List<PlaceSuggestion> suggestions) {
    _searchCache[query] = suggestions;
    _cacheTimestamps[query] = DateTime.now();

    // Clean old cache entries
    _cleanCache();
  }

  static void _cleanCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) >= _cacheExpiration) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _searchCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear all cached data
  static void clearCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
  }
}

/// Add GeoPoint extension for easier usage
extension GeoPointExtension on GeoPoint {
  /// Calculate distance to another GeoPoint in kilometers
  double distanceTo(GeoPoint other) {
    return Geolocator.distanceBetween(
            latitude, longitude, other.latitude, other.longitude) /
        1000; // Convert meters to kilometers
  }
}
