import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'core/signup_info.dart';
import 'core/supabase_config.dart';
import 'models/notification_store.dart';
import 'models/profile_store.dart';
import 'screens/guard/guard_scanner_screen.dart';
import 'services/auth_service.dart';
import 'widgets/responsive_frame.dart';
import 'services/guard_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  var initialRoute = AppRoutes.welcome;
  if (kSupabaseReady) {
    await Supabase.initialize(url: kSupabaseUrl, publishableKey: kSupabaseAnonKey);
    // A saved session means the user is already logged in.
    if (Supabase.instance.client.auth.currentSession != null) {
      if (await GuardService.isGuard()) {
        initialRoute = kGuardRoute;
      } else {
        await AuthService.loadProfile();
        initialRoute = ProfileStore.instance.profileCompleted
            ? AppRoutes.home
            : AppRoutes.completeProfile;
      }
    }
  }

  NotificationStore.instance.ensureStarted();
  runApp(ParkPermitApp(initialRoute: initialRoute));
}

class ParkPermitApp extends StatelessWidget {
  const ParkPermitApp({super.key, this.initialRoute = AppRoutes.welcome});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCU ParkPermit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      builder: (context, child) => ResponsiveFrame(child: child ?? const SizedBox.shrink()),
      onGenerateRoute: (settings) {
        if (settings.name == kGuardRoute) {
          return MaterialPageRoute(builder: (_) => const GuardScannerScreen(), settings: settings);
        }
        var s = settings;
        // Opening Complete Profile directly (saved session): use the stored role.
        if (settings.name == AppRoutes.completeProfile && settings.arguments == null) {
          s = RouteSettings(
            name: settings.name,
            arguments: SignupInfo(
              email: ProfileStore.instance.email,
              role: ProfileStore.instance.role,
            ),
          );
        }
        return AppRoutes.onGenerateRoute(s);
      },
    );
  }
}