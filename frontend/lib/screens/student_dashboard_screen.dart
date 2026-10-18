import 'package:flutter/material.dart';
import 'student_events_screen.dart';
import 'student_registrations_screen.dart';
import 'student_attendance_screen.dart';
import 'student_certificates_screen.dart';
import 'student_notifications_screen.dart';

/// Student portal entry screen. Connect this to your existing STUDENT login route.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});
  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _index = 0;
  static const _pages = <Widget>[
    StudentEventsScreen(),
    StudentRegistrationsScreen(),
    StudentAttendanceScreen(),
    StudentCertificatesScreen(),
    StudentNotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF060917),
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      backgroundColor: const Color(0xFF11152D),
      indicatorColor: const Color(0xFF8B5CF6).withOpacity(.35),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(color: states.contains(WidgetState.selected) ? Colors.white : Colors.white60, fontSize: 11)),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
        NavigationDestination(icon: Icon(Icons.confirmation_num_outlined), selectedIcon: Icon(Icons.confirmation_num), label: 'My Events'),
        NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Attendance'),
        NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium), label: 'Certificates'),
        NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
      ],
    ),
  );
}
