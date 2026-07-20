import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grjoffice_apps/core/api_config.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/models/mypermission.dart';
import 'package:grjoffice_apps/services/user_session.dart';
import 'package:http/http.dart' as http;

/// Permission keys as returned by GET /api/v1/permissions/me.
class AppPermissions {
  AppPermissions._();

  // Suppliers
  static const suppliersView = 'view_suppliers';
  static const suppliersCreate = 'add_suppliers';
  static const suppliersUpdate = 'edit_suppliers';
  static const suppliersDelete = 'delete_suppliers';

  // Contractors
  static const contractorsView = 'view_contractors';
  static const contractorsCreate = 'add_contractors';
  static const contractorsUpdate = 'edit_contractors';
  static const contractorsDelete = 'delete_contractors';

  // Labour / contractor attendances
  static const labourAttendancesView = 'view_contractor_attendances';
  static const labourAttendancesCreate = 'add_attendances';
  static const labourAttendancesReport = 'view_labour_attendance_report';

  // Employer attendances
  static const employerAttendancesView = 'view_employer_attendances';
  static const employerAttendancesCreate = 'add_EmployerAttendances';
  static const employerAttendancesReport = 'view_employer_attendance_report';

  // Purchases
  static const purchasesView = 'view_purchase';
  static const purchasesViewAll = 'view_allpurchase';
  static const purchasesCreate = 'add_purchase';

  // Expenses
  static const expensesCreate = 'add_expenses';
  static const expensesReport = 'view_expenses_report';

  // Items
  static const itemsView = 'view_items';
  static const itemsCreate = 'add_items';
  static const itemsUpdate = 'edit_items';

  // Tasks
  static const tasksCreate = 'add_tasks';
  static const tasksUpdate = 'edit_tasks';
  static const tasks1View = 'view_tasks1';
  static const tasks1Create = 'add_tasks1';

  // Users / employees
  static const usersView = 'view_users';
  static const usersCreate = 'add_users';
  static const usersBlock = 'block_users';

  // Reports / other
  static const viewBackend = 'view_backend';
  static const viewAttendances = 'view_attendances';
  static const viewDayReport = 'view_day_report';
  static const viewChallanReport = 'view_challan_report';
  static const viewMainReport = 'view_main_report';
  static const viewMainExcelReport = 'view_main_excel_report';
  static const allStaffAttendances = 'all_staff_attendances';
}

/// Loads and caches the logged-in user's role permissions for RBAC checks.
class PermissionService extends ChangeNotifier {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  static const _prefsKey = 'my_permissions';
  static const _rolesKey = 'my_roles';

  final Set<String> _permissions = {};
  final Set<String> _roles = {};
  bool _loaded = false;
  bool _loading = false;
  DateTime? _lastSyncedAt;

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  Set<String> get permissions => Set.unmodifiable(_permissions);
  Set<String> get roles => Set.unmodifiable(_roles);

  Map<String, String> get _authHeaders {
    final token = Preference.pref.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  bool can(String permission) {
    if (permission.trim().isEmpty) return false;
    return _permissions.contains(permission.trim().toLowerCase());
  }

  bool canAny(Iterable<String> permissions) {
    for (final p in permissions) {
      if (can(p)) return true;
    }
    return false;
  }

  bool canAll(Iterable<String> permissions) {
    for (final p in permissions) {
      if (!can(p)) return false;
    }
    return true;
  }

  bool hasRole(String role) =>
      _roles.contains(role.trim().toLowerCase());

  /// Apply permissions immediately (e.g. from login response).
  Future<void> apply({
    required Iterable<String> permissions,
    Iterable<String> roles = const [],
  }) async {
    final normalized = permissions
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    final normalizedRoles = roles
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    _permissions
      ..clear()
      ..addAll(normalized);
    _roles
      ..clear()
      ..addAll(normalizedRoles);
    _loaded = true;

    await Preference.pref.setStringList(_prefsKey, _permissions.toList());
    await Preference.pref.setStringList(_rolesKey, _roles.toList());
    _lastSyncedAt = DateTime.now();

    // Keep Profile / Drawer role labels in sync without waiting for profile API.
    final sessionUser = UserSession.instance.user;
    if (sessionUser != null) {
      UserSession.instance.setUser(
        sessionUser.copyWith(
          roles: _roles.toList(),
          permissions: _permissions.toList(),
        ),
      );
    }

    debugPrint(
      '[PermissionService] applied ${_permissions.length} permissions, '
      'roles=$_roles',
    );
    notifyListeners();
  }

  Future<void> loadFromCache() async {
    final raw = Preference.pref.getStringList(_prefsKey) ?? const <String>[];
    final roles = Preference.pref.getStringList(_rolesKey) ?? const <String>[];
    _permissions
      ..clear()
      ..addAll(raw.map((e) => e.toLowerCase()));
    _roles
      ..clear()
      ..addAll(roles.map((e) => e.toLowerCase()));
    _loaded = raw.isNotEmpty;
    notifyListeners();
  }

  /// GET /api/v1/permissions/me
  Future<Mypermissionmodaldata?> fetch() async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/permissions/me');
      debugPrint('[getMyPermissionsApi] GET $uri');

      final response = await http
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 30));

      debugPrint('[getMyPermissionsApi] statusCode: ${response.statusCode}');
      debugPrint('[getMyPermissionsApi] response body: ${response.body}');

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['success'] != true) return null;

      return Mypermissionmodaldata.fromJson(decoded);
    } on TimeoutException {
      debugPrint('[getMyPermissionsApi] request timed out');
    } catch (e, stack) {
      debugPrint('[getMyPermissionsApi] error: $e');
      debugPrint('[getMyPermissionsApi] stack: $stack');
    }
    return null;
  }

  /// Fetch latest permissions from API and replace cached ones.
  /// Does NOT restore old cache first (avoids showing previous role's buttons).
  Future<Mypermissionmodaldata?> refresh({bool force = true}) async {
    if (_loading) {
      debugPrint('[PermissionService] refresh already in progress');
      return null;
    }
    _loading = true;
    notifyListeners();

    try {
      final response = await fetch();
      final data = response?.data;
      if (response?.success == true && data != null) {
        final merged = <String>{
          ...?data.permissions,
          ...?data.rolePermissions,
          ...?data.directPermissions?.map((e) => e.toString()),
        };

        await apply(
          permissions: merged,
          roles: data.roles ?? const [],
        );
      } else {
        // API failed — fall back to cache only if we have nothing in memory.
        if (_permissions.isEmpty) {
          await loadFromCache();
        }
      }
      return response;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Refresh only if last sync is older than [maxAge] (or never synced).
  Future<Mypermissionmodaldata?> refreshIfStale({
    Duration maxAge = const Duration(seconds: 30),
  }) async {
    final last = _lastSyncedAt;
    if (last != null && DateTime.now().difference(last) < maxAge) {
      return null;
    }
    return refresh();
  }

  Future<void> clear() async {
    _permissions.clear();
    _roles.clear();
    _loaded = false;
    _lastSyncedAt = null;
    await Preference.pref.remove(_prefsKey);
    await Preference.pref.remove(_rolesKey);
    debugPrint('[PermissionService] cleared');
    notifyListeners();
  }
}

bool canPermission(String permission) =>
    PermissionService.instance.can(permission);

bool canAnyPermission(Iterable<String> permissions) =>
    PermissionService.instance.canAny(permissions);
