// This file is the entry point for the drift web worker.
// It runs SQLite operations in a separate thread for better performance.

import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}

