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
import 'screens/events/attendance_screen.dart';
import 'screens/events/edit_event_screen.dart';
import 'screens/events/calendar_screen.dart';
import 'screens/events/qr_scan_screen.dart';
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
  '/calendar': (context) => const CalendarScreen(),
  '/profile': (context) => const ProfilePage(),
  '/edit-profile': (context) => EditProfileScreen(),
  '/notifications': (context) => NotificationsScreen(),
  '/admin': (context) => AdminPanelScreen(),
  '/event-detail': (context) {
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    if (args == null) {
      return const Scaffold(
        body: Center(child: Text('Error: ID de evento no proporcionado')),
      );
    }
    return EventDetailScreen(eventId: args);
  },
  '/edit-event': (context) {
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    if (args == null) {
      return const Scaffold(
        body: Center(child: Text('Error: ID de evento no proporcionado')),
      );
    }
    return EditEventScreen(eventId: args);
  },
  '/attendees': (context) {
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    if (args == null) {
      return const Scaffold(
        body: Center(child: Text('Error: ID de evento no proporcionado')),
      );
    }
    return AttendanceScreen(eventId: args);
  },
  '/qr-scan': (context) => const QrScanScreen(),
};
