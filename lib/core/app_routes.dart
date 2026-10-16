import 'package:flutter/material.dart';

import '../screens/application/application_status_screen.dart';
import '../screens/application/application_submitted_screen.dart';
import '../screens/application/application_wizard_screen.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/permit/permit_details_screen.dart';
import '../screens/permit/permit_expired_screen.dart';
import '../screens/permit/renewal_screen.dart';
import '../screens/permit/sticker_pickup_screen.dart';
import '../screens/permit/sticker_replacement_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/notification_preferences_screen.dart';
import '../screens/profile/privacy_security_screen.dart';
import '../screens/results/appeal_screen.dart';
import '../screens/results/appeal_submitted_screen.dart';
import '../screens/results/application_approved_screen.dart';
import '../screens/results/application_declined_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/vehicles/vehicle_details_screen.dart';
import '../screens/vehicles/vehicle_update_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String completeProfile = '/complete-profile';
  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String apply = '/apply';
  static const String applicationSubmitted = '/application-submitted';
  static const String applicationStatus = '/application-status';
  static const String applicationApproved = '/application-approved';
  static const String applicationDeclined = '/application-declined';
  static const String appeal = '/appeal';
  static const String appealSubmitted = '/appeal-submitted';
  static const String permitDetails = '/permit-details';
  static const String stickerPickup = '/sticker-pickup';
  static const String stickerReplacement = '/sticker-replacement';
  static const String renewal = '/renewal';
  static const String permitExpired = '/permit-expired';
  static const String vehicleDetails = '/vehicle-details';
  static const String vehicleUpdate = '/vehicle-update';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String notificationPreferences = '/notification-preferences';
  static const String privacySecurity = '/privacy-security';
  static const String permitRequirements = '/permit-requirements';
  static const String help = '/help';
  static const String contactSupport = '/contact-support';
  static const String parkingPolicy = '/parking-policy';
  static const String parkingZones = '/parking-zones';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case welcome:
        page = const WelcomeScreen();
        break;
      case login:
        page = const LoginScreen();
        break;
      case register:
        page = const RegisterScreen();
        break;
      case forgotPassword:
        page = const ForgotPasswordScreen();
        break;
      case verifyEmail:
        page = const VerifyEmailScreen();
        break;
      case completeProfile:
        page = const CompleteProfileScreen();
        break;
      case home:
        page = const MainShell();
        break;
      case notifications:
        page = const NotificationsScreen();
        break;
      case apply:
        page = const ApplicationWizardScreen();
        break;
      case applicationSubmitted:
        page = const ApplicationSubmittedScreen();
        break;
      case applicationStatus:
        page = const ApplicationStatusScreen();
        break;
      case applicationApproved:
        page = const ApplicationApprovedScreen();
        break;
      case applicationDeclined:
        page = const ApplicationDeclinedScreen();
        break;
      case appeal:
        page = const AppealScreen();
        break;
      case appealSubmitted:
        page = const AppealSubmittedScreen();
        break;
      case permitDetails:
        page = const PermitDetailsScreen();
        break;
      case stickerPickup:
        page = const StickerPickupScreen();
        break;
      case stickerReplacement:
        page = const StickerReplacementScreen();
        break;
      case renewal:
        page = const RenewalScreen();
        break;
      case permitExpired:
        page = const PermitExpiredScreen();
        break;
      case vehicleDetails:
        page = const VehicleDetailsScreen();
        break;
      case vehicleUpdate:
        page = const VehicleUpdateScreen();
        break;
      case editProfile:
        page = const EditProfileScreen();
        break;
      case changePassword:
        page = const ChangePasswordScreen();
        break;
      case notificationPreferences:
        page = const NotificationPreferencesScreen();
        break;
      case privacySecurity:
        page = const PrivacySecurityScreen();
        break;
      default:
        // Screens that are not built yet open a "Coming soon" page.
        page = PlaceholderScreen(routeName: settings.name ?? 'unknown');
    }
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}