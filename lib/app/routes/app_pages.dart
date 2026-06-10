import 'package:get/get.dart';

import '../modules/attendance/bindings/attendance_binding.dart';
import '../modules/attendance/views/attendance_view.dart';
import '../modules/attendance_history/bindings/attendance_history_binding.dart';
import '../modules/attendance_history/views/attendance_history_view.dart';
import '../modules/camera/bindings/camera_binding.dart';
import '../modules/camera/views/camera_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/permit/bindings/permit_binding.dart';
import '../modules/permit/views/permit_view.dart';
import '../modules/permit/views/permit_detail_view.dart';
import '../modules/announcement/bindings/announcement_binding.dart';
import '../modules/announcement/views/announcement_list_view.dart';
import '../modules/announcement/views/announcement_detail_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/profile_edit/bindings/profile_edit_binding.dart';
import '../modules/profile_edit/views/profile_edit_view.dart';
import '../modules/change_password/bindings/change_password_binding.dart';
import '../modules/change_password/views/change_password_view.dart';
import '../modules/forget_password/bindings/forget_password_binding.dart';
import '../modules/forget_password/views/forget_password_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/reports/bindings/reports_binding.dart';
import '../modules/reports/views/reports_list_view.dart';
import '../modules/reports/views/report_create_view.dart';
import '../modules/reports/views/report_detail_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.FORGET_PASSWORD,
      page: () => const ForgetPasswordView(),
      binding: ForgetPasswordBinding(),
    ),
    GetPage(
      name: _Paths.ATTENDANCE,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
    ),
    GetPage(
      name: _Paths.ATTENDANCE_HISTORY,
      page: () => const AttendanceHistoryView(),
      binding: AttendanceHistoryBinding(),
    ),
    GetPage(
      name: _Paths.CAMERA,
      page: () => const CameraView(),
      binding: CameraBinding(),
    ),
    GetPage(
      name: _Paths.REPORTS,
      page: () => const ReportsListView(),
      binding: ReportsBinding(),
    ),
    GetPage(
      name: _Paths.REPORT_CREATE,
      page: () => const ReportCreateView(),
      binding: ReportsBinding(),
    ),
    GetPage(
      name: _Paths.REPORT_DETAIL,
      page: () => const ReportDetailView(),
      binding: ReportsBinding(),
    ),
    GetPage(
      name: _Paths.PERMIT,
      page: () => const PermitView(),
      binding: PermitBinding(),
    ),
    GetPage(
      name: _Paths.PERMIT_DETAIL,
      page: () => const PermitDetailView(),
      binding: PermitBinding(),
    ),
    // Category-locked entry points — all reuse the same PermitView and
    // controller, but pass `category` via Get.arguments so the page filters
    // its list + locks the create-form to that single category.
    GetPage(
      name: _Paths.LEAVE,
      page: () => const PermitView(),
      binding: PermitBinding(),
    ),
    GetPage(
      name: _Paths.OVERTIME,
      page: () => const PermitView(),
      binding: PermitBinding(),
    ),
    GetPage(
      name: _Paths.REIMBURSEMENT,
      page: () => const PermitView(),
      binding: PermitBinding(),
    ),
    GetPage(
      name: _Paths.LOAN,
      page: () => const PermitView(),
      binding: PermitBinding(),
    ),
    GetPage(
      name: _Paths.ANNOUNCEMENT_LIST,
      page: () => const AnnouncementListView(),
      binding: AnnouncementBinding(),
    ),
    GetPage(
      name: _Paths.ANNOUNCEMENT_DETAIL,
      page: () => const AnnouncementDetailView(),
      binding: AnnouncementBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE_EDIT,
      page: () => const ProfileEditView(),
      binding: ProfileEditBinding(),
    ),
    GetPage(
      name: _Paths.CHANGE_PASSWORD,
      page: () => const ChangePasswordView(),
      binding: ChangePasswordBinding(),
    ),
  ];
}
