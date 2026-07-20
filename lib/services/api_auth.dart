import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/app_navigator.dart';
import 'package:grjoffice_apps/core/api_config.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/loginpage/loginpage.dart';
import 'package:grjoffice_apps/main_shell.dart';
import 'package:grjoffice_apps/LabourContractor/labour_contractor.dart';
import 'package:grjoffice_apps/Itemsscreen/item.dart';
import 'package:grjoffice_apps/models/getcontractor.dart';
import 'package:grjoffice_apps/models/getemployeemodal.dart';
import 'package:grjoffice_apps/models/getsupplier.dart';
import 'package:grjoffice_apps/models/getsupplierlist.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/models/itemhistorymodal.dart';
import 'package:grjoffice_apps/models/items_response_model.dart';
import 'package:grjoffice_apps/models/labourattendancereport.dart';
import 'package:grjoffice_apps/models/listcontractor.dart';
import 'package:grjoffice_apps/models/login_model.dart';
import 'package:grjoffice_apps/models/mypermission.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/models/sites_response_model.dart';
import 'package:grjoffice_apps/DayEndReport/activity.dart';
import 'package:grjoffice_apps/models/task_model.dart';
import 'package:grjoffice_apps/models/task_message_model.dart';
import 'package:grjoffice_apps/models/user_model.dart';
import 'package:grjoffice_apps/Expensescreen/expense.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/models/attendance_model.dart';
import 'package:grjoffice_apps/models/viewemployeeprofile.dart';
import 'package:grjoffice_apps/SupplierList/supplier.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/services/user_session.dart';
import 'package:grjoffice_apps/utils/app_helpers.dart';
import 'package:http/http.dart' as http;

bool get isLoggedIn => Preference.pref.getString('token') != null;

Map<String, String> get authHeaders {
  final token = Preference.pref.getString('token');
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

Map<String, String> get authHeadersMultipart {
  final token = Preference.pref.getString('token');
  return {
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

double apiToDouble(dynamic value, double fallback) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

Map<String, dynamic>? decodeApiJson(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty || trimmed.startsWith('<')) return null;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}
  return null;
}

Future<http.Response> apiPut(
  Uri uri, {
  required Map<String, String> headers,
  required String body,
}) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(seconds: 30);

  try {
    final request = await client.putUrl(uri);
    request.persistentConnection = false;
    // Dart sends Expect: 100-continue on PUT; many nginx/Laravel setups hang on it.
    request.headers.remove(HttpHeaders.expectHeader, '100-continue');

    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }

    request.add(utf8.encode(body));

    final ioResponse = await request.close().timeout(const Duration(seconds: 30));
    final responseBody = await ioResponse
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 30));

    final responseHeaders = <String, String>{};
    ioResponse.headers.forEach((name, values) {
      responseHeaders[name] = values.join(',');
    });

    return http.Response(
      responseBody,
      ioResponse.statusCode,
      headers: responseHeaders,
    );
  } finally {
    client.close(force: true);
  }
}

LabourContractor labourContractorFromApiData(
  Map<String, dynamic> responseData, {
  required String fallbackId,
  required String name,
  required String mobile,
  required String address,
  required double masonRate,
  required double beldarRate,
  required double coolieRate,
  required double masonOverRate,
  required double beldarOverRate,
  required double coolieOverRate,
  required ContractorStatus status,
}) {
  return LabourContractor(
    id: responseData['id']?.toString() ?? fallbackId,
    name: responseData['name']?.toString() ?? name,
    mobile: responseData['mobile']?.toString() ?? mobile,
    address: responseData['address']?.toString() ?? address,
    masonRatePerDay: apiToDouble(responseData['mason_rate'], masonRate),
    beldarRatePerDay: apiToDouble(responseData['beldar_rate'], beldarRate),
    coolieRatePerDay: apiToDouble(responseData['coolie_rate'], coolieRate),
    masonOtRatePerHour: apiToDouble(responseData['mason_over_rate'], masonOverRate),
    beldarOtRatePerHour: apiToDouble(responseData['beldar_over_rate'], beldarOverRate),
    coolieOtRatePerHour: apiToDouble(responseData['coolie_over_rate'], coolieOverRate),
    status: status,
  );
}

int? selectedSiteId() =>
    Preference.pref.getInt('site_id') ?? Preference.pref.getInt('selectedSiteId');

String? selectedSiteName() => Preference.pref.getString('selectedSiteName');

Future<void> saveSiteId(int siteId, {String? siteName}) async {
  await Preference.pref.setInt('site_id', siteId);
  await Preference.pref.setInt('selectedSiteId', siteId);
  if (siteName != null) {
    await Preference.pref.setString('selectedSiteName', siteName);
  }
}

Future<void> saveSiteIdFromUser(UserModel user) async {
  if (user.siteId > 0) {
    await saveSiteId(user.siteId);
  }
}

Future<void> _saveUser(UserModel user) async {
  await Preference.pref.setString('userId', user.id.toString());
  await Preference.pref.setString('phone', user.mobile);
  await Preference.pref.setString('email', user.email);
  await Preference.pref.setString('name', user.name);
  await Preference.pref.setString('user', jsonEncode(user.toJson()));
  await saveSiteIdFromUser(user);
  UserSession.instance.setUser(user);
}

UserModel? cachedUser() {
  final userJson = Preference.pref.getString('user');
  if (userJson == null) return null;
  try {
    return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

List<SiteModel>? cachedSites() {
  final sitesJson = Preference.pref.getString('sites');
  if (sitesJson == null) return null;
  try {
    return (jsonDecode(sitesJson) as List<dynamic>)
        .map((item) => SiteModel.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return null;
  }
}

List<ItemModel>? cachedItems() {
  final itemsJson = Preference.pref.getString('items');
  if (itemsJson == null) return null;
  try {
    return (jsonDecode(itemsJson) as List<dynamic>)
        .map((item) => ItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return null;
  }
}

String mediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '$baseUrl/$path';
}

List<String> siteNames(List<SiteModel> sites) {
  return sites.map((site) => site.name).where((name) => name.isNotEmpty).toList();
}

String? siteNameById(List<SiteModel> sites, int id) {
  for (final site in sites) {
    if (site.id == id) return site.name;
  }
  return null;
}

//login api
Future logInApi(
  BuildContext context,
  String login,
  String password, {
  bool rememberDevice = false,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': login.trim(),
        'password': password,
        'device_name': _deviceName,
        "device_id": "abc123-device-uuid",
      }),
    );
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final loginData = LoginModel.fromJson(data['data'] as Map<String, dynamic>);

        await Preference.pref.setString('token', loginData.token);
        await _saveUser(loginData.user);
        await Preference.pref.setBool('rememberDevice', rememberDevice);

        if (rememberDevice) {
          await Preference.pref.setString('rememberedLogin', login.trim());
        } else {
          await Preference.pref.remove('rememberedLogin');
        }

        // Clear previous role's permissions, apply login payload, then sync API.
        await PermissionService.instance.clear();
        await PermissionService.instance.apply(
          permissions: loginData.user.permissions,
          roles: loginData.user.roles,
        );
        await PermissionService.instance.refresh();

        if (!context.mounted) return;
        message(context, data['message'].toString());
        pushAndRevoveUntil(context, const MainShell());
      } else {
        if (!context.mounted) return;
        message(context, data['message'].toString());
        throw Exception('Failed to load data');
      }
    } else {
      final data = json.decode(response.body);
      if (!context.mounted) return;
      message(context, data['message'].toString());
      throw Exception('Failed to load data');
    }
  } catch (e) {
    print(e);
  }
}

//profile api
Future<UserModel?> profileApi(BuildContext context) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/profile'),
      headers: authHeaders,
    );
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final profile = UserModel.fromJson(data['data'] as Map<String, dynamic>);
        await _saveUser(profile);

        // Keep RBAC in sync whenever profile/role is refreshed.
        if (profile.permissions.isNotEmpty) {
          await PermissionService.instance.apply(
            permissions: profile.permissions,
            roles: profile.roles,
          );
        }
        await PermissionService.instance.refresh();

        return profile;
      } else {
        if (!context.mounted) return cachedUser();
        message(context, data['message'].toString());
        throw Exception('Failed to load data');
      }
    } else {
      final data = json.decode(response.body);
      if (!context.mounted) return cachedUser();
      message(context, data['message']?.toString() ?? 'Failed to load profile.');
      throw Exception('Failed to load data');
    }
  } catch (e) {
    print(e);
  }
  return cachedUser();
}

//sites api
Future<List<SiteModel>?> sitesApi(
  BuildContext context, {
  String search = '',
  int perPage = 15,
}) async {
  try {
    final uri = Uri.parse('$baseUrl/api/v1/sites').replace(
      queryParameters: {
        'search': search,
        'per_page': perPage.toString(),
      },
    );
    final response = await http.get(uri, headers: authHeaders);
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final sitesResponse =
            SitesResponseModel.fromJson(data['data'] as Map<String, dynamic>);
        final items = sitesResponse.items;

        await Preference.pref.setString(
          'sites',
          jsonEncode(items.map((site) => site.toJson()).toList()),
        );

        return items;
      } else {
        if (!context.mounted) return cachedSites();
        message(context, data['message'].toString());
        throw Exception('Failed to load data');
      }
    } else {
      final data = json.decode(response.body);
      if (!context.mounted) return cachedSites();
      message(context, data['message']?.toString() ?? 'Failed to load sites.');
      throw Exception('Failed to load data');
    }
  } catch (e) {
    print(e);
  }
  return cachedSites();
}

