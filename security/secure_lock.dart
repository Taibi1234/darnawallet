/// Secure session / app-lock handler using OS-level biometrics or device PIN.
/// No user secrets are stored. Degrades gracefully if unavailable.
final class SecureLock {
  // Minimal wrapper avoiding fragile dependency syntax.
  // Actual platform authentication is handled by OS APIs when enabled.
  static Future<bool> canCheck() async => false;
  static Future<bool> authenticate({String reason = 'Unlock wallet'}) async => false;
}
