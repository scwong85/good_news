import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_news/features/privacy/legal_text.dart';

/// Guards the privacy promises: these fail if someone adds tracking, background work or
/// extra permissions without revisiting docs/legal and the store data-safety answers.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final pubspec = File('pubspec.yaml').readAsStringSync();

  test('the only permission is INTERNET', () {
    final perms = RegExp(r'<uses-permission[^>]*android:name="([^"]+)"').allMatches(manifest).map((m) => m.group(1)).toList();
    expect(perms, ['android.permission.INTERNET']);
  });

  test('no background components and no cloud backup', () {
    expect(manifest, isNot(contains('<service')));
    expect(manifest, isNot(contains('<receiver')));
    expect(manifest, isNot(contains('<provider')));
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });

  test('no analytics, ads, crash reporting or background-work packages', () {
    const banned = [
      'firebase', 'sentry', 'crashlytics', 'google_mobile_ads', 'admob', 'facebook', 'appsflyer',
      'mixpanel', 'amplitude', 'segment', 'workmanager', 'flutter_local_notifications',
      'android_alarm_manager', 'background_fetch', 'permission_handler', 'geolocator',
    ];
    final deps = pubspec.split('dev_dependencies:').first.toLowerCase();
    for (final b in banned) {
      expect(deps, isNot(contains(b)), reason: 'package "$b" would break the privacy promises');
    }
  });

  test('the bundled privacy policy matches the canonical doc', () {
    expect(
      File('assets/legal/privacy_policy.md').readAsStringSync(),
      File('../docs/legal/privacy-policy.md').readAsStringSync(),
    );
  });

  test('the policy parses and the contact placeholder is always replaced', () {
    final md = File('assets/legal/privacy_policy.md').readAsStringSync();
    for (final email in [null, '', 'hello@example.org']) {
      final doc = parseLegal(md, contactEmail: email);
      expect(doc.title, 'Privacy Policy');
      expect(doc.blocks.map((b) => b.text).join(' '), isNot(contains('{{')));
    }
    expect(parseLegal(md, contactEmail: 'hello@example.org').blocks.map((b) => b.text), contains('Contact: hello@example.org'));
    expect(parseLegal(md).blocks.any((b) => b.kind == LegalKind.heading && b.text == 'The short version'), isTrue);
  });
}