//items api
Future<List<ItemModel>?> itemsApi(
  BuildContext context, {
  int? siteId,
  String search = '',
  String status = 'published',
  String consumable = '0',
  int perPage = 15,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return cachedItems();
    }

    await Preference.pref.setInt('site_id', resolvedSiteId);

    final uri = Uri.parse('$baseUrl/api/v1/items').replace(
      queryParameters: {
        'site_id': resolvedSiteId.toString(),
        'search': search,
        'status': status,
        'consumable': consumable,
        'per_page': perPage.toString(),
        'purchase': '1',
      },
    );
    final response = await http.get(uri, headers: authHeaders);
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final itemsResponse =
            ItemsResponseModel.fromJson(data['data'] as Map<String, dynamic>);
        final items = itemsResponse.items;

        await Preference.pref.setString(
          'items',
          jsonEncode(items.map((item) => item.toJson()).toList()),
        );
        return items;
      } else {
        if (!context.mounted) return cachedItems();
        message(context, data['message'].toString());
        throw Exception('Failed to load data');
      }
    } else {
      final data = json.decode(response.body);
      if (!context.mounted) return cachedItems();
      message(context, data['message']?.toString() ?? 'Failed to load items.');
      throw Exception('Failed to load data');
    }
  } catch (e) {
    print(e);
  }
  return cachedItems();
}

//items search api (supplier materials etc.)
Future<List<ItemModel>?> itemsSearchApi(
  BuildContext context, {
  required String keyword,
  int? siteId,
  int perPage = 15,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final uri = Uri.parse('$baseUrl/api/v1/items/search').replace(
      queryParameters: {
        'site_id': resolvedSiteId.toString(),
        'keyword': keyword,
        'per_page': perPage.toString(),
      },
    );
    final response = await http.get(uri, headers: authHeaders);
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final itemsResponse =
            ItemsResponseModel.fromJson(data['data'] as Map<String, dynamic>);
        return itemsResponse.items;
      } else {
        if (!context.mounted) return null;
        message(context, data['message'].toString());
        throw Exception('Failed to load data');
      }
    } else {
      final data = json.decode(response.body);
      if (!context.mounted) return null;
      message(context, data['message']?.toString() ?? 'Failed to search items.');
      throw Exception('Failed to load data');
    }
  } catch (e) {
    print(e);
  }
  return null;
}

String get _deviceName {
  if (kIsWeb) return 'web';
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'flutter';
}
//logout api
Future<void> logoutApi(BuildContext context) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    final url = '$baseUrl/api/v1/logout';

    print('[logoutApi] POST $url');
    print('[logoutApi] Authorization: Bearer ${token.isEmpty ? '(empty)' : '***'}');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('[logoutApi] statusCode: ${response.statusCode}');
    print('[logoutApi] response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final success = data['success'] == true;
      final apiMessage = data['message']?.toString();

      if (success) {
        await _clearSessionData();
        print('[logoutApi] session cleared, navigating to LoginPage');
        navigateToScreenAndClearStack(LoginPage(flashMessage: apiMessage));
      } else {
        if (!context.mounted || apiMessage == null) return;
        message(context, apiMessage);
      }
    } else {
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      if (!context.mounted) return;
      final apiMessage = data?['message']?.toString();
      if (apiMessage != null) message(context, apiMessage);
    }
  } catch (e, stack) {
    print('[logoutApi] error: $e');
    print('[logoutApi] stack: $stack');
  }
}

Future<void> _clearSessionData() async {
  await Preference.pref.remove('token');
  await Preference.pref.remove('user');
  await Preference.pref.remove('userId');
  await Preference.pref.remove('phone');
  await Preference.pref.remove('email');
  await Preference.pref.remove('name');
  await Preference.pref.remove('sites');
  await Preference.pref.remove('items');
  await Preference.pref.remove('site_id');
  await Preference.pref.remove('selectedSiteId');
  await Preference.pref.remove('selectedSiteName');
  await PermissionService.instance.clear();
  UserSession.instance.clear();
}


//create supplierapi
Future<Supplier?> createSupplierApi(
  BuildContext context, {
  required int siteId,
  required String name,
  required String mobile,
  required String address,
  required String gstNo,
  required String panNo,
  required String status,
  required List<int> itemIds,
  required List<String> materialNames,
}) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    final url = '$baseUrl/api/v1/suppliers';

    print('[createSupplierApi] POST $url');
    print('[createSupplierApi] siteId: $siteId, itemIds: $itemIds');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'site_id': siteId,
        'name': name,
        'mobile': mobile,
        'address': address,
        'gst_no': gstNo,
        'pan_no': panNo,
        'status': status,
        'item_id': itemIds,
      }),
    );

    print('[createSupplierApi] statusCode: ${response.statusCode}');
    print('[createSupplierApi] response body: ${response.body}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final apiMessage = data['message']?.toString();

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (data['success'] == true) {
        if (!context.mounted) return null;
        if (apiMessage != null) message(context, apiMessage);

        final responseData = data['data'];
        final supplierStatus = status == 'unpublished'
            ? SupplierStatus.unpublished
            : SupplierStatus.published;

        if (responseData is Map<String, dynamic>) {
          return Supplier(
            id: responseData['id']?.toString() ?? '',
            name: responseData['name']?.toString() ?? name,
            mobile: responseData['mobile']?.toString() ?? mobile,
            materials: materialNames,
            gstNo: responseData['gst_no']?.toString() ?? gstNo,
            panNo: responseData['pan_no']?.toString() ?? panNo,
            address: responseData['address']?.toString() ?? address,
            status: supplierStatus,
          );
        }

        return Supplier(
          id: 'SUP-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          mobile: mobile,
          materials: materialNames,
          gstNo: gstNo,
          panNo: panNo,
          address: address,
          status: supplierStatus,
        );
      }

      if (!context.mounted) return null;
      if (apiMessage != null) message(context, apiMessage);
      return null;
    }

    if (!context.mounted) return null;
    if (apiMessage != null) message(context, apiMessage);
    return null;
  } catch (e, stack) {
    print('[createSupplierApi] error: $e');
    print('[createSupplierApi] stack: $stack');
    return null;
  }
}

