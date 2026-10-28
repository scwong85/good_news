import 'package:drift/wasm.dart';

/// Entry point of the shared database worker (compiled to web/drift_worker.js).
void main() => WasmDatabase.workerMainForOpen();
