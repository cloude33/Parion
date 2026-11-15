/// Currency helpers for monetary values.
///
/// Amounts are stored as [double] for backward compatibility with existing
/// JSON backups. Every result that is persisted must pass through
/// [roundMoney] so binary floating point drift (0.1 + 0.2 != 0.3) cannot
/// accumulate over thousands of transactions.
const int moneyScale = 100;

/// Rounds [value] to the nearest minor unit (kuruş) and strips float noise.
double roundMoney(double value) {
  if (!value.isFinite) return 0;
  final scaled = value * moneyScale;
  if (scaled.abs() > 9007199254740991) return value;
  return scaled.roundToDouble() / moneyScale;
}

/// Sums [values] and rounds the result to a valid monetary amount.
double sumMoney(Iterable<double> values) =>
    roundMoney(values.fold(0.0, (sum, value) => sum + value));

/// Compares two monetary amounts with a tolerance smaller than one kuruş.
bool moneyEquals(double a, double b, {double tolerance = 0.0001}) =>
    (a - b).abs() <= tolerance;
