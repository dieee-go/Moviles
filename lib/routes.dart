import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/check_email_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/inicio_screen.dart';
import 'screens/events/explore_events_screen.dart';
import 'screens/events/create_event_service.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/events/my_events_screen.dart';
import 'screens/events/attendees_screen.dart';
import 'screens/events/edit_event_screen.dart';
import 'screens/profile/profile_page.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/admin/admin_panel_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/welcome': (context) => const WelcomeScreen(),
  '/check-email': (context) => const CheckEmailScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/forgot': (context) => const ForgotPasswordScreen(),
  '/home': (context) => const HomeScreen(),
  '/inicio': (context) => InicioScreen(),
  '/explore': (context) => ExploreEventsScreen(),
  '/create-event': (context) => CreateEventScreen(),
  '/my-events': (context) => MyEventsScreen(),
  '/profile': (context) => const ProfilePage(),
  '/edit-profile': (context) => EditProfileScreen(),
  '/notifications': (context) => NotificationsScreen(),
  '/admin': (context) => AdminPanelScreen(),
  '/event-detail': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return EventDetailScreen(eventId: args as String);
  },
  '/edit-event': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return EditEventScreen(eventId: args as String);
  },
  '/attendees': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return AttendeesScreen(eventId: args as String);
  },
};
