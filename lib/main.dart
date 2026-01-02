import 'package:flutter/material.dart';
import 'app.dart';
import 'core/bindings/initial_binding.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  InitialBinding().dependencies();
  runApp(const App());
}
