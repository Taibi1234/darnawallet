/// Represents MAD currency as integer minor units (100 minor = 1 MAD).
/// This avoids floating-point rounding errors in financial sums.
final class Money {
  final int cents; // 1 MAD = 100 cents

  const Money.fromCents(this.cents);
  factory Money.fromDouble(double amount) =>
      Money.fromCents((amount * 100).round());

  double toDouble() => cents / 100.0;
  int get whole => cents ~/ 100;
  int get minor => cents.abs() % 100;

  bool get isPositive => cents > 0;
  bool get isNegative => cents < 0;
  bool get isZero => cents == 0;

  Money operator +(Money other) => Money.fromCents(cents + other.cents);
  Money operator -(Money other) => Money.fromCents(cents - other.cents);
  Money operator *(int factor) => Money.fromCents(cents * factor);

  @override
  String toString() => '${toDouble().toStringAsFixed(2)} MAD';
}
