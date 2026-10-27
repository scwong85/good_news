// Runs the reader journey on a real device or emulator:
//
//   cd app && flutter test integration_test
//
// It uses in-memory storage and a fake web, so it needs no network. Not run in the cloud session
// (no Android SDK there); `test/app_flow_test.dart` runs the same journey as a widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/app_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('reader journey: fetch, read, save, explore, settings, offline', runAppFlow);
}
