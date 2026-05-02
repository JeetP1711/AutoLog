import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pin_service.dart';
import '../theme/theme_controller.dart';

/// Provides a [PinService] instance backed by the app's [SharedPreferences].
final pinServiceProvider = Provider<PinService>((ref) {
  return PinService(ref.watch(sharedPreferencesProvider));
});