//get supplier api
Future<Getsuppilerdata?> getSupplierApi(BuildContext context, int supplierId) async {
  try {
    final url = '$baseUrl/api/v1/suppliers/$supplierId';

    print('[getSupplierApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getSupplierApi] statusCode: ${response.statusCode}');
    print('[getSupplierApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 && decoded != null && decoded['success'] == true) {
      return Getsuppilerdata.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load supplier.');
    return null;
  } on TimeoutException {
    print('[getSupplierApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getSupplierApi] error: $e');
    print('[getSupplierApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

/// Maps a supplier detail response to [ItemModel]s for purchase material pickers.
List<ItemModel> supplierMaterialsFromData(
  SupplierData? data, {
  List<ItemModel> catalog = const [],
}) {
  if (data == null) return const [];

  final siteId = data.siteId ?? selectedSiteId() ?? 0;
  final supplierItems = data.items ?? const <SupplierItem>[];
  if (supplierItems.isNotEmpty) {
    return supplierItems
        .where((item) => item.id != null)
        .map(
          (item) => ItemModel(
            id: item.id!,
            siteId: siteId,
            name: item.name ?? '',
            unit: item.unit ?? '',
            status: 'published',
          ),
        )
        .toList();
  }

  final itemIds = data.itemIds ?? const <int>[];
  if (itemIds.isEmpty || catalog.isEmpty) return const [];
  final idSet = itemIds.toSet();
  return catalog.where((item) => idSet.contains(item.id)).toList();
}

/// Loads materials assigned to a supplier (`GET /api/v1/suppliers/{id}`).
Future<List<ItemModel>> loadSupplierMaterials(
  BuildContext context,
  int supplierId, {
  List<ItemModel> catalog = const [],
}) async {
  final response = await getSupplierApi(context, supplierId);
  return supplierMaterialsFromData(response?.data, catalog: catalog);
}

//getsupplierlistapi
Future<Getsupplierlistdata?> getSuppliersApi(
  BuildContext context, {
  int? siteId,
  String search = '',
  int perPage = 50,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      return null;
    }

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'per_page': perPage.toString(),
    };
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/api/v1/suppliers').replace(
      queryParameters: queryParams,
    );

    print('[getSuppliersApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getSuppliersApi] statusCode: ${response.statusCode}');
    print('[getSuppliersApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 && decoded != null && decoded['success'] == true) {
      return Getsupplierlistdata.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load suppliers.');
    return null;
  } on TimeoutException {
    print('[getSuppliersApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getSuppliersApi] error: $e');
    print('[getSuppliersApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

/// Suppliers linked to a specific item for the current site.
/// GET /api/v1/suppliers/by-item?site_id=&item_id=
Future<Getsupplierlistdata?> getSuppliersByItemApi(
  BuildContext context, {
  required int itemId,
  int? siteId,
  String search = '',
  String status = 'published',
  int perPage = 50,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      return null;
    }

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'item_id': itemId.toString(),
      'status': status,
      'per_page': perPage.toString(),
    };
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/api/v1/suppliers/by-item').replace(
      queryParameters: queryParams,
    );

    print('[getSuppliersByItemApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getSuppliersByItemApi] statusCode: ${response.statusCode}');
    print('[getSuppliersByItemApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 && decoded != null && decoded['success'] == true) {
      return Getsupplierlistdata.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load suppliers.');
    return null;
  } on TimeoutException {
    print('[getSuppliersByItemApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getSuppliersByItemApi] error: $e');
    print('[getSuppliersByItemApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//updatesupplierapi
Future<Supplier?> updateSupplierApi(
  BuildContext context, {
  required int supplierId,
  required String name,
  required String mobile,
  required String address,
  required String gstNo,
  required String panNo,
  required String status,
  required List<int> itemIds,
  required List<String> materialNames,
}) async {
  try {
    final url = '$baseUrl/api/v1/suppliers/$supplierId';

    print('[updateSupplierApi] PUT $url');
    print('[updateSupplierApi] supplierId: $supplierId, itemIds: $itemIds');

    final response = await apiPut(
      Uri.parse(url),
      headers: authHeaders,
      body: jsonEncode({
        'name': name,
        'mobile': mobile,
        'address': address,
        'gst_no': gstNo,
        'pan_no': panNo,
        'status': status,
        'item_id': itemIds,
      }),
    );

    print('[updateSupplierApi] statusCode: ${response.statusCode}');
    print('[updateSupplierApi] response body: ${response.body}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final apiMessage = data['message']?.toString();

    if (response.statusCode == 200 && data['success'] == true) {
      if (!context.mounted) return null;
      if (apiMessage != null) message(context, apiMessage);

      final responseData = data['data'];
      final supplierStatus = status == 'unpublished'
          ? SupplierStatus.unpublished
          : SupplierStatus.published;

      if (responseData is Map<String, dynamic>) {
        return Supplier(
          id: responseData['id']?.toString() ?? supplierId.toString(),
          name: responseData['name']?.toString() ?? name,
          mobile: responseData['mobile']?.toString() ?? mobile,
          materials: materialNames,
          gstNo: responseData['gst_no']?.toString() ?? gstNo,
          panNo: responseData['pan_no']?.toString() ?? panNo,
          address: responseData['address']?.toString() ?? address,
          status: supplierStatus,
        );
      }

      return Supplier(
        id: supplierId.toString(),
        name: name,
        mobile: mobile,
        materials: materialNames,
        gstNo: gstNo,
        panNo: panNo,
        address: address,
        status: supplierStatus,
      );
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to update supplier.');
    return null;
  } catch (e, stack) {
    print('[updateSupplierApi] error: $e');
    print('[updateSupplierApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}
//delete supplier api
Future<bool> deleteSupplierApi(
  BuildContext context,
  int supplierId,
) async {
  try {
    final url = '$baseUrl/api/v1/suppliers/$supplierId';

    print('[deleteSupplierApi] DELETE $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: authHeaders,
    );

    print('[deleteSupplierApi] statusCode: ${response.statusCode}');
    print('[deleteSupplierApi] response body: ${response.body}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final apiMessage = data['message']?.toString();

    if (response.statusCode == 200 && data['success'] == true) {
      if (!context.mounted) return false;
      if (apiMessage != null) message(context, apiMessage);
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to delete supplier.');
    return false;
  } catch (e, stack) {
    print('[deleteSupplierApi] error: $e');
    print('[deleteSupplierApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}
//create contractorapi
Future<LabourContractor?> createContractorApi(
  BuildContext context, {
  required int siteId,
  required String name,
  required String mobile,
  required String address,
  required String status,
  required int masonRate,
  required int beldarRate,
  required int coolieRate,
  required int masonOverRate,
  required int beldarOverRate,
  required int coolieOverRate,
}) async {
  try {
    final url = '$baseUrl/api/v1/contractors';

    print('[createContractorApi] POST $url');
    print('[createContractorApi] siteId: $siteId');

    final response = await http
        .post(
          Uri.parse(url),
          headers: authHeaders,
          body: jsonEncode({
            'site_id': siteId,
            'name': name,
            'mobile': mobile,
            'address': address,
            'status': status,
            'mason_rate': masonRate,
            'beldar_rate': beldarRate,
            'coolie_rate': coolieRate,
            'mason_over_rate': masonOverRate,
            'beldar_over_rate': beldarOverRate,
            'coolie_over_rate': coolieOverRate,
          }),
        )
        .timeout(const Duration(seconds: 30));

    print('[createContractorApi] statusCode: ${response.statusCode}');
    print('[createContractorApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    final apiMessage = data?['message']?.toString();

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (data != null && data['success'] == true) {
        final responseData = data['data'];
        final contractorStatus = status == 'unpublished'
            ? ContractorStatus.unpublished
            : ContractorStatus.published;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('items') &&
            responseData.containsKey('pagination')) {
          if (!context.mounted) return null;
          message(
            context,
            'Invalid server response. Contractor was not created.',
          );
          return null;
        }

        if (!context.mounted) return null;
        if (apiMessage != null &&
            apiMessage.toLowerCase().contains('contractor')) {
          message(context, apiMessage);
        }

        if (responseData is Map<String, dynamic>) {
          return labourContractorFromApiData(
            responseData,
            fallbackId: '',
            name: name,
            mobile: mobile,
            address: address,
            masonRate: masonRate.toDouble(),
            beldarRate: beldarRate.toDouble(),
            coolieRate: coolieRate.toDouble(),
            masonOverRate: masonOverRate.toDouble(),
            beldarOverRate: beldarOverRate.toDouble(),
            coolieOverRate: coolieOverRate.toDouble(),
            status: contractorStatus,
          );
        }

        return LabourContractor(
          id: 'CON-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          mobile: mobile,
          address: address,
          masonRatePerDay: masonRate.toDouble(),
          beldarRatePerDay: beldarRate.toDouble(),
          coolieRatePerDay: coolieRate.toDouble(),
          masonOtRatePerHour: masonOverRate.toDouble(),
          beldarOtRatePerHour: beldarOverRate.toDouble(),
          coolieOtRatePerHour: coolieOverRate.toDouble(),
          status: contractorStatus,
        );
      }

      if (!context.mounted) return null;
      if (apiMessage != null) message(context, apiMessage);
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to create contractor.');
    return null;
  } on TimeoutException {
    print('[createContractorApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[createContractorApi] error: $e');
    print('[createContractorApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//listcontractorapi

Future<Contractorlistdatamodal?> getContractorListApi(
  BuildContext context, {
  int? siteId,
  String search = '',
  int perPage = 50,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      return null;
    }

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'per_page': perPage.toString(),
    };
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/api/v1/contractors').replace(
      queryParameters: queryParams,
    );

    print('[getContractorListApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getContractorListApi] statusCode: ${response.statusCode}');
    print('[getContractorListApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 && decoded != null && decoded['success'] == true) {
      return Contractorlistdatamodal.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load contractors.');
    return null;
  } on TimeoutException {
    print('[getContractorListApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getContractorListApi] error: $e');
    print('[getContractorListApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}
//updatecontractorapi
Future<LabourContractor?> updateContractorApi(
  BuildContext context, {
  required int contractorId,
  required String name,
  required String mobile,
  required String address,
  required String status,
  required int masonRate,
  required int beldarRate,
  required int coolieRate,
  required int masonOverRate,
  required int beldarOverRate,
  required int coolieOverRate,
}) async {
  try {
    // Postman uses: PUT /api/v1/contractors/{id}  (no trailing slash)
    final uri = Uri.parse('$baseUrl/api/v1/contractors/$contractorId');
    final body = jsonEncode({
      'name': name,
      'mobile': mobile,
      'address': address,
      'status': status,
      'mason_rate': masonRate,
      'beldar_rate': beldarRate,
      'coolie_rate': coolieRate,
      'mason_over_rate': masonOverRate,
      'beldar_over_rate': beldarOverRate,
      'coolie_over_rate': coolieOverRate,
    });

    print('[updateContractorApi] PUT $uri');
    print('[updateContractorApi] contractorId: $contractorId');

    final response = await apiPut(
      uri,
      headers: authHeaders,
      body: body,
    );

    print('[updateContractorApi] statusCode: ${response.statusCode}');
    print('[updateContractorApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    if (data == null) {
      if (!context.mounted) return null;
      message(context, 'Invalid server response. Please try again.');
      return null;
    }

    final apiMessage = data['message']?.toString();

    if (response.statusCode == 200 && data['success'] == true) {
      if (!context.mounted) return null;
      if (apiMessage != null) message(context, apiMessage);

      final responseData = data['data'];
      final contractorStatus = status == 'unpublished'
          ? ContractorStatus.unpublished
          : ContractorStatus.published;

      final fallbackContractor = LabourContractor(
        id: contractorId.toString(),
        name: name,
        mobile: mobile,
        address: address,
        masonRatePerDay: masonRate.toDouble(),
        beldarRatePerDay: beldarRate.toDouble(),
        coolieRatePerDay: coolieRate.toDouble(),
        masonOtRatePerHour: masonOverRate.toDouble(),
        beldarOtRatePerHour: beldarOverRate.toDouble(),
        coolieOtRatePerHour: coolieOverRate.toDouble(),
        status: contractorStatus,
      );

      if (responseData is Map<String, dynamic>) {
        try {
          return labourContractorFromApiData(
            responseData,
            fallbackId: contractorId.toString(),
            name: name,
            mobile: mobile,
            address: address,
            masonRate: masonRate.toDouble(),
            beldarRate: beldarRate.toDouble(),
            coolieRate: coolieRate.toDouble(),
            masonOverRate: masonOverRate.toDouble(),
            beldarOverRate: beldarOverRate.toDouble(),
            coolieOverRate: coolieOverRate.toDouble(),
            status: contractorStatus,
          );
        } catch (e, stack) {
          print('[updateContractorApi] parse warning: $e');
          print('[updateContractorApi] parse stack: $stack');
          return fallbackContractor;
        }
      }

      return fallbackContractor;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to update contractor.');
    return null;
  } on TimeoutException {
    print('[updateContractorApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[updateContractorApi] error: $e');
    print('[updateContractorApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}
//deletecontractorapi


Future<bool> deleteContractorApi(
  BuildContext context,
  int contractorId,
) async {
  try {
    final url = '$baseUrl/api/v1/contractors/$contractorId';

    print('[deleteContractorApi] DELETE $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: authHeaders,
    ).timeout(const Duration(seconds: 30));

    print('[deleteContractorApi] statusCode: ${response.statusCode}');
    print('[deleteContractorApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    if (data == null) {
      if (!context.mounted) return false;
      message(context, 'Invalid server response. Please try again.');
      return false;
    }

    final apiMessage = data['message']?.toString();

    if (response.statusCode == 200 && data['success'] == true) {
      if (!context.mounted) return false;
      if (apiMessage != null) message(context, apiMessage);
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to delete contractor.');
    return false;
  } catch (e, stack) {
    print('[deleteContractorApi] error: $e');
    print('[deleteContractorApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//createitemapi
Future<InventoryItem?> createItemApi(
  BuildContext context, {
  required int siteId,
  required String name,
  required String sku,
  required String unit,
  required String status,
  required int balance,
  required int purchase,
  required int dayReport,
  required int consumable,
}) async {
  try {
    final url = '$baseUrl/api/v1/items';

    print('[createItemApi] POST $url');
    print('[createItemApi] siteId: $siteId');

    final response = await http
        .post(
          Uri.parse(url),
          headers: authHeaders,
          body: jsonEncode({
            'site_id': siteId,
            'name': name,
            'sku': sku,
            'unit': unit,
            'status': status,
            'balance': balance,
            'purchase': purchase,
            'day_report': dayReport,
            'consumable': consumable,
          }),
        )
        .timeout(const Duration(seconds: 30));

    print('[createItemApi] statusCode: ${response.statusCode}');
    print('[createItemApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    final apiMessage = data?['message']?.toString();
    final itemStatus = status == 'unpublished'
        ? ItemStatus.unpublished
        : ItemStatus.published;

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (data != null && data['success'] == true) {
        if (!context.mounted) return null;
        if (apiMessage != null) message(context, apiMessage);

        final responseData = data['data'];
        if (responseData is Map<String, dynamic>) {
          return InventoryItem(
            id: responseData['id']?.toString() ?? '',
            name: responseData['name']?.toString() ?? name,
            sku: responseData['sku']?.toString() ?? sku,
            unit: responseData['unit']?.toString() ?? unit,
            status: (responseData['status']?.toString() ?? status) == 'published'
                ? ItemStatus.published
                : ItemStatus.unpublished,
            directPurchase: (responseData['purchase'] ?? purchase) == 1,
            dayReport: (responseData['day_report'] ?? dayReport) == 1,
            consumable: (responseData['consumable'] ?? consumable) == 1,
          );
        }

        return InventoryItem(
          id: 'ITM-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          sku: sku,
          unit: unit,
          status: itemStatus,
          directPurchase: purchase == 1,
          dayReport: dayReport == 1,
          consumable: consumable == 1,
        );
      }

      if (!context.mounted) return null;
      if (apiMessage != null) message(context, apiMessage);
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to create item.');
    return null;
  } on TimeoutException {
    print('[createItemApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[createItemApi] error: $e');
    print('[createItemApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

InventoryItem inventoryItemFromApiData(
  Map<String, dynamic> responseData, {
  required String fallbackId,
  required String name,
  required String sku,
  required String unit,
  required String status,
  required int purchase,
  required int dayReport,
  required int consumable,
  int balance = 0,
}) {
  return InventoryItem(
    id: responseData['id']?.toString() ?? fallbackId,
    name: responseData['name']?.toString() ?? name,
    sku: responseData['sku']?.toString() ?? sku,
    unit: responseData['unit']?.toString() ?? unit,
    status: (responseData['status']?.toString() ?? status) == 'published'
        ? ItemStatus.published
        : ItemStatus.unpublished,
    directPurchase: (responseData['purchase'] ?? purchase) == 1,
    dayReport: (responseData['day_report'] ?? dayReport) == 1,
    consumable: (responseData['consumable'] ?? consumable) == 1,
    balance: apiToDouble(responseData['balance'], balance.toDouble()).round(),
  );
}

//itemupdate api
Future<InventoryItem?> updateItemApi(
  BuildContext context, {
  required int itemId,
  required String name,
  required String sku,
  required String unit,
  required String status,
  required int balance,
  required int purchase,
  required int dayReport,
  required int consumable,
}) async {
  try {
    final uri = Uri.parse('$baseUrl/api/v1/items/$itemId');
    final body = jsonEncode({
      'name': name,
      'sku': sku,
      'unit': unit,
      'status': status,
      'balance': balance,
      'purchase': purchase,
      'day_report': dayReport,
      'consumable': consumable,
    });

    print('[updateItemApi] PUT $uri');
    print('[updateItemApi] itemId: $itemId');

    final response = await apiPut(
      uri,
      headers: authHeaders,
      body: body,
    );

    print('[updateItemApi] statusCode: ${response.statusCode}');
    print('[updateItemApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    if (data == null) {
      if (!context.mounted) return null;
      message(context, 'Invalid server response. Please try again.');
      return null;
    }

    final apiMessage = data['message']?.toString();
    final itemStatus = status == 'unpublished'
        ? ItemStatus.unpublished
        : ItemStatus.published;

    if (response.statusCode == 200 && data['success'] == true) {
      final responseData = data['data'];
      final fallbackItem = InventoryItem(
        id: itemId.toString(),
        name: name,
        sku: sku,
        unit: unit,
        status: itemStatus,
        directPurchase: purchase == 1,
        dayReport: dayReport == 1,
        consumable: consumable == 1,
        balance: balance,
      );

      if (responseData is Map<String, dynamic>) {
        try {
          return inventoryItemFromApiData(
            responseData,
            fallbackId: itemId.toString(),
            name: name,
            sku: sku,
            unit: unit,
            status: status,
            purchase: purchase,
            dayReport: dayReport,
            consumable: consumable,
            balance: balance,
          );
        } catch (e, stack) {
          print('[updateItemApi] parse warning: $e');
          print('[updateItemApi] parse stack: $stack');
          return fallbackItem;
        }
      }

      return fallbackItem;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to update item.');
    return null;
  } on TimeoutException {
    print('[updateItemApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[updateItemApi] error: $e');
    print('[updateItemApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//itemdeleteapi
Future<bool> deleteItemApi(
  BuildContext context,
  int itemId,
) async {
  try {
    final url = '$baseUrl/api/v1/items/$itemId';

    print('[deleteItemApi] DELETE $url');

    final response = await http
        .delete(
          Uri.parse(url),
          headers: authHeaders,
        )
        .timeout(const Duration(seconds: 30));

    print('[deleteItemApi] statusCode: ${response.statusCode}');
    print('[deleteItemApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    if (data == null) {
      if (!context.mounted) return false;
      message(context, 'Invalid server response. Please try again.');
      return false;
    }

    final apiMessage = data['message']?.toString();

    if (response.statusCode == 200 && data['success'] == true) {
      if (!context.mounted) return false;
      if (apiMessage != null) message(context, apiMessage);
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to delete item.');
    return false;
  } catch (e, stack) {
    print('[deleteItemApi] error: $e');
    print('[deleteItemApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}
//itemhistoryapi
Future<Itemhistorydata?> itemHistoryApi(
  BuildContext context, {
  required int itemId,
  int perPage = 50,
}) async {
  try {
    final uri = Uri.parse('$baseUrl/api/v1/items/$itemId/history').replace(
      queryParameters: {
        'per_page': perPage.toString(),
      },
    );

    print('[itemHistoryApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[itemHistoryApi] statusCode: ${response.statusCode}');
    print('[itemHistoryApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return Itemhistorydata.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load item history.');
    return null;
  } on TimeoutException {
    print('[itemHistoryApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[itemHistoryApi] error: $e');
    print('[itemHistoryApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}
// createemployeeapi
Future<bool> createEmployeeApi(
  BuildContext context, {
  required int siteId,
  required String firstName,
  required String lastName,
  required String email,
  required String mobile,
  required String password,
  required String passwordConfirmation,
  required String designation,
  required String dateOfJoin,
  String? dateOfSuspended,
  required bool attendanceAllow,
  required int status,
}) async {
  try {
    final url = '$baseUrl/api/v1/employees';

    print('[createEmployeeApi] POST $url');
    print('[createEmployeeApi] siteId: $siteId');

    final body = <String, dynamic>{
      'site_id': siteId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'designation': designation,
      'date_of_join': dateOfJoin,
      'attendance_allow': attendanceAllow ? 1 : 0,
      'status': status,
    };
    if (dateOfSuspended != null && dateOfSuspended.isNotEmpty) {
      body['date_of_suspended'] = dateOfSuspended;
    }

    final response = await http
        .post(
          Uri.parse(url),
          headers: authHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print('[createEmployeeApi] statusCode: ${response.statusCode}');
    print('[createEmployeeApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    final apiMessage = data?['message']?.toString();

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (data != null && data['success'] == true) {
        return true;
      }

      if (!context.mounted) return false;
      message(context, apiMessage ?? 'Failed to create employee.');
      return false;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to create employee.');
    return false;
  } on TimeoutException {
    print('[createEmployeeApi] request timed out');
    if (!context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[createEmployeeApi] error: $e');
    print('[createEmployeeApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}
// listemployeeapi
Future<Getemployeesmodal?> getEmployeesApi(
  BuildContext context, {
  int? siteId,
  String search = '',
  int perPage = 50,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      return null;
    }

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'per_page': perPage.toString(),
    };
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/api/v1/employees').replace(
      queryParameters: queryParams,
    );

    print('[getEmployeesApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getEmployeesApi] statusCode: ${response.statusCode}');
    print('[getEmployeesApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return Getemployeesmodal.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load employees.');
    return null;
  } on TimeoutException {
    print('[getEmployeesApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getEmployeesApi] error: $e');
    print('[getEmployeesApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}
// editemployeeapi
Future<bool> updateEmployeeApi(
  BuildContext context, {
  required int employeeId,
  required String firstName,
  required String lastName,
  required String email,
  required String mobile,
  required String designation,
  required String dateOfJoin,
  String? dateOfSuspended,
  String? password,
  String? passwordConfirmation,
  required bool attendanceAllow,
  required int status,
}) async {
  try {
    final uri = Uri.parse('$baseUrl/api/v1/employees/$employeeId');
    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'designation': designation,
      'date_of_join': dateOfJoin,
      'attendance_allow': attendanceAllow ? 1 : 0,
      'status': status,
    };
    if (dateOfSuspended != null && dateOfSuspended.isNotEmpty) {
      body['date_of_suspended'] = dateOfSuspended;
    }
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
      body['password_confirmation'] = passwordConfirmation ?? password;
    }

    print('[updateEmployeeApi] PUT $uri');
    print('[updateEmployeeApi] employeeId: $employeeId');

    final response = await apiPut(
      uri,
      headers: authHeaders,
      body: jsonEncode(body),
    );

    print('[updateEmployeeApi] statusCode: ${response.statusCode}');
    print('[updateEmployeeApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    final apiMessage = data?['message']?.toString();

    if (response.statusCode == 200 && data != null && data['success'] == true) {
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to update employee.');
    return false;
  } catch (e, stack) {
    print('[updateEmployeeApi] error: $e');
    print('[updateEmployeeApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}
// deleteemployeeapi
Future<bool> deleteEmployeeApi(
  BuildContext context,
  int employeeId,
) async {
  try {
    final url = '$baseUrl/api/v1/employees/$employeeId';

    print('[deleteEmployeeApi] DELETE $url');

    final response = await http
        .delete(
          Uri.parse(url),
          headers: authHeaders,
        )
        .timeout(const Duration(seconds: 30));

    print('[deleteEmployeeApi] statusCode: ${response.statusCode}');
    print('[deleteEmployeeApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    final apiMessage = data?['message']?.toString();

    if (response.statusCode == 200 && data != null && data['success'] == true) {
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to delete employee.');
    return false;
  } on TimeoutException {
    print('[deleteEmployeeApi] request timed out');
    if (!context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[deleteEmployeeApi] error: $e');
    print('[deleteEmployeeApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}
// viewprofileofemployeeapi
Future<Viewemployeeprofile?> viewProfileOfEmployeeApi(
  BuildContext context,
  int employeeId,
) async {
  try {
    final url = '$baseUrl/api/v1/employees/$employeeId';

    print('[viewProfileOfEmployeeApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[viewProfileOfEmployeeApi] statusCode: ${response.statusCode}');
    print('[viewProfileOfEmployeeApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return Viewemployeeprofile.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load employee profile.');
    return null;
  } on TimeoutException {
    print('[viewProfileOfEmployeeApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[viewProfileOfEmployeeApi] error: $e');
    print('[viewProfileOfEmployeeApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}
// getcontractor api
Future<Getcontractormodal?> getContractorApi(
  BuildContext context,
  int contractorId,
) async {
  try {
    final url = '$baseUrl/api/v1/contractors/$contractorId';

    print('[getContractorApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getContractorApi] statusCode: ${response.statusCode}');
    print('[getContractorApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return Getcontractormodal.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load contractor.');
    return null;
  } on TimeoutException {
    print('[getContractorApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getContractorApi] error: $e');
    print('[getContractorApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//gettasksapi
Future<TasksListResponse?> getTasksApi(
  BuildContext context, {
  int? siteId,
  String status = 'all',
  String search = '',
  String? level,
  int? userId,
  String sortBy = 'due_date',
  String sortDir = 'asc',
  int perPage = 50,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'sort_by': sortBy,
      'sort_dir': sortDir,
      'per_page': perPage.toString(),
    };
    if (status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (level != null && level.trim().isNotEmpty) {
      queryParams['level'] = level.trim();
    }
    if (userId != null) {
      queryParams['user_id'] = userId.toString();
    }

    final uri = Uri.parse('$baseUrl/api/v1/tasks').replace(
      queryParameters: queryParams,
    );

    print('[getTasksApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getTasksApi] statusCode: ${response.statusCode}');
    print('[getTasksApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return TasksListResponse.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load tasks.');
    return null;
  } on TimeoutException {
    print('[getTasksApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getTasksApi] error: $e');
    print('[getTasksApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//createtaskapi
Future<Task?> createTaskApi(
  BuildContext context, {
  int? siteId,
  required int userId,
  required String title,
  String description = '',
  required String startDate,
  required String endDate,
  String status = 'start',
  String level = 'low',
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final url = '$baseUrl/api/v1/tasks';
    final body = <String, dynamic>{
      'site_id': resolvedSiteId,
      'user_id': userId,
      'title': title.trim(),
      'description': description.trim(),
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'level': level,
    };

    print('[createTaskApi] POST $url');
    print('[createTaskApi] body: $body');

    final response = await http
        .post(
          Uri.parse(url),
          headers: authHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print('[createTaskApi] statusCode: ${response.statusCode}');
    print('[createTaskApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 201 || response.statusCode == 200) &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Task.fromJson(data);
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to create task.');
    return null;
  } on TimeoutException {
    print('[createTaskApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[createTaskApi] error: $e');
    print('[createTaskApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//gettaskapi
Future<Task?> getTaskApi(BuildContext context, int taskId) async {
  try {
    final url = '$baseUrl/api/v1/tasks/$taskId';

    print('[getTaskApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getTaskApi] statusCode: ${response.statusCode}');
    print('[getTaskApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Task.fromJson(data);
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load task.');
    return null;
  } on TimeoutException {
    print('[getTaskApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getTaskApi] error: $e');
    print('[getTaskApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//updatetaskapi
Future<Task?> updateTaskApi(
  BuildContext context, {
  required int taskId,
  required String title,
  String description = '',
  required int userId,
  required String startDate,
  required String endDate,
  String status = 'start',
  String level = 'low',
}) async {
  try {
    final url = '$baseUrl/api/v1/tasks/$taskId';
    final body = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'user_id': userId,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'level': level,
    };

    print('[updateTaskApi] PUT $url');
    print('[updateTaskApi] body: $body');

    final response = await apiPut(
      Uri.parse(url),
      headers: authHeaders,
      body: jsonEncode(body),
    );

    print('[updateTaskApi] statusCode: ${response.statusCode}');
    print('[updateTaskApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Task.fromJson(data);
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to update task.');
    return null;
  } on TimeoutException {
    print('[updateTaskApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[updateTaskApi] error: $e');
    print('[updateTaskApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//updatetaskstatusapi
Future<Task?> updateTaskStatusApi(
  BuildContext context, {
  required int taskId,
  required String status,
}) async {
  try {
    final url = '$baseUrl/api/v1/tasks/$taskId';
    final body = <String, dynamic>{
      'status': status,
    };

    print('[updateTaskStatusApi] PUT $url');
    print('[updateTaskStatusApi] body: $body');

    final response = await apiPut(
      Uri.parse(url),
      headers: authHeaders,
      body: jsonEncode(body),
    );

    print('[updateTaskStatusApi] statusCode: ${response.statusCode}');
    print('[updateTaskStatusApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Task.fromJson(data);
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to update task status.');
    return null;
  } on TimeoutException {
    print('[updateTaskStatusApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[updateTaskStatusApi] error: $e');
    print('[updateTaskStatusApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//deletetaskapi
Future<bool> deleteTaskApi(BuildContext context, int taskId) async {
  try {
    final url = '$baseUrl/api/v1/tasks/$taskId';

    print('[deleteTaskApi] DELETE $url');

    final response = await http
        .delete(
          Uri.parse(url),
          headers: authHeaders,
        )
        .timeout(const Duration(seconds: 30));

    print('[deleteTaskApi] statusCode: ${response.statusCode}');
    print('[deleteTaskApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    final apiMessage = data?['message']?.toString();

    if (response.statusCode == 200 && data != null && data['success'] == true) {
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to delete task.');
    return false;
  } on TimeoutException {
    print('[deleteTaskApi] request timed out');
    if (!context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[deleteTaskApi] error: $e');
    print('[deleteTaskApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//getactivitiesapi
Future<ActivitiesListResponse?> getActivitiesApi(
  BuildContext context, {
  int? siteId,
  String type = 'all',
  String period = 'all',
  String search = '',
  int perPage = 20,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'type': type.trim().isEmpty ? 'all' : type.trim(),
      'period': period.trim().isEmpty ? 'all' : period.trim(),
      'per_page': perPage.toString(),
    };
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/api/v1/activities').replace(
      queryParameters: queryParams,
    );

    print('[getActivitiesApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getActivitiesApi] statusCode: ${response.statusCode}');
    print('[getActivitiesApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return ActivitiesListResponse.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load activities.');
    return null;
  } on TimeoutException {
    print('[getActivitiesApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getActivitiesApi] error: $e');
    print('[getActivitiesApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//getactivityapi
Future<ActivityEntry?> getActivityApi(
  BuildContext context,
  int activityId, {
  int? siteId,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final uri = Uri.parse('$baseUrl/api/v1/activities/$activityId').replace(
      queryParameters: {'site_id': resolvedSiteId.toString()},
    );

    print('[getActivityApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getActivityApi] statusCode: ${response.statusCode}');
    print('[getActivityApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true &&
        decoded['data'] is Map<String, dynamic>) {
      return ActivityEntry.fromJson(decoded['data'] as Map<String, dynamic>);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load activity.');
    return null;
  } on TimeoutException {
    print('[getActivityApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getActivityApi] error: $e');
    print('[getActivityApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//gettaskmessagesapi
Future<TaskMessagesListResponse?> getTaskMessagesApi(
  BuildContext context,
  int taskId, {
  int perPage = 50,
}) async {
  try {
    final uri = Uri.parse('$baseUrl/api/v1/tasks/$taskId/messages').replace(
      queryParameters: {'per_page': perPage.toString()},
    );

    print('[getTaskMessagesApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getTaskMessagesApi] statusCode: ${response.statusCode}');
    print('[getTaskMessagesApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return TaskMessagesListResponse.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load messages.');
    return null;
  } on TimeoutException {
    print('[getTaskMessagesApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getTaskMessagesApi] error: $e');
    print('[getTaskMessagesApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//sendtaskmessageapi
Future<TaskMessage?> sendTaskMessageApi(
  BuildContext context,
  int taskId, {
  required String messageText,
  int? receiverId,
}) async {
  try {
    final url = '$baseUrl/api/v1/tasks/$taskId/messages';
    final body = <String, dynamic>{
      'message': messageText.trim(),
      'receiver_id': receiverId,
    };

    print('[sendTaskMessageApi] POST $url');
    print('[sendTaskMessageApi] body: $body');

    final response = await http
        .post(
          Uri.parse(url),
          headers: authHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print('[sendTaskMessageApi] statusCode: ${response.statusCode}');
    print('[sendTaskMessageApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 201 || response.statusCode == 200) &&
        decoded != null &&
        decoded['success'] == true &&
        decoded['data'] is Map<String, dynamic>) {
      return TaskMessage.fromJson(decoded['data'] as Map<String, dynamic>);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to send message.');
    return null;
  } on TimeoutException {
    print('[sendTaskMessageApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[sendTaskMessageApi] error: $e');
    print('[sendTaskMessageApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//markalltaskmessagesreadapi
Future<bool> markAllTaskMessagesReadApi(
  BuildContext context,
  int taskId, {
  bool showErrors = true,
}) async {
  try {
    final url = '$baseUrl/api/v1/tasks/$taskId/messages/mark-read';

    print('[markAllTaskMessagesReadApi] POST $url');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[markAllTaskMessagesReadApi] statusCode: ${response.statusCode}');
    print('[markAllTaskMessagesReadApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return true;
    }

    if (!showErrors || !context.mounted) return false;
    message(context, apiMessage ?? 'Failed to mark messages as read.');
    return false;
  } on TimeoutException {
    print('[markAllTaskMessagesReadApi] request timed out');
    if (!showErrors || !context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[markAllTaskMessagesReadApi] error: $e');
    print('[markAllTaskMessagesReadApi] stack: $stack');
    if (!showErrors || !context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//marktaskmessagereadapi
Future<bool> markTaskMessageReadApi(
  BuildContext context,
  int taskId,
  int messageId, {
  bool showErrors = true,
}) async {
  try {
    final url = '$baseUrl/api/v1/tasks/$taskId/messages/$messageId/read';

    print('[markTaskMessageReadApi] POST $url');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[markTaskMessageReadApi] statusCode: ${response.statusCode}');
    print('[markTaskMessageReadApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return true;
    }

    if (!showErrors || !context.mounted) return false;
    message(context, apiMessage ?? 'Failed to mark message as read.');
    return false;
  } on TimeoutException {
    print('[markTaskMessageReadApi] request timed out');
    if (!showErrors || !context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[markTaskMessageReadApi] error: $e');
    print('[markTaskMessageReadApi] stack: $stack');
    if (!showErrors || !context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//deletetaskmessageapi
Future<bool> deleteTaskMessageApi(
  BuildContext context,
  int taskId,
  int messageId,
) async {
  try {
    final url = '$baseUrl/api/v1/tasks/$taskId/messages/$messageId';

    print('[deleteTaskMessageApi] DELETE $url');

    final response = await http
        .delete(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[deleteTaskMessageApi] statusCode: ${response.statusCode}');
    print('[deleteTaskMessageApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to delete message.');
    return false;
  } on TimeoutException {
    print('[deleteTaskMessageApi] request timed out');
    if (!context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[deleteTaskMessageApi] error: $e');
    print('[deleteTaskMessageApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//getexpensesapi
Future<ExpensesListResponse?> getExpensesApi(
  BuildContext context, {
  int? siteId,
  String period = 'this_month',
  String? category,
  String? type,
  String search = '',
  int perPage = 50,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'period': period,
      'per_page': perPage.toString(),
    };
    if (category != null && category.trim().isNotEmpty) {
      queryParams['category'] = category.trim();
    }
    if (type != null && type.trim().isNotEmpty) {
      queryParams['type'] = type.trim();
    }
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/api/v1/expenses').replace(
      queryParameters: queryParams,
    );

    print('[getExpensesApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getExpensesApi] statusCode: ${response.statusCode}');
    print('[getExpensesApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return ExpensesListResponse.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load expenses.');
    return null;
  } on TimeoutException {
    print('[getExpensesApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getExpensesApi] error: $e');
    print('[getExpensesApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//createexpenseapi
/// Supports cheque / cash / credit create payloads.
/// - Debit + cheque: includes `source` + `cheque`
/// - Debit + cash/upi/bank: includes `source` only
/// - Credit: omits `source` and `cheque`
Future<Expense?> createExpenseApi(
  BuildContext context, {
  int? siteId,
  required String date,
  required String type,
  String? source,
  String? cheque,
  required double amount,
  String? voucherNo,
  required String detail,
  required String category,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final url = '$baseUrl/api/v1/expenses';
    final normalizedType = type.trim().toLowerCase();
    final body = <String, dynamic>{
      'site_id': resolvedSiteId,
      'date': date,
      'type': normalizedType,
      'amount': amount,
      'detail': detail.trim(),
      'category': category,
    };

    // Credit create does not send source/cheque (per API).
    if (normalizedType != 'credit') {
      final normalizedSource = source?.trim().toLowerCase();
      if (normalizedSource != null && normalizedSource.isNotEmpty) {
        body['source'] = normalizedSource;
      }
      if (normalizedSource == 'cheque' &&
          cheque != null &&
          cheque.trim().isNotEmpty) {
        body['cheque'] = cheque.trim();
      }
    }

    if (voucherNo != null && voucherNo.trim().isNotEmpty) {
      body['voucher_no'] = voucherNo.trim();
    }

    print('[createExpenseApi] POST $url');
    print('[createExpenseApi] body: $body');

    final response = await http
        .post(
          Uri.parse(url),
          headers: authHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print('[createExpenseApi] statusCode: ${response.statusCode}');
    print('[createExpenseApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 201 || response.statusCode == 200) &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Expense.fromJson(data);
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to create expense.');
    return null;
  } on TimeoutException {
    print('[createExpenseApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[createExpenseApi] error: $e');
    print('[createExpenseApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//getexpenseapi
Future<Expense?> getExpenseApi(BuildContext context, int expenseId) async {
  try {
    final url = '$baseUrl/api/v1/expenses/$expenseId';

    print('[getExpenseApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getExpenseApi] statusCode: ${response.statusCode}');
    print('[getExpenseApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Expense.fromJson(data);
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load expense.');
    return null;
  } on TimeoutException {
    print('[getExpenseApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getExpenseApi] error: $e');
    print('[getExpenseApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//updateexpenseapi
Future<Expense?> updateExpenseApi(
  BuildContext context, {
  required int expenseId,
  required String date,
  required String type,
  String? source,
  String? cheque,
  required double amount,
  String? voucherNo,
  required String detail,
  required String category,
}) async {
  try {
    final url = '$baseUrl/api/v1/expenses/$expenseId';
    final normalizedType = type.trim().toLowerCase();
    final body = <String, dynamic>{
      'date': date,
      'type': normalizedType,
      'amount': amount,
      'detail': detail.trim(),
      'category': category,
    };

    if (normalizedType != 'credit') {
      final normalizedSource = source?.trim().toLowerCase();
      if (normalizedSource != null && normalizedSource.isNotEmpty) {
        body['source'] = normalizedSource;
      }
      if (normalizedSource == 'cheque' &&
          cheque != null &&
          cheque.trim().isNotEmpty) {
        body['cheque'] = cheque.trim();
      }
    }

    if (voucherNo != null && voucherNo.trim().isNotEmpty) {
      body['voucher_no'] = voucherNo.trim();
    }

    print('[updateExpenseApi] PUT $url');
    print('[updateExpenseApi] body: $body');

    final response = await apiPut(
      Uri.parse(url),
      headers: authHeaders,
      body: jsonEncode(body),
    );

    print('[updateExpenseApi] statusCode: ${response.statusCode}');
    print('[updateExpenseApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Expense.fromJson(data);
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to update expense.');
    return null;
  } on TimeoutException {
    print('[updateExpenseApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[updateExpenseApi] error: $e');
    print('[updateExpenseApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//deleteexpenseapi
Future<bool> deleteExpenseApi(BuildContext context, int expenseId) async {
  try {
    final url = '$baseUrl/api/v1/expenses/$expenseId';

    print('[deleteExpenseApi] DELETE $url');

    final response = await http
        .delete(
          Uri.parse(url),
          headers: authHeaders,
        )
        .timeout(const Duration(seconds: 30));

    print('[deleteExpenseApi] statusCode: ${response.statusCode}');
    print('[deleteExpenseApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    final apiMessage = data?['message']?.toString();

    if (response.statusCode == 200 && data != null && data['success'] == true) {
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to delete expense.');
    return false;
  } on TimeoutException {
    print('[deleteExpenseApi] request timed out');
    if (!context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[deleteExpenseApi] error: $e');
    print('[deleteExpenseApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

Future<http.Response> _sendMultipart(
  Uri uri, {
  required Map<String, String> fields,
  List<http.MultipartFile> files = const [],
}) async {
  final request = http.MultipartRequest('POST', uri);
  request.headers.addAll(authHeadersMultipart);
  request.fields.addAll(fields);
  request.files.addAll(files);
  final streamed = await request.send().timeout(const Duration(seconds: 60));
  return http.Response.fromStream(streamed).timeout(const Duration(seconds: 60));
}

Future<http.MultipartFile> _multipartImage(
  String field,
  File file, {
  String fallbackName = 'photo.jpg',
}) async {
  final filename = file.path.split(Platform.pathSeparator).last;
  return http.MultipartFile.fromPath(
    field,
    file.path,
    filename: filename.isEmpty ? fallbackName : filename,
  );
}

Purchase? _purchaseFromApiResponse(Map<String, dynamic>? decoded) {
  if (decoded == null || decoded['success'] != true) return null;
  final data = decoded['data'];
  if (data is Map<String, dynamic>) {
    return Purchase.fromJson(data);
  }
  return null;
}

//getpurchasesapi
Future<PurchasesListResponse?> getPurchasesApi(
  BuildContext context, {
  int? siteId,
  String period = 'all',
  String? status,
  String? flowType,
  String search = '',
  int perPage = 50,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'period': period,
      'per_page': perPage.toString(),
      'status': status?.trim() ?? '',
      'flow_type': flowType?.trim() ?? '',
      'search': search.trim(),
    };

    final uri = Uri.parse('$baseUrl/api/v1/purchases').replace(
      queryParameters: queryParams,
    );

    print('[getPurchasesApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getPurchasesApi] statusCode: ${response.statusCode}');
    print('[getPurchasesApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return PurchasesListResponse.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load purchases.');
    return null;
  } on TimeoutException {
    print('[getPurchasesApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getPurchasesApi] error: $e');
    print('[getPurchasesApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//getpurchaseapi
Future<Purchase?> getPurchaseApi(BuildContext context, int purchaseId) async {
  try {
    final url = '$baseUrl/api/v1/purchases/$purchaseId';

    print('[getPurchaseApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getPurchaseApi] statusCode: ${response.statusCode}');
    print('[getPurchaseApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Purchase.fromJson(data);
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load purchase.');
    return null;
  } on TimeoutException {
    print('[getPurchaseApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getPurchaseApi] error: $e');
    print('[getPurchaseApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//deletepurchaseapi
Future<bool> deletePurchaseApi(BuildContext context, int purchaseId) async {
  try {
    final url = '$baseUrl/api/v1/purchases/$purchaseId';

    print('[deletePurchaseApi] DELETE $url');

    final response = await http
        .delete(
          Uri.parse(url),
          headers: authHeaders,
        )
        .timeout(const Duration(seconds: 30));

    print('[deletePurchaseApi] statusCode: ${response.statusCode}');
    print('[deletePurchaseApi] response body: ${response.body}');

    final data = decodeApiJson(response.body);
    final apiMessage = data?['message']?.toString();

    if (response.statusCode == 200 && data != null && data['success'] == true) {
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to delete purchase.');
    return false;
  } on TimeoutException {
    print('[deletePurchaseApi] request timed out');
    if (!context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[deletePurchaseApi] error: $e');
    print('[deletePurchaseApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//getattendancesapi
Future<AttendancesListResponse?> getAttendancesApi(
  BuildContext context, {
  int? siteId,
  String? date,
  String? status,
  String search = '',
  int perPage = 50,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'per_page': perPage.toString(),
      'date': date?.trim() ?? '',
      'status': status?.trim() ?? '',
      'search': search.trim(),
    };

    final uri = Uri.parse('$baseUrl/api/v1/attendances').replace(
      queryParameters: queryParams,
    );

    print('[getAttendancesApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getAttendancesApi] statusCode: ${response.statusCode}');
    print('[getAttendancesApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return AttendancesListResponse.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load attendances.');
    return null;
  } on TimeoutException {
    print('[getAttendancesApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getAttendancesApi] error: $e');
    print('[getAttendancesApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//gettodayattendanceapi
Future<TodayAttendanceStatus?> getTodayAttendanceApi(
  BuildContext context, {
  int? siteId,
  bool showErrors = true,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (showErrors && context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final uri = Uri.parse('$baseUrl/api/v1/attendances/today').replace(
      queryParameters: {
        'site_id': resolvedSiteId.toString(),
      },
    );

    print('[getTodayAttendanceApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getTodayAttendanceApi] statusCode: ${response.statusCode}');
    print('[getTodayAttendanceApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return TodayAttendanceStatus.fromJson(data);
      }
      if (data is Map) {
        return TodayAttendanceStatus.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    }

    if (showErrors && context.mounted) {
      message(context, apiMessage ?? 'Failed to load today attendance.');
    }
    return null;
  } on TimeoutException {
    print('[getTodayAttendanceApi] request timed out');
    if (showErrors && context.mounted) {
      message(context, 'Request timed out. Please try again.');
    }
    return null;
  } catch (e, stack) {
    print('[getTodayAttendanceApi] error: $e');
    print('[getTodayAttendanceApi] stack: $stack');
    if (showErrors && context.mounted) {
      message(context, 'Something went wrong');
    }
    return null;
  }
}

//punchinapi — POST /attendances/punch-in (no employer_image)
Future<PunchActionResult?> punchInApi(
  BuildContext context, {
  required double latitude,
  required double longitude,
  int? siteId,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final url = '$baseUrl/api/v1/attendances/punch-in';
    final fields = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    print('[punchInApi] POST $url');
    print('[punchInApi] fields: $fields');

    final response = await _sendMultipart(
      Uri.parse(url),
      fields: fields,
    );

    print('[punchInApi] statusCode: ${response.statusCode}');
    print('[punchInApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      PunchActionResult? result;
      if (data is Map<String, dynamic>) {
        result = PunchActionResult.fromJson(data);
      } else if (data is Map) {
        result = PunchActionResult.fromJson(Map<String, dynamic>.from(data));
      }
      if (result != null) {
        return PunchActionResult(
          isPunchedIn: result.isPunchedIn,
          attendance: result.attendance,
          latitude: result.latitude,
          longitude: result.longitude,
          message: apiMessage,
        );
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to punch in.');
    return null;
  } on TimeoutException {
    print('[punchInApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[punchInApi] error: $e');
    print('[punchInApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//punchoutapi — POST /attendances/punch-out (JSON)
Future<PunchActionResult?> punchOutApi(
  BuildContext context, {
  required double latitude,
  required double longitude,
  int? siteId,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final url = '$baseUrl/api/v1/attendances/punch-out';
    final body = <String, dynamic>{
      'site_id': resolvedSiteId,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    print('[punchOutApi] POST $url');
    print('[punchOutApi] body: $body');

    final response = await http
        .post(
          Uri.parse(url),
          headers: authHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print('[punchOutApi] statusCode: ${response.statusCode}');
    print('[punchOutApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      PunchActionResult? result;
      if (data is Map<String, dynamic>) {
        result = PunchActionResult.fromJson(data);
      } else if (data is Map) {
        result = PunchActionResult.fromJson(Map<String, dynamic>.from(data));
      }
      if (result != null) {
        return PunchActionResult(
          isPunchedIn: result.isPunchedIn,
          attendance: result.attendance,
          latitude: result.latitude,
          longitude: result.longitude,
          message: apiMessage,
        );
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to punch out.');
    return null;
  } on TimeoutException {
    print('[punchOutApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[punchOutApi] error: $e');
    print('[punchOutApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//getattendanceapi
Future<Attendance?> getAttendanceApi(BuildContext context, int attendanceId) async {
  try {
    final url = '$baseUrl/api/v1/attendances/$attendanceId';

    print('[getAttendanceApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getAttendanceApi] statusCode: ${response.statusCode}');
    print('[getAttendanceApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return Attendance.fromJson(data);
      }
      if (data is Map) {
        return Attendance.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load attendance.');
    return null;
  } on TimeoutException {
    print('[getAttendanceApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getAttendanceApi] error: $e');
    print('[getAttendanceApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//createpurchaseapi — with_kanta / without_kanta / direct (multipart)
Future<Purchase?> createPurchaseApi(
  BuildContext context, {
  required String flowType,
  required int supplierId,
  required String vehicleNo,
  required File imageFile,
  List<int> itemIds = const [],
  List<PurchaseMaterialPayload> materials = const [],
  String? remark,
  int? siteId,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final normalizedFlow = flowType.trim().toLowerCase();
    final url = '$baseUrl/api/v1/purchases';
    final fields = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'flow_type': normalizedFlow,
      'supplier_id': supplierId.toString(),
      'vehicle_no': vehicleNo.trim(),
    };

    if (remark != null && remark.trim().isNotEmpty) {
      fields['remark'] = remark.trim();
    }

    if (normalizedFlow == 'direct') {
      for (var i = 0; i < materials.length; i++) {
        final m = materials[i];
        fields['materials[$i][item_id]'] = m.itemId.toString();
        fields['materials[$i][qty]'] = m.qty.toString();
        fields['materials[$i][unit]'] = m.unit;
      }
    } else {
      for (var i = 0; i < itemIds.length; i++) {
        fields['item_ids[$i]'] = itemIds[i].toString();
      }
    }

    final imageField = normalizedFlow == 'direct' ? 'image' : 'loading_image';
    final files = [
      await _multipartImage(imageField, imageFile),
    ];

    print('[createPurchaseApi] POST $url');
    print('[createPurchaseApi] fields: $fields');
    print('[createPurchaseApi] imageField: $imageField path=${imageFile.path}');

    final response = await _sendMultipart(
      Uri.parse(url),
      fields: fields,
      files: files,
    );

    print('[createPurchaseApi] statusCode: ${response.statusCode}');
    print('[createPurchaseApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();
    final purchase = _purchaseFromApiResponse(decoded);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        purchase != null) {
      return purchase;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to create purchase.');
    return null;
  } on TimeoutException {
    print('[createPurchaseApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[createPurchaseApi] error: $e');
    print('[createPurchaseApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//purchasestep2withkantaapi — POST /purchases/{id}/step-2
Future<Purchase?> purchaseStep2WithKantaApi(
  BuildContext context, {
  required int purchaseId,
  required String vehicleNo,
  required File unloadingImage,
}) async {
  try {
    final url = '$baseUrl/api/v1/purchases/$purchaseId/step-2';
    final fields = <String, String>{
      'vehicle_no': vehicleNo.trim(),
    };
    final files = [
      await _multipartImage('unloading_image', unloadingImage),
    ];

    print('[purchaseStep2WithKantaApi] POST $url');
    print('[purchaseStep2WithKantaApi] fields: $fields');

    final response = await _sendMultipart(
      Uri.parse(url),
      fields: fields,
      files: files,
    );

    print('[purchaseStep2WithKantaApi] statusCode: ${response.statusCode}');
    print('[purchaseStep2WithKantaApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();
    final purchase = _purchaseFromApiResponse(decoded);

    if (response.statusCode == 200 && purchase != null) {
      return purchase;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to save step 2.');
    return null;
  } on TimeoutException {
    print('[purchaseStep2WithKantaApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[purchaseStep2WithKantaApi] error: $e');
    print('[purchaseStep2WithKantaApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//purchasestep2withoutkantaapi — POST /purchases/{id}/step-2 (complete)
Future<Purchase?> purchaseStep2WithoutKantaApi(
  BuildContext context, {
  required int purchaseId,
  required String invoiceNo,
  String? remark,
  required List<PurchaseMaterialPayload> materials,
  required File unloadingImage,
}) async {
  try {
    final url = '$baseUrl/api/v1/purchases/$purchaseId/step-2';
    final fields = <String, String>{
      'invoice_no': invoiceNo.trim(),
    };
    if (remark != null && remark.trim().isNotEmpty) {
      fields['remark'] = remark.trim();
    }
    for (var i = 0; i < materials.length; i++) {
      final m = materials[i];
      fields['materials[$i][item_id]'] = m.itemId.toString();
      fields['materials[$i][qty]'] = m.qty.toString();
      fields['materials[$i][unit]'] = m.unit;
    }

    final files = [
      await _multipartImage('unloading_image', unloadingImage),
    ];

    print('[purchaseStep2WithoutKantaApi] POST $url');
    print('[purchaseStep2WithoutKantaApi] fields: $fields');

    final response = await _sendMultipart(
      Uri.parse(url),
      fields: fields,
      files: files,
    );

    print('[purchaseStep2WithoutKantaApi] statusCode: ${response.statusCode}');
    print('[purchaseStep2WithoutKantaApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();
    final purchase = _purchaseFromApiResponse(decoded);

    if (response.statusCode == 200 && purchase != null) {
      return purchase;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to complete purchase.');
    return null;
  } on TimeoutException {
    print('[purchaseStep2WithoutKantaApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[purchaseStep2WithoutKantaApi] error: $e');
    print('[purchaseStep2WithoutKantaApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//purchasestep3withkantaapi — POST /purchases/{id}/step-3
Future<Purchase?> purchaseStep3WithKantaApi(
  BuildContext context, {
  required int purchaseId,
  required String invoiceNo,
  required String kantaNo,
  String? remark,
  required List<PurchaseMaterialPayload> materials,
  required File kantaSlipImage,
  required File vehicleAtKantaImage,
}) async {
  try {
    final url = '$baseUrl/api/v1/purchases/$purchaseId/step-3';
    final fields = <String, String>{
      'invoice_no': invoiceNo.trim(),
      'kanta_no': kantaNo.trim(),
    };
    if (remark != null && remark.trim().isNotEmpty) {
      fields['remark'] = remark.trim();
    }
    for (var i = 0; i < materials.length; i++) {
      final m = materials[i];
      fields['materials[$i][item_id]'] = m.itemId.toString();
      fields['materials[$i][qty]'] = m.qty.toString();
      fields['materials[$i][unit]'] = m.unit;
    }

    final files = [
      await _multipartImage('kanta_slip_image', kantaSlipImage),
      await _multipartImage('vehicle_at_kanta_image', vehicleAtKantaImage),
    ];

    print('[purchaseStep3WithKantaApi] POST $url');
    print('[purchaseStep3WithKantaApi] fields: $fields');

    final response = await _sendMultipart(
      Uri.parse(url),
      fields: fields,
      files: files,
    );

    print('[purchaseStep3WithKantaApi] statusCode: ${response.statusCode}');
    print('[purchaseStep3WithKantaApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();
    final purchase = _purchaseFromApiResponse(decoded);

    if (response.statusCode == 200 && purchase != null) {
      return purchase;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to complete purchase.');
    return null;
  } on TimeoutException {
    print('[purchaseStep3WithKantaApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[purchaseStep3WithKantaApi] error: $e');
    print('[purchaseStep3WithKantaApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

Future<Getlabourattendancereport?> getLabourAttendanceReportApi(
  BuildContext context, {
  required String siteId,
  required String contractorId,
  required String startDate,
  required String endDate,
}) async {
  try {
    final uri = Uri.parse('$baseUrl/api/v1/labour-attendances').replace(
      queryParameters: {
        'site_id': siteId,
        'contractor_id': contractorId,
        'start_date': startDate,
        'end_date': endDate,
      },
    );

    print('[getLabourAttendanceReportApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getLabourAttendanceReportApi] statusCode: ${response.statusCode}');
    print('[getLabourAttendanceReportApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 && decoded != null) {
      return Getlabourattendancereport.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load labour attendance report.');
    return null;
  } on TimeoutException {
    print('[getLabourAttendanceReportApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getLabourAttendanceReportApi] error: $e');
    print('[getLabourAttendanceReportApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

Future<bool> markLabourAttendanceApi(
  BuildContext context, {
  required int siteId,
  required int contractorId,
  required String date,
  required int mason,
  required int beldar,
  required int coolie,
  required int masonOver,
  required int beldarOver,
  required int coolieOver,
}) async {
  try {
    final url = '$baseUrl/api/v1/labour-attendances';
    final body = {
      'site_id': siteId,
      'contractor_id': contractorId,
      'date': date,
      'mason': mason,
      'beldar': beldar,
      'coolie': coolie,
      'mason_over': masonOver,
      'beldar_over': beldarOver,
      'coolie_over': coolieOver,
    };

    print('[markLabourAttendanceApi] POST $url');
    print('[markLabourAttendanceApi] body: $body');

    final response = await http
        .post(
          Uri.parse(url),
          headers: authHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    print('[markLabourAttendanceApi] statusCode: ${response.statusCode}');
    print('[markLabourAttendanceApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decoded == null || decoded['success'] != false) {
        return true;
      }
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to save labour attendance.');
    return false;
  } on TimeoutException {
    print('[markLabourAttendanceApi] request timed out');
    if (!context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[markLabourAttendanceApi] error: $e');
    print('[markLabourAttendanceApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}


Future<Mypermissionmodaldata?> getMyPermissionsApi() {
  return PermissionService.instance.fetch();
}