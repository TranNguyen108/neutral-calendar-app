import 'package:flutter/material.dart';
import 'app.dart';
import 'core/bindings/initial_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await InitialBinding().dependencies();
  runApp(const App());
}
