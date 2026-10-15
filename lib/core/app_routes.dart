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
import '../screens/placeholder_screen.dart';
import '../screens/results/appeal_screen.dart';
import '../screens/results/appeal_submitted_screen.dart';
import '../screens/results/application_approved_screen.dart';
import '../screens/results/application_declined_screen.dart';
import '../screens/shell/main_shell.dart';

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
  static const String renewal = '/renewal';
  static const String permitRequirements = '/permit-requirements';
  static const String help = '/help';

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
      default:
        // Screens that are not built yet open a "Coming soon" page.
        page = PlaceholderScreen(routeName: settings.name ?? 'unknown');
    }
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}