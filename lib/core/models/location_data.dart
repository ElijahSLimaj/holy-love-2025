import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Enhanced location data model for Google Places integration
class LocationData extends Equatable {
  final String? placeId; // Google Places ID for future lookups
  final String displayName; // e.g., "San Francisco, CA, USA"
  final String city;
  final String? state;
  final String country;
  final GeoPoint coordinates;
  final String? postalCode;
  final String? administrativeArea;
  final String? countryCode; // ISO country code (US, CA, etc.)

  const LocationData({
    this.placeId,
    required this.displayName,
    required this.city,
    this.state,
    required this.country,
    required this.coordinates,
    this.postalCode,
    this.administrativeArea,
    this.countryCode,
  });

  /// Create LocationData from Google Places API response
  factory LocationData.fromGooglePlace(Map<String, dynamic> placeData) {
    final components = placeData['address_components'] as List<dynamic>? ?? [];
    final geometry = placeData['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;

    String city = '';
    String? state;
    String country = '';
    String? postalCode;
    String? administrativeArea;
    String? countryCode;

    for (final component in components) {
      final types = List<String>.from(component['types'] ?? []);
      final longName = component['long_name'] as String? ?? '';
      final shortName = component['short_name'] as String? ?? '';

      if (types.contains('locality')) {
        city = longName;
      } else if (types.contains('administrative_area_level_1')) {
        state = shortName; // "CA" instead of "California"
        administrativeArea = longName;
      } else if (types.contains('country')) {
        country = longName;
        countryCode = shortName;
      } else if (types.contains('postal_code')) {
        postalCode = longName;
      }
    }

    // Fallback for city if locality not found
    if (city.isEmpty) {
      for (final component in components) {
        final types = List<String>.from(component['types'] ?? []);
        if (types.contains('sublocality_level_1') ||
            types.contains('neighborhood')) {
          city = component['long_name'] as String? ?? '';
          break;
        }
      }
    }

    // Coordinates
    final lat = (location?['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (location?['lng'] as num?)?.toDouble() ?? 0.0;
    final coordinates = GeoPoint(lat, lng);

    // Display name
    String displayName = city;
    if (state != null && state!.isNotEmpty) displayName += ', $state';
    if (country.isNotEmpty && country != 'United States')
      displayName += ', $country';

    return LocationData(
      placeId: placeData['place_id'] as String?,
      displayName: displayName,
      city: city,
      state: state,
      country: country,
      coordinates: coordinates,
      postalCode: postalCode,
      administrativeArea: administrativeArea,
      countryCode: countryCode,
    );
  }

  /// Create manually from a string like "City, ST, Country"
  factory LocationData.fromUserInput(String locationString) {
    final parts = locationString.split(',').map((e) => e.trim()).toList();
    final city = parts.isNotEmpty ? parts[0] : '';
    final state = parts.length > 1 ? parts[1] : null;
    final country = parts.length > 2 ? parts[2] : 'United States';
    const coordinates = GeoPoint(0.0, 0.0);
    return LocationData(
      displayName: locationString,
      city: city,
      state: state,
      country: country,
      coordinates: coordinates,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'placeId': placeId,
      'displayName': displayName,
      'city': city,
      'state': state,
      'country': country,
      'coordinates': coordinates,
      'postalCode': postalCode,
      'administrativeArea': administrativeArea,
      'countryCode': countryCode,
    };
  }

  factory LocationData.fromFirestore(Map<String, dynamic> data) {
    final coordinates =
        data['coordinates'] as GeoPoint? ?? const GeoPoint(0.0, 0.0);
    return LocationData(
      placeId: data['placeId'] as String?,
      displayName: data['displayName'] as String? ?? '',
      city: data['city'] as String? ?? '',
      state: data['state'] as String?,
      country: data['country'] as String? ?? '',
      coordinates: coordinates,
      postalCode: data['postalCode'] as String?,
      administrativeArea: data['administrativeArea'] as String?,
      countryCode: data['countryCode'] as String?,
    );
  }

  String get legacyLocationString {
    String result = city;
    if (state != null && state!.isNotEmpty) result += ', $state';
    return result;
  }

  bool get hasValidCoordinates =>
      coordinates.latitude != 0.0 || coordinates.longitude != 0.0;

  LocationData copyWith({
    String? placeId,
    String? displayName,
    String? city,
    String? state,
    String? country,
    GeoPoint? coordinates,
    String? postalCode,
    String? administrativeArea,
    String? countryCode,
  }) {
    return LocationData(
      placeId: placeId ?? this.placeId,
      displayName: displayName ?? this.displayName,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      coordinates: coordinates ?? this.coordinates,
      postalCode: postalCode ?? this.postalCode,
      administrativeArea: administrativeArea ?? this.administrativeArea,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  @override
  List<Object?> get props => [
        placeId,
        displayName,
        city,
        state,
        country,
        coordinates,
        postalCode,
        administrativeArea,
        countryCode,
      ];

  @override
  String toString() => displayName;
}

/// Simple place suggestion for autocomplete
class PlaceSuggestion extends Equatable {
  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText,
  });

  factory PlaceSuggestion.fromGooglePrediction(
      Map<String, dynamic> prediction) {
    final structuredFormatting =
        prediction['structured_formatting'] as Map<String, dynamic>?;
    return PlaceSuggestion(
      placeId: prediction['place_id'] as String,
      description: prediction['description'] as String,
      mainText: structuredFormatting?['main_text'] as String? ??
          prediction['description'] as String,
      secondaryText: structuredFormatting?['secondary_text'] as String?,
    );
  }

  @override
  List<Object?> get props => [placeId, description, mainText, secondaryText];
}
