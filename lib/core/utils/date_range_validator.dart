/// Tarih aralığı doğrulama sonucu
class DateRangeValidationResult {
  /// Tarih aralığının geçerli olup olmadığı
  final bool isValid;

  /// Geçersiz aralık durumunda hata mesajı; geçerli ise null
  final String? errorMessage;

  const DateRangeValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  @override
  String toString() =>
      'DateRangeValidationResult(isValid: $isValid, errorMessage: $errorMessage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRangeValidationResult &&
          runtimeType == other.runtimeType &&
          isValid == other.isValid &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => isValid.hashCode ^ errorMessage.hashCode;
}

/// Tarih aralığını doğrular.
///
/// [start] başlangıç tarihi, [end] bitiş tarihi.
///
/// Bitiş tarihi başlangıç tarihinden önce ise [DateRangeValidationResult.isValid]
/// `false` ve [DateRangeValidationResult.errorMessage] dolu döner.
/// Aksi hâlde [DateRangeValidationResult.isValid] `true` ve
/// [DateRangeValidationResult.errorMessage] `null` döner.
///
/// Validates: Requirements 2.5
DateRangeValidationResult validateDateRange(DateTime start, DateTime end) {
  if (end.isBefore(start)) {
    return const DateRangeValidationResult(
      isValid: false,
      errorMessage: 'Bitiş tarihi başlangıç tarihinden önce olamaz',
    );
  }

  return const DateRangeValidationResult(isValid: true);
}
