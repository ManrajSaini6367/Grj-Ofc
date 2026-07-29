import 'package:flutter/material.dart';
import 'package:grjoffice_apps/DayEndReport/day_end_report_screen.dart';
import 'package:grjoffice_apps/EmployeeListscreen/employees.dart';
import 'package:grjoffice_apps/Expensescreen/expenses.dart';
import 'package:grjoffice_apps/Itemsscreen/items.dart';
import 'package:grjoffice_apps/LabourContractor/contractors.dart';
import 'package:grjoffice_apps/SupplierList/suppliers.dart';
import 'package:grjoffice_apps/attendancescreen/attendance_screen.dart';
import 'package:grjoffice_apps/attendancescreen/contractor_attendance_screen.dart';
import 'package:grjoffice_apps/core/app_navigator.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_requests_screen.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_screen.dart';
import 'package:grjoffice_apps/kycscreens/kyc_requests_screen.dart';
import 'package:grjoffice_apps/kycscreens/kyc_status_screen.dart';
import 'package:grjoffice_apps/leavescreens/leave_requests_screen.dart';
import 'package:grjoffice_apps/leavescreens/leavescreen.dart';
import 'package:grjoffice_apps/main_shell.dart';
import 'package:grjoffice_apps/reportscreen/report_screen.dart';
import 'package:grjoffice_apps/rolesscreen/roles_screen.dart';
import 'package:grjoffice_apps/tasksscreen/tasks_screen.dart';
import 'package:grjoffice_apps/widgets/app_bottom_nav.dart';
import 'package:grjoffice_apps/utils/app_helpers.dart';

/// Bottom tab indices in [MainShell].
abstract final class MainTab {
  static const dashboard = 0;
  static const chats = 1;
  static const purchase = 2;
  static const store = 3;
  static const profile = 4;
}

/// Drawer menu indices in [AppDrawer].
abstract final class DrawerIndex {
  static const dashboard = 0;
  static const employees = 1;
  static const dayEndReport = 2;
  static const suppliers = 3;
  static const labourContractors = 4;
  static const items = 5;
  static const store = 6;
  static const expenses = 7;
  static const tasks = 8;
  static const purchase = 9;
  static const employeeAttendances = 10;
  static const contractorAttendances = 11;
  static const roles = 12;
  static const report = 13;
  static const leave = 14;
  static const leaveRequests = 15;
  static const kycVerification = 16;
  static const kycRequests = 17;
  static const employeeKyc = 18;
  static const employeeKycRequests = 19;
}

bool shellCanPop(BuildContext context) {
  final shell = AppShellScope.maybeOf(context);
  if (shell == null) return false;
  return shell.shellNavigatorKey.currentState?.canPop() ?? false;
}

void popShellRoute(BuildContext context) {
  final shell = AppShellScope.maybeOf(context);
  final shellNav = shell?.shellNavigatorKey.currentState;
  if (shellNav != null && shellNav.canPop()) {
    shellNav.pop();
    return;
  }

  final nav = Navigator.maybeOf(context);
  if (nav != null && nav.canPop()) {
    nav.pop();
  }
}

void showComingSoon(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label is coming soon.')),
  );
}

/// Switches tab when already inside [MainShell], otherwise opens [MainShell].
void navigateToMainTab(BuildContext context, int index) {
  if (!AppBottomNav.canAccessTab(index)) {
    message(context, 'You do not have permission to access this');
    return;
  }

  final shell = AppShellScope.maybeOf(context);
  if (shell != null) {
    shell.shellNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (shell.currentIndex != index) {
      shell.switchToTab(index);
    }
    return;
  }

  navigateToScreenAndClearStack(MainShell(initialIndex: index));
}

/// Pushes a secondary screen above the tab stack while keeping the bottom bar visible.
void pushInShell(BuildContext context, Widget screen) {
  final shell = AppShellScope.maybeOf(context);
  if (shell != null) {
    final nav = shell.shellNavigatorKey.currentState;
    nav?.popUntil((route) => route.isFirst);
    nav?.push(MaterialPageRoute(builder: (_) => screen));
    return;
  }

  navigateToScreenAndClearStack(MainShell(initialPush: screen));
}

/// Handles [AppDrawer] menu taps consistently while keeping the bottom bar visible.
void navigateFromDrawer(BuildContext context, int drawerIndex) {
  switch (drawerIndex) {
    case DrawerIndex.dashboard:
      navigateToMainTab(context, MainTab.dashboard);
    case DrawerIndex.employees:
      pushInShell(context, const EmployeesScreen(isActive: true));
    case DrawerIndex.dayEndReport:
      pushInShell(context, const DayEndReportScreen());
    case DrawerIndex.suppliers:
      pushInShell(context, const SuppliersScreen(isActive: true));
    case DrawerIndex.labourContractors:
      pushInShell(context, const ContractorsScreen(isActive: true));
    case DrawerIndex.items:
      pushInShell(context, const ItemsScreen());
    case DrawerIndex.store:
      navigateToMainTab(context, MainTab.store);
    case DrawerIndex.expenses:
      pushInShell(context, const ExpensesScreen());
    case DrawerIndex.tasks:
      pushInShell(context, const TasksScreen());
    case DrawerIndex.purchase:
      navigateToMainTab(context, MainTab.purchase);
    case DrawerIndex.employeeAttendances:
      pushInShell(context, const AttendanceScreen());
    case DrawerIndex.contractorAttendances:
      pushInShell(context, const ContractorAttendanceScreen());
    case DrawerIndex.roles:
      pushInShell(context, const RolesScreen());
    case DrawerIndex.report:
      pushInShell(context, const ReportScreen());
    case DrawerIndex.leave:
      pushInShell(context, const LeaveScreen());
    case DrawerIndex.leaveRequests:
      pushInShell(context, const LeaveRequestsScreen());
    case DrawerIndex.kycVerification:
      pushInShell(context, const KycVerificationScreen());
    case DrawerIndex.kycRequests:
      pushInShell(context, const KycRequestsScreen());
    case DrawerIndex.employeeKyc:
      pushInShell(context, const EmployeeKycScreen());
    case DrawerIndex.employeeKycRequests:
      pushInShell(context, const EmployeeKycRequestsScreen());
    default:
      break;
  }
}
