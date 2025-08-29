/// Represents the compatibility score between two users
class MatchScore {
  final int faithCompatibility;    // 0-40 points
  final int locationProximity;     // 0-25 points
  final int sharedInterests;       // 0-20 points
  final int ageCompatibility;      // 0-15 points
  final int totalScore;           // 0-100 points
  final List<String> reasons;     // Human-readable reasons

  const MatchScore({
    required this.faithCompatibility,
    required this.locationProximity,
    required this.sharedInterests,
    required this.ageCompatibility,
    required this.totalScore,
    required this.reasons,
  });

  /// Get compatibility level as a string
  String get compatibilityLevel {
    if (totalScore >= 80) return 'Excellent Match';
    if (totalScore >= 60) return 'Great Match';
    if (totalScore >= 40) return 'Good Match';
    if (totalScore >= 20) return 'Potential Match';
    return 'Low Compatibility';
  }

  /// Get compatibility percentage
  double get compatibilityPercentage => totalScore / 100.0;

  /// Get primary reason for match
  String get primaryReason => reasons.isNotEmpty ? reasons.first : 'Potential compatibility';

  @override
  String toString() {
    return 'MatchScore(total: $totalScore, faith: $faithCompatibility, location: $locationProximity, interests: $sharedInterests, age: $ageCompatibility)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchScore && other.totalScore == totalScore;
  }

  @override
  int get hashCode => totalScore.hashCode;
}
