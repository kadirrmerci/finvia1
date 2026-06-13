import 'dart:math' as math;

class BodyFatService {
  const BodyFatService();

  double calculateAceNavyBodyFat({
    required String gender,
    required double heightCm,
    required double waistCm,
    required double neckCm,
    double? hipCm,
  }) {
    final heightIn = _cmToInches(heightCm);
    final waistIn = _cmToInches(waistCm);
    final neckIn = _cmToInches(neckCm);
    final normalizedGender = gender.toLowerCase();

    if (normalizedGender == 'female') {
      final hipIn = _cmToInches(hipCm ?? 0);
      if (waistIn + hipIn - neckIn <= 0 || heightIn <= 0) {
        throw ArgumentError('Invalid female body fat measurements.');
      }
      return 163.205 * _log10(waistIn + hipIn - neckIn) -
          97.684 * _log10(heightIn) -
          78.387;
    }

    if (waistIn - neckIn <= 0 || heightIn <= 0) {
      throw ArgumentError('Invalid male body fat measurements.');
    }
    return 86.010 * _log10(waistIn - neckIn) -
        70.041 * _log10(heightIn) +
        36.76;
  }

  String aceCategory({required String gender, required double bodyFat}) {
    final isFemale = gender.toLowerCase() == 'female';
    if (isFemale) {
      if (bodyFat <= 13) return 'Essential fat';
      if (bodyFat <= 20) return 'Athletes';
      if (bodyFat <= 24) return 'Fitness';
      if (bodyFat <= 31) return 'Average';
      return 'Obese';
    }
    if (bodyFat <= 5) return 'Essential fat';
    if (bodyFat <= 13) return 'Athletes';
    if (bodyFat <= 17) return 'Fitness';
    if (bodyFat <= 24) return 'Average';
    return 'Obese';
  }

  double calculateFfmi({
    required double weightKg,
    required double heightCm,
    required double bodyFatPercentage,
    bool normalized = false,
  }) {
    final heightM = heightCm / 100;
    final leanMass = weightKg * (1 - bodyFatPercentage / 100);
    final ffmi = leanMass / math.pow(heightM, 2);
    if (!normalized) return ffmi.toDouble();
    return (ffmi + 6.1 * (1.8 - heightM)).toDouble();
  }

  double _cmToInches(double value) => value / 2.54;

  double _log10(double value) => math.log(value) / math.ln10;
}
