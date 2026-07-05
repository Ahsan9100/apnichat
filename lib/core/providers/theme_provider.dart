import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the app's theme mode (Light / Dark / System).
/// This can later be persisted using shared_preferences.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
