import 'package:flutter/material.dart';

import '../models/student_model.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_dashboard_page.dart';
import '../screens/admin/bk_inbox_page.dart';
import '../screens/admin/counselor_workspace_page.dart';
import '../screens/admin/input_point_page.dart';
import '../screens/admin/notifications_page.dart';
import '../screens/admin/reports_page.dart';
import '../screens/admin/student_department_page.dart';
import '../screens/admin/summon_letter_page.dart';
import '../screens/auth/login_page.dart';
import '../screens/student/appointment_page.dart';
import '../screens/student/counseling_booking_page.dart';
import '../screens/student/counseling_chat_page.dart';
import '../screens/student/counseling_request_page.dart';
import '../screens/admin/counseling_requests_page.dart';
import '../screens/student/inbox_page.dart';
import '../screens/student/point_history_page.dart';
import '../screens/student/profile_page.dart';
import '../screens/student/report_incident_page.dart';
import '../screens/student/student_dashboard_page.dart';
import '../screens/student/submit_report_page.dart';
import '../screens/teacher/monitoring_records_page.dart';
import '../screens/teacher/student_detail_monitoring_page.dart';
import '../screens/teacher/wali_kelas_dashboard_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProfile = '/admin/profile';
  static const String bkInbox = '/admin/inbox';
  static const String counselorWorkspace = '/admin/counselor';
  static const String inputPoint = '/admin/input-point';
  static const String studentDepartment = '/admin/students';
  static const String summonLetter = '/admin/summon';
  static const String adminReports = '/admin/reports';
  static const String waliKelasDashboard = '/teacher/dashboard';
  static const String teacherProfile = '/teacher/profile';
  static const String monitoringRecords = '/teacher/records';
  static const String studentDetail = '/teacher/student-detail';
  static const String studentDashboard = '/student/dashboard';
  static const String studentProfile = '/student/profile';
  static const String counselingChat = '/student/chat';
  static const String submitReport = '/student/submit';
  static const String reportIncident = '/student/report';
  static const String inbox = '/student/inbox';
  static const String appointment = '/student/appointment';
  static const String pointHistory = '/student/points';
  static const String counselingBooking = '/student/booking';
  static const String counselingRequest = '/student/counseling-request';
  static const String adminCounselingRequests = '/admin/counseling-requests';
  static const String adminNotifications = '/admin/notifications';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardPage());
      case adminProfile:
      case teacherProfile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case bkInbox:
        return MaterialPageRoute(builder: (_) => const BkInboxPage());
      case counselorWorkspace:
        return MaterialPageRoute(builder: (_) => const CounselorWorkspacePage());
      case inputPoint:
        final student = settings.arguments as Student?;
        return MaterialPageRoute(builder: (_) => InputPointPage(student: student));
      case studentDepartment:
        return MaterialPageRoute(builder: (_) => const StudentDepartmentPage());
      case summonLetter:
        return MaterialPageRoute(builder: (_) => const SummonLetterPage());
      case adminReports:
        return MaterialPageRoute(builder: (_) => const ReportsPage());
      case waliKelasDashboard:
        return MaterialPageRoute(builder: (_) => const WaliKelasDashboardPage());
      case monitoringRecords:
        return MaterialPageRoute(builder: (_) => const MonitoringRecordsPage());
      case studentDetail:
        final student = settings.arguments as Student;
        return MaterialPageRoute(
          builder: (_) => StudentDetailMonitoringPage(student: student),
        );
      case studentDashboard:
        return MaterialPageRoute(builder: (_) => const StudentDashboardPage());
      case counselingChat:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CounselingChatPage(
            counselorId: (args?['counselorId'] as String?) ?? '',
            counselorName: (args?['counselorName'] as String?) ?? '',
          ),
        );
      case submitReport:
        return MaterialPageRoute(builder: (_) => const SubmitReportPage());
      case reportIncident:
        return MaterialPageRoute(builder: (_) => const ReportIncidentPage());
      case inbox:
        return MaterialPageRoute(builder: (_) => const InboxPage());
      case appointment:
        return MaterialPageRoute(builder: (_) => const AppointmentPage());
      case studentProfile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case pointHistory:
        return MaterialPageRoute(builder: (_) => const PointHistoryPage());
      case counselingBooking:
        return MaterialPageRoute(builder: (_) => const CounselingBookingPage());
      case counselingRequest:
        return MaterialPageRoute(builder: (_) => const CounselingRequestPage());
      case adminCounselingRequests:
        return MaterialPageRoute(builder: (_) => const CounselingRequestsPage());
      case adminNotifications:
        return MaterialPageRoute(builder: (_) => const NotificationsPage());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }

  static String getInitialRoute(AuthProvider auth) {
    if (!auth.isLoggedIn) return login;
    if (auth.isAdmin) return adminDashboard;
    if (auth.isWaliKelas) return waliKelasDashboard;
    return studentDashboard;
  }

  static void navigateTo(BuildContext context, String route,
      {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  static void replaceWith(BuildContext context, String route,
      {Object? arguments}) {
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }
}
