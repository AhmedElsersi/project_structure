// Entry point. Run with your environment file:
//   flutter run --dart-define-from-file=.env
//
// Source: baytna lib/main.dart → bootstrap() split.
import 'bootstrap.dart';
import 'core/di/services_module.dart';
import 'features/sample_feature/items_di.dart';

Future<void> main() => bootstrap(
  modules: [
    registerServicesModule, // connectivity, url, permissions, image picker, push, app config
    registerItemsFeature,
    // Add new features here: registerXFeature,
  ],
);
