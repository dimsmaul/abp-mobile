part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const HOME = _Paths.HOME;
  static const DASHBOARD = _Paths.DASHBOARD;
  static const PROFILE = _Paths.PROFILE;
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const ATTENDANCE = _Paths.ATTENDANCE;
  static const ATTENDANCE_HISTORY = _Paths.ATTENDANCE_HISTORY;
  static const CAMERA = _Paths.CAMERA;
  static const REPORTS = _Paths.REPORTS;
  static const REPORT_CREATE = _Paths.REPORT_CREATE;
  static const REPORT_DETAIL = _Paths.REPORT_DETAIL;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const HOME = '/home';
  static const DASHBOARD = '/dashboard';
  static const PROFILE = '/profile';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const ATTENDANCE = '/attendance';
  static const ATTENDANCE_HISTORY = '/attendance-history';
  static const CAMERA = '/camera';
  static const REPORTS = '/reports';
  static const REPORT_CREATE = '/reports/create';
  static const REPORT_DETAIL = '/reports/detail';
}
