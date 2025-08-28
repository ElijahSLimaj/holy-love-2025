import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for handling location-related operations
class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  // Mapbox Search API - You'll need to add your Mapbox token
  String? _mapboxToken;
  bool _initialized = false;

  /// Initialize the location service with Mapbox token
  Future<void> initialize({required String mapboxToken}) async {
    if (_initialized) return;
    
    try {
      _mapboxToken = mapboxToken;
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize LocationService: $e');
    }
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final permission = await Permission.location.status;
    return permission == PermissionStatus.granted;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission == PermissionStatus.granted;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current position with error handling
  Future<LocationResult> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error('Location services are disabled. Please enable location services in your device settings.');
      }

      // Handle location permission with proper flow
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission - this will show the system dialog
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          return LocationResult.error('Location permission denied. Please grant location permission to use this feature.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error('Location permissions are permanently denied. Please enable location access in your device settings.');
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final locationData = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          city: placemark.locality ?? '',
          state: placemark.administrativeArea ?? '',
          country: placemark.country ?? '',
          fullAddress: _formatAddress(placemark),
        );
        
        return LocationResult.success(locationData);
      } else {
        return LocationResult.error('Unable to determine your location address.');
      }
    } catch (e) {
      debugPrint('Error getting current position: $e');
      if (e is LocationServiceDisabledException) {
        return LocationResult.error('Location services are disabled. Please enable location services in your device settings.');
      } else if (e is PermissionDeniedException) {
        return LocationResult.error('Location permission was denied. Please grant location permission in your device settings.');
      } else if (e.toString().contains('timeout')) {
        return LocationResult.error('Location request timed out. Please try again or check your GPS signal.');
      } else {
        return LocationResult.error('Failed to get your current location. Please ensure location services are enabled and try again.');
      }
    }
  }

  /// Search for places using Mapbox
  Future<List<LocationData>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      if (_mapboxToken == null || _mapboxToken!.isEmpty) {
        debugPrint('Mapbox token not configured, using mock data');
        return _getMockSearchResults(query);
      }
      
      // Use Mapbox Geocoding API directly
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json?access_token=$_mapboxToken&limit=5';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];
        
        return features.map((feature) {
          final coordinates = feature['geometry']['coordinates'] as List<dynamic>;
          final placeName = feature['place_name'] as String;
          final parts = placeName.split(', ');
          
          return LocationData(
            latitude: coordinates[1].toDouble(),
            longitude: coordinates[0].toDouble(),
            city: parts.isNotEmpty ? parts[0] : '',
            state: parts.length > 1 ? parts[1] : '',
            country: parts.length > 2 ? parts.last : '',
            fullAddress: placeName,
            placeId: feature['id'] as String?,
          );
        }).toList();
      }
      
      // Fallback to mock data if no results
      return _getMockSearchResults(query);
    } catch (e) {
      debugPrint('Error searching places: $e');
      // Fallback to mock data on error
      return _getMockSearchResults(query);
    }
  }

  /// Mock search results for testing
  List<LocationData> _getMockSearchResults(String query) {
    final mockResults = <LocationData>[];
    
    if (query.toLowerCase().contains('new york')) {
      mockResults.add(LocationData(
        latitude: 40.7128,
        longitude: -74.0060,
        city: 'New York',
        state: 'NY',
        country: 'United States',
        fullAddress: 'New York, NY, United States',
      ));
    }
    
    if (query.toLowerCase().contains('los angeles')) {
      mockResults.add(LocationData(
        latitude: 34.0522,
        longitude: -118.2437,
        city: 'Los Angeles',
        state: 'CA',
        country: 'United States',
        fullAddress: 'Los Angeles, CA, United States',
      ));
    }
    
    if (query.toLowerCase().contains('chicago')) {
      mockResults.add(LocationData(
        latitude: 41.8781,
        longitude: -87.6298,
        city: 'Chicago',
        state: 'IL',
        country: 'United States',
        fullAddress: 'Chicago, IL, United States',
      ));
    }
    
    return mockResults;
  }

  /// Format placemark into readable address
  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    
    if (placemark.locality?.isNotEmpty == true) {
      parts.add(placemark.locality!);
    }
    
    if (placemark.administrativeArea?.isNotEmpty == true) {
      parts.add(placemark.administrativeArea!);
    }
    
    if (placemark.country?.isNotEmpty == true) {
      parts.add(placemark.country!);
    }
    
    return parts.join(', ');
  }
}

/// Result wrapper for location operations
class LocationResult {
  final bool success;
  final LocationData? data;
  final String? error;

  LocationResult.success(this.data) : success = true, error = null;
  LocationResult.error(this.error) : success = false, data = null;
}

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;
  final String fullAddress;
  final String? placeId;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.country,
    required this.fullAddress,
    this.placeId,
  });

  /// Get formatted city, state for display
  String get displayLocation {
    final parts = <String>[];
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    return parts.join(', ');
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'fullAddress': fullAddress,
      'placeId': placeId,
    };
  }

  @override
  String toString() => fullAddress;
}