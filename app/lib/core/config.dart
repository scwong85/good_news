import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time settings, passed with `--dart-define` (never committed).
class AppConfig {
  const AppConfig({this.contactEmail = const String.fromEnvironment('CONTACT_EMAIL')});

  /// Where readers and publishers can send removal requests. Release builds must set it
  /// (`--dart-define=CONTACT_EMAIL=...`); see docs/release-checklist.md.
  final String contactEmail;

  bool get hasContact => contactEmail.trim().isNotEmpty;
}

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());
