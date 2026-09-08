import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grjoffice_apps/InwardOutward/inward_outward_store.dart';
import 'package:grjoffice_apps/chatmodalsclasses/createopendirectmodal.dart';
import 'package:grjoffice_apps/chatmodalsclasses/getchatlistmodal.dart';
import 'package:grjoffice_apps/chatmodalsclasses/getlistmessagesmodal.dart';
import 'package:grjoffice_apps/chatmodalsclasses/showthreadmodal.dart';
import 'package:grjoffice_apps/chatmodalsclasses/threadchatmodal.dart';
import 'package:grjoffice_apps/core/app_navigator.dart';
import 'package:grjoffice_apps/core/api_config.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/loginpage/loginpage.dart';
import 'package:grjoffice_apps/LabourContractor/labour_contractor.dart';
import 'package:grjoffice_apps/Itemsscreen/item.dart';
import 'package:grjoffice_apps/models/getcalendermodal.dart';
import 'package:grjoffice_apps/models/getcontractor.dart';
import 'package:grjoffice_apps/models/getemployeemodal.dart';
import 'package:grjoffice_apps/models/getempoyeeskycrequest.dart';
import 'package:grjoffice_apps/models/getlistnotificationmodal.dart';
import 'package:grjoffice_apps/models/getnotificationmodal.dart';
import 'package:grjoffice_apps/models/getleavetypemodal.dart';
import 'package:grjoffice_apps/models/getmyleavemodal.dart';
import 'package:grjoffice_apps/models/getoriginalcontractor.dart';
import 'package:grjoffice_apps/models/getcontractorlist.dart';
import 'package:grjoffice_apps/models/getshowleavemodal.dart';
import 'package:grjoffice_apps/models/getsupplier.dart';
import 'package:grjoffice_apps/models/getsupplierlist.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/models/itemhistorymodal.dart';
import 'package:grjoffice_apps/models/items_response_model.dart';
import 'package:grjoffice_apps/models/labourattendancereport.dart';
import 'package:grjoffice_apps/models/leaverequestHR.dart';
import 'package:grjoffice_apps/models/listcontractor.dart';
import 'package:grjoffice_apps/models/login_model.dart';
import 'package:grjoffice_apps/models/mykycdatamodal.dart';
import 'package:grjoffice_apps/models/mypermission.dart';
import 'package:grjoffice_apps/models/pagination_model.dart';
import 'package:grjoffice_apps/models/showemployeeskycmodal.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/models/sites_response_model.dart';
import 'package:grjoffice_apps/DayEndReport/activity.dart';
import 'package:grjoffice_apps/models/task_model.dart';
import 'package:grjoffice_apps/models/task_message_model.dart';
import 'package:grjoffice_apps/models/user_model.dart';
import 'package:grjoffice_apps/Expensescreen/expense.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/models/approvekycmodal.dart';
import 'package:grjoffice_apps/models/attendance_model.dart';
import 'package:grjoffice_apps/models/getreportmodal.dart';
import 'package:grjoffice_apps/models/viewemployeeprofile.dart';
import 'package:grjoffice_apps/SupplierList/supplier.dart';
import 'package:grjoffice_apps/services/kyc_gate.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/services/user_session.dart';
import 'package:grjoffice_apps/utils/app_helpers.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

export 'package:grjoffice_apps/core/api_config.dart' show mediaUrl;

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

/// Headers for PDF / binary downloads (not JSON APIs).
Map<String, String> get pdfAuthHeaders {
  final token = Preference.pref.getString('token');
  return {
    'Accept': 'application/pdf,application/octet-stream,*/*',
    'Cache-Control': 'no-cache',
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

    final ioResponse = await request.close().timeout(
      const Duration(seconds: 30),
    );
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
  List<String> agreements = const [],
  List<String> documents = const [],
  String? cancelCheque,
}) {
  return LabourContractor(
    id: responseData['id']?.toString() ?? fallbackId,
    name: responseData['name']?.toString() ?? name,
    mobile: responseData['mobile']?.toString() ?? mobile,
    address: responseData['address']?.toString() ?? address,
    masonRatePerDay: apiToDouble(responseData['mason_rate'], masonRate),
    beldarRatePerDay: apiToDouble(responseData['beldar_rate'], beldarRate),
    coolieRatePerDay: apiToDouble(responseData['coolie_rate'], coolieRate),
    masonOtRatePerHour: apiToDouble(
      responseData['mason_over_rate'],
      masonOverRate,
    ),
    beldarOtRatePerHour: apiToDouble(
      responseData['beldar_over_rate'],
      beldarOverRate,
    ),
    coolieOtRatePerHour: apiToDouble(
      responseData['coolie_over_rate'],
      coolieOverRate,
    ),
    status: status,
    agreements: _stringListFromApi(responseData['agreements'], agreements),
    documents: _stringListFromApi(responseData['documents'], documents),
    cancelCheque:
        responseData['cancel_cheque']?.toString().trim().isNotEmpty == true
        ? responseData['cancel_cheque']?.toString()
        : (responseData['cancel_cheque_url']?.toString().trim().isNotEmpty ==
                  true
              ? responseData['cancel_cheque_url']?.toString()
              : cancelCheque),
  );
}

List<String> _stringListFromApi(
  dynamic value, [
  List<String> fallback = const [],
]) {
  if (value is! List) return fallback;
  final out = <String>[];
  for (final item in value) {
    final s = item?.toString().trim() ?? '';
    if (s.isNotEmpty && s != 'null') out.add(s);
  }
  return out.isEmpty ? fallback : out;
}

int? selectedSiteId() =>
    Preference.pref.getInt('site_id') ??
    Preference.pref.getInt('selectedSiteId');

int? currentRoleId() =>
    cachedUser()?.roleId ?? Preference.pref.getInt('role_id');

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
  if (user.roleId != null && user.roleId! > 0) {
    await Preference.pref.setInt('role_id', user.roleId!);
  } else {
    await Preference.pref.remove('role_id');
  }
  await saveSiteIdFromUser(user);
  UserSession.instance.setUser(user);
}

Future<void> updateCachedKycStatus(String? status) async {
  final user = cachedUser();
  if (user == null) return;
  final next = (status ?? '').trim();
  final updated = next.isEmpty
      ? user.copyWith(clearKycStatus: true)
      : user.copyWith(kycStatus: next.toLowerCase());
  await _saveUser(updated);
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
        .whereType<Map>()
        .map((item) => SiteModel.fromJson(Map<String, dynamic>.from(item)))
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

List<ItemModel>? cachedStoreItems() {
  final itemsJson = Preference.pref.getString('store_items');
  if (itemsJson == null) return null;
  try {
    return (jsonDecode(itemsJson) as List<dynamic>)
        .map((item) => ItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return null;
  }
}

List<String> siteNames(List<SiteModel> sites) {
  return sites
      .map((site) => site.name)
      .where((name) => name.isNotEmpty)
      .toList();
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
  final email = login.trim();
  final rawPassword = password;
  final trimmedPassword = password.trim();
  if (email.isEmpty || trimmedPassword.isEmpty) {
    if (context.mounted) {
      message(context, 'Please enter email and password.');
    }
    return;
  }

  try {
    final url = '$baseUrl/api/v1/login';
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final requestBody = {
      'email': email,
      'password': trimmedPassword,
      'device_name': _deviceName,
      'device_id': 'abc123-device-uuid',
    };
    final encodedBody = jsonEncode(requestBody);

    print('========== LOGIN REQUEST ==========');
    print('[Login] URL: $url');
    print('[Login] headers: $headers');
    print('[Login] raw email: "$login"');
    print('[Login] trimmed email: "$email"  len=${email.length}');
    print('[Login] raw password: "$rawPassword"  len=${rawPassword.length}');
    print(
      '[Login] trimmed password: "$trimmedPassword"  len=${trimmedPassword.length}',
    );
    print('[Login] password codeUnits: ${trimmedPassword.codeUnits}');
    print('[Login] device_name: $_deviceName');
    print('[Login] request JSON: $encodedBody');
    print('===================================');

    final response = await http
        .post(Uri.parse(url), headers: headers, body: encodedBody)
        .timeout(const Duration(seconds: 30));

    print('========== LOGIN RESPONSE ==========');
    print('[Login] status: ${response.statusCode}');
    print('[Login] response headers: ${response.headers}');
    print('[Login] response body: ${response.body}');
    print('====================================');

    final data = decodeApiJson(response.body);
    if (data == null) {
      if (context.mounted) {
        message(context, 'Unexpected server response. Please try again.');
      }
      return;
    }

    if (response.statusCode == 200 && data['success'] == true) {
      final payload = data['data'];
      if (payload is! Map<String, dynamic>) {
        if (context.mounted) {
          message(context, 'Invalid login response. Please try again.');
        }
        return;
      }

      final loginData = LoginModel.fromJson(payload);

      await Preference.pref.setString('token', loginData.token);
      await _saveUser(loginData.user);
      await Preference.pref.setBool('rememberDevice', rememberDevice);

      if (rememberDevice) {
        await Preference.pref.setString('rememberedLogin', email);
      } else {
        await Preference.pref.remove('rememberedLogin');
      }

      // Apply permissions from login first so UI can open immediately.
      await PermissionService.instance.clear();
      await PermissionService.instance.apply(
        permissions: loginData.user.permissions,
        roles: loginData.user.roles,
      );
      // Sync latest permissions in background (don't block login).
      unawaited(PermissionService.instance.refresh());

      if (!context.mounted) return;
      message(
        context,
        data['message']?.toString() ?? 'Logged in successfully.',
      );
      pushAndRevoveUntil(context, KycGate.homeScreen());
      return;
    }

    if (!context.mounted) return;
    message(
      context,
      data['message']?.toString() ??
          'Login failed. Please check your credentials.',
    );
  } on TimeoutException {
    debugPrint('Login API timeout');
    if (context.mounted) {
      message(context, 'Server is taking too long. Please try again.');
    }
  } on SocketException catch (e) {
    debugPrint('Login API network error: $e');
    if (context.mounted) {
      message(context, 'No internet connection. Please try again.');
    }
  } catch (e, st) {
    debugPrint('Login API error: $e\n$st');
    if (context.mounted) {
      message(context, 'Login failed. Please try again.');
    }
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
        final profile = UserModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
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
      message(
        context,
        data['message']?.toString() ?? 'Failed to load profile.',
      );
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
      queryParameters: {'search': search, 'per_page': perPage.toString()},
    );
    final response = await http.get(uri, headers: authHeaders);
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final rawData = data['data'];
        final sitesResponse = SitesResponseModel.fromJson(
          rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : <String, dynamic>{},
        );
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
  String? consumable = '0',
  String? purchase = '1',
  int perPage = 15,
  int page = 1,
  bool fetchAllPages = false,
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

    Future<ItemsResponseModel?> fetchPage(int pageNo) async {
      final query = <String, String>{
        'site_id': resolvedSiteId.toString(),
        'per_page': perPage.toString(),
        'page': pageNo.toString(),
      };
      if (search.trim().isNotEmpty) query['search'] = search.trim();
      if (status.trim().isNotEmpty) query['status'] = status.trim();
      if (consumable != null && consumable.trim().isNotEmpty) {
        query['consumable'] = consumable.trim();
      }
      if (purchase != null && purchase.trim().isNotEmpty) {
        query['purchase'] = purchase.trim();
      }

      final uri = Uri.parse(
        '$baseUrl/api/v1/items',
      ).replace(queryParameters: query);
      debugPrint('[itemsApi] GET $uri');

      final response = await http
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 30));
      debugPrint('[itemsApi] status=${response.statusCode}');
      debugPrint(response.body);

      if (response.statusCode != 200) {
        final data = decodeApiJson(response.body);
        if (context.mounted) {
          message(
            context,
            data?['message']?.toString() ?? 'Failed to load items.',
          );
        }
        return null;
      }

      final data = decodeApiJson(response.body);
      if (data == null || data['success'] != true) {
        if (context.mounted) {
          message(
            context,
            data?['message']?.toString() ?? 'Failed to load items.',
          );
        }
        return null;
      }

      final payload = data['data'];
      if (payload is! Map<String, dynamic>) return null;
      return ItemsResponseModel.fromJson(payload);
    }

    final first = await fetchPage(page);
    if (first == null) return cachedItems();

    final allItems = <ItemModel>[...first.items];

    if (fetchAllPages) {
      final lastPage = first.pagination.lastPage;
      for (var p = page + 1; p <= lastPage; p++) {
        if (!context.mounted) break;
        final next = await fetchPage(p);
        if (next == null) break;
        allItems.addAll(next.items);
      }
    }

    await Preference.pref.setString(
      'items',
      jsonEncode(allItems.map((item) => item.toJson()).toList()),
    );
    return allItems;
  } catch (e, st) {
    debugPrint('[itemsApi] error: $e\n$st');
  }
  return cachedItems();
}

// Store catalog: published, non-consumable items for the site (admin Item History list).
Future<List<ItemModel>?> storeItemsApi(
  BuildContext context, {
  int? siteId,
  String search = '',
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return cachedStoreItems();
    }

    await Preference.pref.setInt('site_id', resolvedSiteId);

    final query = <String, String>{
      'site_id': resolvedSiteId.toString(),
    };
    if (search.trim().isNotEmpty) query['search'] = search.trim();

    final uri = Uri.parse(
      '$baseUrl/api/v1/store-items',
    ).replace(queryParameters: query);
    debugPrint('[storeItemsApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));
    debugPrint('[storeItemsApi] status=${response.statusCode}');
    debugPrint(response.body);

    if (response.statusCode != 200) {
      final data = decodeApiJson(response.body);
      if (context.mounted) {
        message(
          context,
          data?['message']?.toString() ?? 'Failed to load store items.',
        );
      }
      return cachedStoreItems();
    }

    final data = decodeApiJson(response.body);
    if (data == null || data['success'] != true) {
      if (context.mounted) {
        message(
          context,
          data?['message']?.toString() ?? 'Failed to load store items.',
        );
      }
      return cachedStoreItems();
    }

    final payload = data['data'];
    if (payload is! List) return cachedStoreItems();

    final allItems = payload
        .whereType<Map<String, dynamic>>()
        .map(ItemModel.fromJson)
        .toList();

    await Preference.pref.setString(
      'store_items',
      jsonEncode(allItems.map((item) => item.toJson()).toList()),
    );
    return allItems;
  } catch (e, st) {
    debugPrint('[storeItemsApi] error: $e\n$st');
  }
  return cachedStoreItems();
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
        final itemsResponse = ItemsResponseModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        return itemsResponse.items;
      } else {
        if (!context.mounted) return null;
        message(context, data['message'].toString());
        throw Exception('Failed to load data');
      }
    } else {
      final data = json.decode(response.body);
      if (!context.mounted) return null;
      message(
        context,
        data['message']?.toString() ?? 'Failed to search items.',
      );
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
    print(
      '[logoutApi] Authorization: Bearer ${token.isEmpty ? '(empty)' : '***'}',
    );

    final response = await http.post(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
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
  await Preference.pref.remove('role_id');
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
Future<Getsuppilerdata?> getSupplierApi(
  BuildContext context,
  int supplierId,
) async {
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

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
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
  int perPage = 15,
  int page = 1,
  bool fetchAllPages = false,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      return null;
    }

    Future<Getsupplierlistdata?> fetchPage(int pageNo) async {
      final queryParams = <String, String>{
        'site_id': resolvedSiteId.toString(),
        'per_page': perPage.toString(),
        'page': pageNo.toString(),
      };
      if (search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse(
        '$baseUrl/api/v1/suppliers',
      ).replace(queryParameters: queryParams);

      debugPrint('[getSuppliersApi] GET $uri');

      final response = await http
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 30));

      debugPrint('[getSuppliersApi] statusCode: ${response.statusCode}');
      debugPrint('[getSuppliersApi] response body: ${response.body}');

      final decoded = decodeApiJson(response.body);
      final apiMessage = decoded?['message']?.toString();

      if (response.statusCode == 200 &&
          decoded != null &&
          decoded['success'] == true) {
        return Getsupplierlistdata.fromJson(decoded);
      }

      if (context.mounted) {
        message(context, apiMessage ?? 'Failed to load suppliers.');
      }
      return null;
    }

    final first = await fetchPage(page);
    if (first == null) return null;

    if (!fetchAllPages) return first;

    final allItems = <SupplierListItem>[...(first.data?.items ?? const [])];
    final lastPage = first.data?.pagination?.lastPage ?? 1;

    for (var p = page + 1; p <= lastPage; p++) {
      if (!context.mounted) break;
      final next = await fetchPage(p);
      if (next == null) break;
      allItems.addAll(next.data?.items ?? const []);
    }

    return Getsupplierlistdata(
      success: first.success,
      message: first.message,
      data: SupplierListData(
        items: allItems,
        pagination: SupplierListPagination(
          currentPage: 1,
          lastPage: lastPage,
          perPage: perPage,
          total: allItems.length,
        ),
      ),
    );
  } on TimeoutException {
    debugPrint('[getSuppliersApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    debugPrint('[getSuppliersApi] error: $e');
    debugPrint('[getSuppliersApi] stack: $stack');
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

    final uri = Uri.parse(
      '$baseUrl/api/v1/suppliers/by-item',
    ).replace(queryParameters: queryParams);

    print('[getSuppliersByItemApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getSuppliersByItemApi] statusCode: ${response.statusCode}');
    print('[getSuppliersByItemApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
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
Future<bool> deleteSupplierApi(BuildContext context, int supplierId) async {
  try {
    final url = '$baseUrl/api/v1/suppliers/$supplierId';

    print('[deleteSupplierApi] DELETE $url');

    final response = await http.delete(Uri.parse(url), headers: authHeaders);

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
  List<File> agreementFiles = const [],
  List<File> documentFiles = const [],
  File? cancelChequeFile,
}) async {
  try {
    final url = '$baseUrl/api/v1/contractors';
    final hasFiles =
        agreementFiles.isNotEmpty ||
        documentFiles.isNotEmpty ||
        cancelChequeFile != null;

    print('[createContractorApi] POST $url files=$hasFiles');

    late final http.Response response;
    if (hasFiles) {
      final files = <http.MultipartFile>[];
      for (final f in agreementFiles) {
        files.add(await _multipartImage('agreements[]', f));
      }
      for (final f in documentFiles) {
        files.add(await _multipartImage('documents[]', f));
      }
      if (cancelChequeFile != null) {
        files.add(await _multipartImage('cancel_cheque', cancelChequeFile));
      }
      response = await _sendMultipart(
        Uri.parse(url),
        fields: {
          'site_id': siteId.toString(),
          'name': name,
          'mobile': mobile,
          'address': address,
          'status': status,
          'mason_rate': masonRate.toString(),
          'beldar_rate': beldarRate.toString(),
          'coolie_rate': coolieRate.toString(),
          'mason_over_rate': masonOverRate.toString(),
          'beldar_over_rate': beldarOverRate.toString(),
          'coolie_over_rate': coolieOverRate.toString(),
        },
        files: files,
      );
    } else {
      response = await http
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
    }

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

    final uri = Uri.parse(
      '$baseUrl/api/v1/contractors',
    ).replace(queryParameters: queryParams);

    print('[getContractorListApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getContractorListApi] statusCode: ${response.statusCode}');
    print('[getContractorListApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
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
  List<File> agreementFiles = const [],
  List<File> documentFiles = const [],
  File? cancelChequeFile,
}) async {
  try {
    final uri = Uri.parse('$baseUrl/api/v1/contractors/$contractorId');
    final hasFiles =
        agreementFiles.isNotEmpty ||
        documentFiles.isNotEmpty ||
        cancelChequeFile != null;

    print('[updateContractorApi] ${hasFiles ? 'POST' : 'PUT'} $uri');

    late final http.Response response;
    if (hasFiles) {
      final files = <http.MultipartFile>[];
      for (final f in agreementFiles) {
        files.add(await _multipartImage('agreements[]', f));
      }
      for (final f in documentFiles) {
        files.add(await _multipartImage('documents[]', f));
      }
      if (cancelChequeFile != null) {
        files.add(await _multipartImage('cancel_cheque', cancelChequeFile));
      }
      response = await _sendMultipart(
        uri,
        fields: {
          'name': name,
          'mobile': mobile,
          'address': address,
          'status': status,
          'mason_rate': masonRate.toString(),
          'beldar_rate': beldarRate.toString(),
          'coolie_rate': coolieRate.toString(),
          'mason_over_rate': masonOverRate.toString(),
          'beldar_over_rate': beldarOverRate.toString(),
          'coolie_over_rate': coolieOverRate.toString(),
        },
        files: files,
      );
    } else {
      response = await apiPut(
        uri,
        headers: authHeaders,
        body: jsonEncode({
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
      );
    }

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

Future<bool> deleteContractorApi(BuildContext context, int contractorId) async {
  try {
    final url = '$baseUrl/api/v1/contractors/$contractorId';

    print('[deleteContractorApi] DELETE $url');

    final response = await http
        .delete(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

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
            status:
                (responseData['status']?.toString() ?? status) == 'published'
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

    final response = await apiPut(uri, headers: authHeaders, body: body);

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
Future<bool> deleteItemApi(BuildContext context, int itemId) async {
  try {
    final url = '$baseUrl/api/v1/items/$itemId';

    print('[deleteItemApi] DELETE $url');

    final response = await http
        .delete(Uri.parse(url), headers: authHeaders)
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
  String type = '',
  int perPage = 15,
  int page = 1,
  bool fetchAllPages = false,
}) async {
  try {
    Future<Itemhistorydata?> fetchPage(int pageNo) async {
      final query = <String, String>{
        'per_page': perPage.toString(),
        'page': pageNo.toString(),
      };
      if (type.trim().isNotEmpty) query['type'] = type.trim();

      final uri = Uri.parse(
        '$baseUrl/api/v1/items/$itemId/history',
      ).replace(queryParameters: query);

      debugPrint('[itemHistoryApi] GET $uri');

      final response = await http
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 30));

      debugPrint('[itemHistoryApi] statusCode: ${response.statusCode}');
      debugPrint('[itemHistoryApi] response body: ${response.body}');

      final decoded = decodeApiJson(response.body);
      final apiMessage = decoded?['message']?.toString();

      if (response.statusCode == 200 &&
          decoded != null &&
          decoded['success'] == true) {
        return Itemhistorydata.fromJson(decoded);
      }

      if (context.mounted) {
        message(context, apiMessage ?? 'Failed to load item history.');
      }
      return null;
    }

    final first = await fetchPage(page);
    if (first == null) return null;
    if (!fetchAllPages) return first;

    final allItems = <ItemHistoryRecord>[...(first.data?.items ?? const [])];
    final lastPage = first.data?.pagination?.lastPage ?? 1;

    for (var p = page + 1; p <= lastPage; p++) {
      if (!context.mounted) break;
      final next = await fetchPage(p);
      if (next == null) break;
      allItems.addAll(next.data?.items ?? const []);
    }

    return Itemhistorydata(
      success: first.success,
      message: first.message,
      data: ItemHistoryListData(
        items: allItems,
        pagination: ItemHistoryPagination(
          currentPage: 1,
          lastPage: lastPage,
          perPage: perPage,
          total: allItems.length,
        ),
        item: first.data?.item,
      ),
    );
  } on TimeoutException {
    debugPrint('[itemHistoryApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    debugPrint('[itemHistoryApi] error: $e');
    debugPrint('[itemHistoryApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

Future<bool> createItemHistoryApi(
  BuildContext context, {
  required int itemId,
  required double qty,
  required String date,
  required String issueTo,
  required String remark,
  String type = 'debit',
}) async {
  try {
    final url = '$baseUrl/api/v1/items/$itemId/history';
    final body = <String, dynamic>{
      'qty': qty,
      'type': type,
      'issue_to': issueTo,
      'description': remark,
      if (date.trim().isNotEmpty) 'date': date,
      if (selectedSiteId() != null) 'site_id': selectedSiteId(),
    };

    debugPrint('[createItemHistoryApi] POST $url');
    debugPrint('[createItemHistoryApi] body: $body');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));

    debugPrint('[createItemHistoryApi] statusCode: ${response.statusCode}');
    debugPrint('[createItemHistoryApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 201 || response.statusCode == 200) &&
        decoded != null &&
        decoded['success'] == true) {
      if (context.mounted && apiMessage != null) message(context, apiMessage);
      return true;
    }

    if (context.mounted) {
      message(context, apiMessage ?? 'Failed to save item history.');
    }
    return false;
  } on TimeoutException {
    debugPrint('[createItemHistoryApi] request timed out');
    if (context.mounted)
      message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    debugPrint('[createItemHistoryApi] error: $e');
    debugPrint('[createItemHistoryApi] stack: $stack');
    if (context.mounted) message(context, 'Something went wrong');
    return false;
  }
}

/// GET /api/v1/inbound or /outbound — list stock movements for current site.
Future<List<InwardOutwardRecord>?> inboundOutboundListApi(
  BuildContext context, {
  required String direction, // inbound | outbound
  int perPage = 50,
  int page = 1,
  bool fetchAllPages = true,
}) async {
  assert(direction == 'inbound' || direction == 'outbound');
  try {
    final siteId = selectedSiteId();
    Future<({List<InwardOutwardRecord> items, int lastPage})?> fetchPage(
      int pageNo,
    ) async {
      final query = <String, String>{
        'per_page': perPage.toString(),
        'page': pageNo.toString(),
        if (siteId != null) 'site_id': siteId.toString(),
      };
      final uri = Uri.parse(
        '$baseUrl/api/v1/$direction',
      ).replace(queryParameters: query);
      debugPrint('[inboundOutboundListApi] GET $uri');
      final response = await http
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 30));
      debugPrint('[inboundOutboundListApi] status=${response.statusCode}');
      final decoded = decodeApiJson(response.body);
      final apiMessage = decoded?['message']?.toString();
      if (response.statusCode == 200 &&
          decoded != null &&
          decoded['success'] == true) {
        final data = decoded['data'];
        final rawItems = (data is Map ? data['items'] : null);
        final items = <InwardOutwardRecord>[];
        if (rawItems is List) {
          for (final row in rawItems) {
            if (row is Map) {
              items.add(
                InwardOutwardRecord.fromApi(
                  Map<String, dynamic>.from(row),
                  direction: direction,
                ),
              );
            }
          }
        }
        final pagination = data is Map ? data['pagination'] : null;
        final lastPage = pagination is Map
            ? (pagination['last_page'] as num?)?.toInt() ?? 1
            : 1;
        return (items: items, lastPage: lastPage);
      }
      if (context.mounted) {
        message(context, apiMessage ?? 'Failed to load $direction list.');
      }
      return null;
    }

    final first = await fetchPage(page);
    if (first == null) return null;
    if (!fetchAllPages) return first.items;

    final all = <InwardOutwardRecord>[...first.items];
    for (var p = page + 1; p <= first.lastPage; p++) {
      if (!context.mounted) break;
      final next = await fetchPage(p);
      if (next == null) break;
      all.addAll(next.items);
    }
    return all;
  } on TimeoutException {
    debugPrint('[inboundOutboundListApi] timed out');
    if (context.mounted)
      message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, st) {
    debugPrint('[inboundOutboundListApi] error: $e\n$st');
    if (context.mounted) message(context, 'Something went wrong');
    return null;
  }
}

/// POST /api/v1/inbound or /outbound
Future<InwardOutwardRecord?> createInboundOutboundApi(
  BuildContext context, {
  required String direction, // inbound | outbound
  required int itemId,
  required double qty,
  required String unit,
  String? contractorKey,
  String? remark,
  String? destinationType,
  int? toSiteId,
}) async {
  assert(direction == 'inbound' || direction == 'outbound');
  try {
    final siteId = selectedSiteId();
    final body = <String, dynamic>{
      'item_id': itemId,
      'qty': qty,
      'unit': unit,
      if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
      if (contractorKey != null && contractorKey.isNotEmpty)
        'contractor_key': contractorKey,
      if (destinationType != null) 'destination_type': destinationType,
      if (toSiteId != null) 'to_site_id': toSiteId,
      if (siteId != null) 'site_id': siteId,
    };

    final url = '$baseUrl/api/v1/$direction';
    debugPrint('[createInboundOutboundApi] POST $url');
    debugPrint('[createInboundOutboundApi] body: $body');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));

    debugPrint('[createInboundOutboundApi] status=${response.statusCode}');
    debugPrint('[createInboundOutboundApi] body=${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 201 || response.statusCode == 200) &&
        decoded != null &&
        decoded['success'] == true) {
      final data = decoded['data'];
      final item = data is Map ? data['item'] : null;
      final siteRequest = data is Map ? data['site_request'] : null;
      final msg =
          apiMessage ??
          (siteRequest != null
              ? 'Outbound site request submitted'
              : '$direction submitted');
      if (context.mounted) message(context, msg);
      if (item is Map) {
        return InwardOutwardRecord.fromApi(
          Map<String, dynamic>.from(item),
          direction: direction,
        );
      }
      return InwardOutwardRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: direction == 'outbound'
            ? InwardOutwardType.outward
            : InwardOutwardType.inward,
        itemId: itemId,
        itemName: '',
        qty: qty,
        unit: unit,
        contractorId: null,
        contractorName: '',
        remark: remark ?? '',
        createdAt: DateTime.now(),
        siteId: toSiteId,
      );
    }

    if (context.mounted) {
      message(context, apiMessage ?? 'Failed to submit $direction.');
    }
    return null;
  } on TimeoutException {
    debugPrint('[createInboundOutboundApi] timed out');
    if (context.mounted)
      message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, st) {
    debugPrint('[createInboundOutboundApi] error: $e\n$st');
    if (context.mounted) message(context, 'Something went wrong');
    return null;
  }
}

/// GET /api/v1/outbound-site-requests — requests sent from current site.
Future<List<Map<String, dynamic>>?> outboundSiteRequestsApi(
  BuildContext context, {
  String status = 'all',
  int perPage = 50,
}) async {
  try {
    final siteId = selectedSiteId();
    final uri = Uri.parse('$baseUrl/api/v1/outbound-site-requests').replace(
      queryParameters: {
        'per_page': perPage.toString(),
        'status': status,
        if (siteId != null) 'site_id': siteId.toString(),
      },
    );
    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));
    final decoded = decodeApiJson(response.body);
    if (response.statusCode == 200 && decoded?['success'] == true) {
      final items = decoded?['data']?['items'];
      if (items is! List) return <Map<String, dynamic>>[];
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (context.mounted) {
      message(
        context,
        decoded?['message']?.toString() ?? 'Failed to load requests.',
      );
    }
    return null;
  } catch (e) {
    debugPrint('[outboundSiteRequestsApi] $e');
    if (context.mounted) message(context, 'Something went wrong');
    return null;
  }
}

/// GET /api/v1/outbound-site-receive-requests — incoming for current site.
Future<List<Map<String, dynamic>>?> outboundSiteReceiveRequestsApi(
  BuildContext context, {
  String? status,
  int perPage = 50,
}) async {
  try {
    final siteId = selectedSiteId();
    final uri = Uri.parse('$baseUrl/api/v1/outbound-site-receive-requests')
        .replace(
          queryParameters: {
            'per_page': perPage.toString(),
            if (status != null) 'status': status,
            if (siteId != null) 'site_id': siteId.toString(),
          },
        );
    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));
    final decoded = decodeApiJson(response.body);
    if (response.statusCode == 200 && decoded?['success'] == true) {
      final items = decoded?['data']?['items'];
      if (items is! List) return <Map<String, dynamic>>[];
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (context.mounted) {
      message(
        context,
        decoded?['message']?.toString() ?? 'Failed to load receive requests.',
      );
    }
    return null;
  } catch (e) {
    debugPrint('[outboundSiteReceiveRequestsApi] $e');
    if (context.mounted) message(context, 'Something went wrong');
    return null;
  }
}

Future<bool> acceptOutboundSiteReceiveRequestApi(
  BuildContext context, {
  required int id,
  String? reviewNote,
}) async {
  return _reviewOutboundSiteReceiveRequestApi(
    context,
    id: id,
    action: 'accept',
    reviewNote: reviewNote,
  );
}

Future<bool> rejectOutboundSiteReceiveRequestApi(
  BuildContext context, {
  required int id,
  String? reviewNote,
}) async {
  return _reviewOutboundSiteReceiveRequestApi(
    context,
    id: id,
    action: 'reject',
    reviewNote: reviewNote,
  );
}

Future<bool> _reviewOutboundSiteReceiveRequestApi(
  BuildContext context, {
  required int id,
  required String action,
  String? reviewNote,
}) async {
  try {
    final siteId = selectedSiteId();
    final url = '$baseUrl/api/v1/outbound-site-receive-requests/$id/$action';
    final body = <String, dynamic>{
      if (reviewNote != null && reviewNote.trim().isNotEmpty)
        'review_note': reviewNote.trim(),
      if (siteId != null) 'site_id': siteId,
    };
    final response = await http
        .post(Uri.parse(url), headers: authHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();
    if (response.statusCode == 200 && decoded?['success'] == true) {
      if (context.mounted && apiMessage != null) message(context, apiMessage);
      return true;
    }
    if (context.mounted) {
      message(context, apiMessage ?? 'Failed to $action receive request.');
    }
    return false;
  } catch (e) {
    debugPrint('[reviewOutboundSiteReceiveRequestApi] $e');
    if (context.mounted) message(context, 'Something went wrong');
    return false;
  }
}

Future<List<Map<String, dynamic>>?> getEmployeeRolesApi(
  BuildContext context,
) async {
  try {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/v1/roles?per_page=100'),
          headers: authHeaders,
        )
        .timeout(const Duration(seconds: 30));
    final json = decodeApiJson(response.body);
    final items = json?['data']?['items'];

    if (response.statusCode == 200 && items is List) {
      return items.whereType<Map<String, dynamic>>().toList();
    }

    if (context.mounted) {
      message(context, json?['message']?.toString() ?? 'Failed to load roles.');
    }
    return null;
  } catch (e) {
    debugPrint('[getEmployeeRolesApi] $e');
    if (context.mounted) message(context, 'Failed to load roles.');
    return null;
  }
}

// createemployeeapi
Future<bool> createEmployeeApi(
  BuildContext context, {
  required int siteId,
  required int roleId,
  required String firstName,
  required String lastName,
  required String email,
  required String mobile,
  required String password,
  required String passwordConfirmation,
  required String designation,
  required String dateOfJoin,
  String? dateOfSuspended,
  String? monthlySalary,
  String? leaveAllocation,
  required bool attendanceAllow,
  required String status,
  List<int> accessRoleIds = const [],
  List<int> siteIds = const [],
}) async {
  try {
    final url = '$baseUrl/api/v1/employees';

    print('[createEmployeeApi] POST $url');
    print('[createEmployeeApi] siteId: $siteId');

    final body = <String, dynamic>{
      'site_id': siteId,
      'role_id': roleId,
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
      'access_roles': List<int>.from(accessRoleIds),
      'site_ids': List<int>.from(siteIds),
    };
    if (dateOfSuspended != null && dateOfSuspended.isNotEmpty) {
      body['date_of_suspended'] = dateOfSuspended;
    }
    if (monthlySalary != null && monthlySalary.isNotEmpty) {
      body['monthly_salary'] = monthlySalary;
    }
    if (leaveAllocation != null && leaveAllocation.isNotEmpty) {
      body['leave_allocation'] = leaveAllocation;
    }

    final encoded = jsonEncode(body);
    print('[createEmployeeApi] body: $encoded');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders, body: encoded)
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
  int perPage = 15,
  int page = 1,
  bool fetchAllPages = false,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      return null;
    }

    Future<Getemployeesmodal?> fetchPage(int pageNo) async {
      final queryParams = <String, String>{
        'site_id': resolvedSiteId.toString(),
        'per_page': perPage.toString(),
        'page': pageNo.toString(),
      };
      if (search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse(
        '$baseUrl/api/v1/employees',
      ).replace(queryParameters: queryParams);

      debugPrint('[getEmployeesApi] GET $uri');

      final response = await http
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 30));

      debugPrint('[getEmployeesApi] statusCode: ${response.statusCode}');
      debugPrint('[getEmployeesApi] response body: ${response.body}');

      final decoded = decodeApiJson(response.body);
      final apiMessage = decoded?['message']?.toString();

      if (response.statusCode == 200 &&
          decoded != null &&
          decoded['success'] == true) {
        return Getemployeesmodal.fromJson(decoded);
      }

      if (context.mounted) {
        message(context, apiMessage ?? 'Failed to load employees.');
      }
      return null;
    }

    final first = await fetchPage(page);
    if (first == null) return null;
    if (!fetchAllPages) return first;

    final allItems = <EmployeeListItem>[...(first.data?.items ?? const [])];
    final lastPage = first.data?.pagination?.lastPage ?? 1;

    for (var p = page + 1; p <= lastPage; p++) {
      if (!context.mounted) break;
      final next = await fetchPage(p);
      if (next == null) break;
      allItems.addAll(next.data?.items ?? const []);
    }

    return Getemployeesmodal(
      success: first.success,
      message: first.message,
      data: EmployeeListData(
        items: allItems,
        pagination: EmployeeListPagination(
          currentPage: 1,
          lastPage: lastPage,
          perPage: perPage,
          total: allItems.length,
        ),
      ),
    );
  } on TimeoutException {
    debugPrint('[getEmployeesApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    debugPrint('[getEmployeesApi] error: $e');
    debugPrint('[getEmployeesApi] stack: $stack');
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
  String? monthlySalary,
  String? leaveAllocation,
  String? password,
  String? passwordConfirmation,
  required bool attendanceAllow,
  required String status,
  required int roleId,
  List<int> accessRoleIds = const [],
  List<int>? siteIds,
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
      'role_id': roleId,
      'access_roles': List<int>.from(accessRoleIds),
    };
    if (siteIds != null) {
      body['site_ids'] = List<int>.from(siteIds);
    }
    if (dateOfSuspended != null && dateOfSuspended.isNotEmpty) {
      body['date_of_suspended'] = dateOfSuspended;
    }
    if (monthlySalary != null) {
      body['monthly_salary'] = monthlySalary;
    }
    if (leaveAllocation != null) {
      body['leave_allocation'] = leaveAllocation;
    }
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
      body['password_confirmation'] = passwordConfirmation ?? password;
    }

    print('[updateEmployeeApi] PUT $uri');
    print('[updateEmployeeApi] employeeId: $employeeId');

    final encoded = jsonEncode(body);
    print('[updateEmployeeApi] body: $encoded');

    final response = await apiPut(
      uri,
      headers: authHeaders,
      body: encoded,
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
Future<bool> deleteEmployeeApi(BuildContext context, int employeeId) async {
  try {
    final url = '$baseUrl/api/v1/employees/$employeeId';

    print('[deleteEmployeeApi] DELETE $url');

    final response = await http
        .delete(Uri.parse(url), headers: authHeaders)
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

    final uri = Uri.parse(
      '$baseUrl/api/v1/tasks',
    ).replace(queryParameters: queryParams);

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
        .post(Uri.parse(url), headers: authHeaders, body: jsonEncode(body))
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
    final body = <String, dynamic>{'status': status};

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
        .delete(Uri.parse(url), headers: authHeaders)
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

    final uri = Uri.parse(
      '$baseUrl/api/v1/activities',
    ).replace(queryParameters: queryParams);

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

    final uri = Uri.parse(
      '$baseUrl/api/v1/activities/$activityId',
    ).replace(queryParameters: {'site_id': resolvedSiteId.toString()});

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
    final uri = Uri.parse(
      '$baseUrl/api/v1/tasks/$taskId/messages',
    ).replace(queryParameters: {'per_page': perPage.toString()});

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
        .post(Uri.parse(url), headers: authHeaders, body: jsonEncode(body))
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
  int perPage = 15,
  int page = 1,
  bool fetchAllPages = false,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    Future<ExpensesListResponse?> fetchPage(int pageNo) async {
      final queryParams = <String, String>{
        'site_id': resolvedSiteId.toString(),
        'period': period,
        'per_page': perPage.toString(),
        'page': pageNo.toString(),
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

      final uri = Uri.parse(
        '$baseUrl/api/v1/expenses',
      ).replace(queryParameters: queryParams);

      debugPrint('[getExpensesApi] GET $uri');

      final response = await http
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 30));

      debugPrint('[getExpensesApi] statusCode: ${response.statusCode}');
      debugPrint('[getExpensesApi] response body: ${response.body}');

      final decoded = decodeApiJson(response.body);
      final apiMessage = decoded?['message']?.toString();

      if (response.statusCode == 200 &&
          decoded != null &&
          decoded['success'] == true) {
        return ExpensesListResponse.fromJson(decoded);
      }

      if (context.mounted) {
        message(context, apiMessage ?? 'Failed to load expenses.');
      }
      return null;
    }

    final first = await fetchPage(page);
    if (first == null) return null;
    if (!fetchAllPages) return first;

    final allItems = <Expense>[...(first.data?.items ?? const [])];
    final lastPage = first.data?.pagination?.lastPage ?? 1;

    for (var p = page + 1; p <= lastPage; p++) {
      if (!context.mounted) break;
      final next = await fetchPage(p);
      if (next == null) break;
      allItems.addAll(next.data?.items ?? const []);
    }

    return ExpensesListResponse(
      success: first.success,
      message: first.message,
      data: ExpensesListData(
        items: allItems,
        pagination: PaginationModel(
          currentPage: 1,
          lastPage: lastPage,
          perPage: perPage,
          total: allItems.length,
        ),
        totalAmount: first.data?.totalAmount ?? 0,
      ),
    );
  } on TimeoutException {
    debugPrint('[getExpensesApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    debugPrint('[getExpensesApi] error: $e');
    debugPrint('[getExpensesApi] stack: $stack');
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
        .post(Uri.parse(url), headers: authHeaders, body: jsonEncode(body))
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
        .delete(Uri.parse(url), headers: authHeaders)
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
  Duration timeout = const Duration(seconds: 60),
}) async {
  final request = http.MultipartRequest('POST', uri);
  request.headers.addAll(authHeadersMultipart);
  request.fields.addAll(fields);
  request.files.addAll(files);
  final streamed = await request.send().timeout(timeout);
  return http.Response.fromStream(streamed).timeout(timeout);
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

/// [asArray] true: every file as `field[]` (create + step 2).
/// [asArray] false: first file as `field`, extras as `fields[]` (step 3 file validation).
Future<List<http.MultipartFile>> _multipartPurchaseImages({
  required String field,
  required List<File> files,
  bool asArray = true,
}) async {
  if (files.isEmpty) return const [];
  if (asArray) {
    final arrayField = field.endsWith('[]') ? field : '$field[]';
    return [
      for (final file in files) await _multipartImage(arrayField, file),
    ];
  }

  final extrasField = field.endsWith('_image') ? '${field}s[]' : '$field[]';
  // Required file field plus the full gallery array (including the first photo).
  final uploads = <http.MultipartFile>[
    await _multipartImage(field, files.first),
  ];
  for (final file in files) {
    uploads.add(await _multipartImage(extrasField, file));
  }
  return uploads;
}

Future<http.MultipartFile> _multipartChatMedia(
  File file, {
  required String fallbackName,
  required MediaType contentType,
}) async {
  final filename = file.path.split(Platform.pathSeparator).last;
  final length = await file.length();
  if (length <= 0) {
    throw StateError('Media file is empty: ${file.path}');
  }
  // Stream from disk (better for large videos than loading all bytes).
  return http.MultipartFile.fromPath(
    'media',
    file.path,
    filename: filename.isEmpty ? fallbackName : filename,
    contentType: contentType,
  );
}

/// Result of chat photo/video upload.
class ChatMediaSendResult {
  const ChatMediaSendResult({
    required this.success,
    this.messageId,
    this.mediaPath,
    this.isVideo = false,
    this.mediaDuration,
    this.errorMessage,
  });

  final bool success;
  final String? messageId;
  final String? mediaPath;
  final bool isVideo;
  final int? mediaDuration;
  final String? errorMessage;

  bool get hasServerMedia {
    final path = mediaPath?.trim();
    return path != null && path.isNotEmpty && path != 'null';
  }
}

ChatMediaSendResult _parseChatMediaSendResponse(http.Response response) {
  if (response.statusCode != 200 && response.statusCode != 201) {
    return ChatMediaSendResult(
      success: false,
      errorMessage: 'HTTP ${response.statusCode}',
    );
  }

  if (response.body.trim().isEmpty) {
    return const ChatMediaSendResult(success: true);
  }

  try {
    final jsonData = jsonDecode(response.body);
    if (jsonData is! Map<String, dynamic>) {
      return const ChatMediaSendResult(success: true);
    }
    if (jsonData['success'] == false) {
      return ChatMediaSendResult(
        success: false,
        errorMessage: jsonData['message']?.toString(),
      );
    }

    final data = jsonData['data'];
    if (data is Map<String, dynamic>) {
      final rawUrl = data['media_url']?.toString().trim();
      final rawPath = data['media_path']?.toString().trim();
      final path = () {
        if (rawUrl != null && rawUrl.isNotEmpty && rawUrl != 'null') {
          return rawUrl;
        }
        if (rawPath == null || rawPath.isEmpty || rawPath == 'null') {
          return null;
        }
        return rawPath;
      }();
      final durationRaw = data['media_duration'];
      int? duration;
      if (durationRaw is int) {
        duration = durationRaw;
      } else if (durationRaw != null) {
        duration = int.tryParse('$durationRaw');
      }

      final type = data['type']?.toString().toLowerCase();
      return ChatMediaSendResult(
        success: true,
        messageId: data['id']?.toString(),
        mediaPath: path,
        isVideo: data['is_video'] == true || type == 'video',
        mediaDuration: duration,
      );
    }

    return ChatMediaSendResult(
      success: jsonData['success'] == true || data != null,
    );
  } catch (e) {
    return ChatMediaSendResult(success: false, errorMessage: e.toString());
  }
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
  String? startDate,
  String? endDate,
  int perPage = 15,
  int page = 1,
  bool fetchAllPages = false,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    Future<PurchasesListResponse?> fetchPage(int pageNo) async {
      final queryParams = <String, String>{
        'site_id': resolvedSiteId.toString(),
        'period': period,
        'per_page': perPage.toString(),
        'page': pageNo.toString(),
        'status': status?.trim() ?? '',
        'flow_type': flowType?.trim() ?? '',
        'search': search.trim(),
        if (startDate != null && startDate.trim().isNotEmpty)
          'start_date': startDate.trim(),
        if (endDate != null && endDate.trim().isNotEmpty)
          'end_date': endDate.trim(),
      };

      final uri = Uri.parse(
        '$baseUrl/api/v1/purchases',
      ).replace(queryParameters: queryParams);

      debugPrint('[getPurchasesApi] GET $uri');

      final response = await http
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 30));

      debugPrint('[getPurchasesApi] statusCode: ${response.statusCode}');
      debugPrint('[getPurchasesApi] response body: ${response.body}');

      final decoded = decodeApiJson(response.body);
      final apiMessage = decoded?['message']?.toString();

      if (response.statusCode == 200 &&
          decoded != null &&
          decoded['success'] == true) {
        return PurchasesListResponse.fromJson(decoded);
      }

      if (context.mounted) {
        message(context, apiMessage ?? 'Failed to load purchases.');
      }
      return null;
    }

    final first = await fetchPage(page);
    if (first == null) return null;
    if (!fetchAllPages) return first;

    final allItems = <Purchase>[...(first.data?.items ?? const [])];
    final lastPage = first.data?.pagination?.lastPage ?? 1;

    for (var p = page + 1; p <= lastPage; p++) {
      if (!context.mounted) break;
      final next = await fetchPage(p);
      if (next == null) break;
      allItems.addAll(next.data?.items ?? const []);
    }

    return PurchasesListResponse(
      success: first.success,
      message: first.message,
      data: PurchasesListData(
        items: allItems,
        pagination: PurchasesPagination(
          currentPage: 1,
          lastPage: lastPage,
          perPage: perPage,
          total: allItems.length,
        ),
        summary: first.data?.summary,
      ),
    );
  } on TimeoutException {
    debugPrint('[getPurchasesApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    debugPrint('[getPurchasesApi] error: $e');
    debugPrint('[getPurchasesApi] stack: $stack');
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
        .delete(Uri.parse(url), headers: authHeaders)
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

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'per_page': perPage.toString(),
      'date': date?.trim() ?? '',
      'status': status?.trim() ?? '',
      'search': search.trim(),
    };

    final uri = Uri.parse(
      '$baseUrl/api/v1/attendances',
    ).replace(queryParameters: queryParams);

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

    if (!showErrors || !context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load attendances.');
    return null;
  } on TimeoutException {
    print('[getAttendancesApi] request timed out');
    if (!showErrors || !context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getAttendancesApi] error: $e');
    print('[getAttendancesApi] stack: $stack');
    if (!showErrors || !context.mounted) return null;
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

    final uri = Uri.parse(
      '$baseUrl/api/v1/attendances/today',
    ).replace(queryParameters: {'site_id': resolvedSiteId.toString()});

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

    final response = await _sendMultipart(Uri.parse(url), fields: fields);

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
        .post(Uri.parse(url), headers: authHeaders, body: jsonEncode(body))
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
Future<Attendance?> getAttendanceApi(
  BuildContext context,
  int attendanceId,
) async {
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
  required List<File> imageFiles,
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

    final files = await _multipartPurchaseImages(
      field: normalizedFlow == 'direct' ? 'image' : 'loading_image',
      files: imageFiles,
    );

    print('[createPurchaseApi] POST $url');
    print('[createPurchaseApi] fields: $fields');
    print('[createPurchaseApi] loading_image[] count=${imageFiles.length}');

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
  required List<File> unloadingImages,
}) async {
  try {
    final url = '$baseUrl/api/v1/purchases/$purchaseId/step-2';
    final fields = <String, String>{'vehicle_no': vehicleNo.trim()};
    final files = await _multipartPurchaseImages(
      field: 'unloading_image',
      files: unloadingImages,
    );

    print('[purchaseStep2WithKantaApi] POST $url');
    print('[purchaseStep2WithKantaApi] fields: $fields');
    print('[purchaseStep2WithKantaApi] unloading_image[] count=${unloadingImages.length}');

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
  required List<File> unloadingImages,
}) async {
  try {
    final url = '$baseUrl/api/v1/purchases/$purchaseId/step-2';
    final fields = <String, String>{'invoice_no': invoiceNo.trim()};
    if (remark != null && remark.trim().isNotEmpty) {
      fields['remark'] = remark.trim();
    }
    for (var i = 0; i < materials.length; i++) {
      final m = materials[i];
      fields['materials[$i][item_id]'] = m.itemId.toString();
      fields['materials[$i][qty]'] = m.qty.toString();
      fields['materials[$i][unit]'] = m.unit;
    }

    final files = await _multipartPurchaseImages(
      field: 'unloading_image',
      files: unloadingImages,
    );

    print('[purchaseStep2WithoutKantaApi] POST $url');
    print('[purchaseStep2WithoutKantaApi] fields: $fields');
    print('[purchaseStep2WithoutKantaApi] unloading_image[] count=${unloadingImages.length}');

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
  String? invoiceNo,
  required String kantaNo,
  String? remark,
  required List<PurchaseMaterialPayload> materials,
  required List<File> kantaSlipImages,
  required List<File> vehicleAtKantaImages,
}) async {
  try {
    final url = '$baseUrl/api/v1/purchases/$purchaseId/step-3';
    final fields = <String, String>{'kanta_no': kantaNo.trim()};
    final trimmedInvoice = invoiceNo?.trim();
    if (trimmedInvoice != null && trimmedInvoice.isNotEmpty) {
      fields['invoice_no'] = trimmedInvoice;
    }
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
      ...await _multipartPurchaseImages(
        field: 'kanta_slip_image',
        files: kantaSlipImages,
        asArray: false,
      ),
      ...await _multipartPurchaseImages(
        field: 'vehicle_at_kanta_image',
        files: vehicleAtKantaImages,
        asArray: false,
      ),
    ];

    print('[purchaseStep3WithKantaApi] POST $url');
    print('[purchaseStep3WithKantaApi] fields: $fields');
    print('[purchaseStep3WithKantaApi] kanta_slip_image count=${kantaSlipImages.length}');
    print('[purchaseStep3WithKantaApi] vehicle_at_kanta_image count=${vehicleAtKantaImages.length}');
    print('[purchaseStep3WithKantaApi] multipart fields: ${files.map((f) => f.field).toList()}');

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
    message(context, 'Something went wrong: $e');
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
        .post(Uri.parse(url), headers: authHeaders, body: jsonEncode(body))
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

//getchatlistapi

Future<Getchatlistmodaldata?> getChatListApi({
  int perPage = 50,
  String search = '',
}) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    if (token.isEmpty) {
      debugPrint('Get Chat List API : missing token');
      return null;
    }

    final uri = Uri.parse('$baseUrl/api/v1/chat/users').replace(
      queryParameters: {
        'per_page': '$perPage',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    debugPrint('Get Chat List API : ${response.request?.url}');
    debugPrint('Status Code : ${response.statusCode}');
    debugPrint('Response : ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is Map<String, dynamic> && jsonData['success'] == true) {
        return Getchatlistmodaldata.fromJson(jsonData);
      }
    }
  } catch (e, st) {
    debugPrint('Get Chat List API Error : $e\n$st');
  }

  return null;
}

//getchatthreadlistapi

Future<Getchatthreadlistmodal?> getChatThreadListApi({
  int perPage = 30,
  String type = '',
  String search = '',
}) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    if (token.isEmpty) {
      debugPrint('Get Chat Thread List API : missing token');
      return null;
    }

    final uri = Uri.parse('$baseUrl/api/v1/chat/threads').replace(
      queryParameters: {
        'per_page': '$perPage',
        if (type.trim().isNotEmpty) 'type': type.trim(),
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    debugPrint('Get Chat Thread List API : ${response.request?.url}');
    debugPrint('Status Code : ${response.statusCode}');
    debugPrint('Response : ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is Map<String, dynamic> && jsonData['success'] == true) {
        return Getchatthreadlistmodal.fromJson(jsonData);
      }
    }
  } catch (e, st) {
    debugPrint('Get Chat Thread List API Error : $e\n$st');
  }

  return null;
}

//creategroupchatapi

class CreateGroupApiResult {
  const CreateGroupApiResult({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? data;
}

Future<CreateGroupApiResult> createGroupApi({
  required String name,
  required String description,
  required List<int> memberIds,
  required int groupAvatarColor,
}) async {
  final requestBody = {
    'name': name,
    'description': description,
    'member_ids': memberIds,
    'group_avatar_color': groupAvatarColor,
  };

  try {
    final token = Preference.pref.getString('token') ?? '';
    if (token.isEmpty) {
      debugPrint('Create Group API : missing token');
      return const CreateGroupApiResult(
        success: false,
        message: 'Not authenticated. Please login again.',
      );
    }

    final uri = Uri.parse('$baseUrl/api/v1/chat/groups');
    debugPrint('Create Group API Request URL : $uri');
    debugPrint('Create Group API Request Body : ${jsonEncode(requestBody)}');

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    debugPrint('Create Group API Status Code : ${response.statusCode}');
    debugPrint('Create Group API Response : ${response.body}');

    Map<String, dynamic>? jsonData;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) jsonData = decoded;
    } catch (_) {}

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (jsonData?['success'] == true) {
        final data = jsonData!['data'];
        return CreateGroupApiResult(
          success: true,
          message:
              jsonData['message']?.toString() ?? 'Group created successfully.',
          data: data is Map<String, dynamic>
              ? data
              : (data is Map ? Map<String, dynamic>.from(data) : null),
        );
      }
      return CreateGroupApiResult(
        success: false,
        message: jsonData?['message']?.toString() ?? 'Failed to create group.',
        data: jsonData,
      );
    }

    return CreateGroupApiResult(
      success: false,
      message:
          jsonData?['message']?.toString() ??
          'Failed to create group (${response.statusCode}).',
      data: jsonData,
    );
  } catch (e, st) {
    debugPrint('Create Group API Error : $e\n$st');
    return const CreateGroupApiResult(
      success: false,
      message: 'Something went wrong. Please try again.',
    );
  }
}

//DELETEGROUPAPI

class DeleteGroupApiResult {
  const DeleteGroupApiResult({required this.success, required this.message});

  final bool success;
  final String message;
}

Future<DeleteGroupApiResult> deleteGroupApi({
  required String chatThreadId,
}) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    if (token.isEmpty) {
      debugPrint('Delete Group API : missing token');
      return const DeleteGroupApiResult(
        success: false,
        message: 'Not authenticated. Please login again.',
      );
    }

    final uri = Uri.parse('$baseUrl/api/v1/chat/groups/$chatThreadId');
    debugPrint('Delete Group API Request URL : $uri');

    final response = await http.delete(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    debugPrint('Delete Group API Status Code : ${response.statusCode}');
    debugPrint('Delete Group API Response : ${response.body}');

    Map<String, dynamic>? jsonData;
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) jsonData = decoded;
      } catch (_) {}
    }

    final okStatus = response.statusCode == 200 || response.statusCode == 204;
    final okFlag = jsonData == null || jsonData['success'] == true;

    if (okStatus && okFlag) {
      return DeleteGroupApiResult(
        success: true,
        message:
            jsonData?['message']?.toString() ?? 'Group deleted successfully.',
      );
    }

    return DeleteGroupApiResult(
      success: false,
      message:
          jsonData?['message']?.toString() ??
          'Failed to delete group (${response.statusCode}).',
    );
  } catch (e, st) {
    debugPrint('Delete Group API Error : $e\n$st');
    return const DeleteGroupApiResult(
      success: false,
      message: 'Something went wrong. Please try again.',
    );
  }
}

//LEAVEGROUPAPI

class LeaveGroupApiResult {
  const LeaveGroupApiResult({required this.success, required this.message});

  final bool success;
  final String message;
}

Future<LeaveGroupApiResult> leaveGroupApi({
  required String chatThreadId,
}) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    if (token.isEmpty) {
      debugPrint('Leave Group API : missing token');
      return const LeaveGroupApiResult(
        success: false,
        message: 'Not authenticated. Please login again.',
      );
    }

    final uri = Uri.parse('$baseUrl/api/v1/chat/groups/$chatThreadId/leave');
    debugPrint('Leave Group API Request URL : $uri');

    final response = await http.post(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    debugPrint('Leave Group API Status Code : ${response.statusCode}');
    debugPrint('Leave Group API Response : ${response.body}');

    Map<String, dynamic>? jsonData;
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) jsonData = decoded;
      } catch (_) {}
    }

    final okStatus = response.statusCode == 200 || response.statusCode == 201;
    final okFlag = jsonData == null || jsonData['success'] == true;

    if (okStatus && okFlag) {
      return LeaveGroupApiResult(
        success: true,
        message: jsonData?['message']?.toString() ?? 'Left group successfully.',
      );
    }

    return LeaveGroupApiResult(
      success: false,
      message:
          jsonData?['message']?.toString() ??
          'Failed to leave group (${response.statusCode}).',
    );
  } catch (e, st) {
    debugPrint('Leave Group API Error : $e\n$st');
    return const LeaveGroupApiResult(
      success: false,
      message: 'Something went wrong. Please try again.',
    );
  }
}

//REMOVEGROUPMEMBERAPI

class RemoveGroupMemberApiResult {
  const RemoveGroupMemberApiResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

Future<RemoveGroupMemberApiResult> removeGroupMemberApi({
  required String chatThreadId,
  required int memberId,
}) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    if (token.isEmpty) {
      debugPrint('Remove Group Member API : missing token');
      return const RemoveGroupMemberApiResult(
        success: false,
        message: 'Not authenticated. Please login again.',
      );
    }

    final uri = Uri.parse(
      '$baseUrl/api/v1/chat/groups/$chatThreadId/members/$memberId',
    );
    debugPrint('Remove Group Member API Request URL : $uri');

    final response = await http.delete(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    debugPrint('Remove Group Member API Status Code : ${response.statusCode}');
    debugPrint('Remove Group Member API Response : ${response.body}');

    Map<String, dynamic>? jsonData;
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) jsonData = decoded;
      } catch (_) {}
    }

    final okStatus = response.statusCode == 200 || response.statusCode == 204;
    final okFlag = jsonData == null || jsonData['success'] == true;

    if (okStatus && okFlag) {
      return RemoveGroupMemberApiResult(
        success: true,
        message:
            jsonData?['message']?.toString() ?? 'Member removed successfully.',
      );
    }

    return RemoveGroupMemberApiResult(
      success: false,
      message:
          jsonData?['message']?.toString() ??
          'Failed to remove member (${response.statusCode}).',
    );
  } catch (e, st) {
    debugPrint('Remove Group Member API Error : $e\n$st');
    return const RemoveGroupMemberApiResult(
      success: false,
      message: 'Something went wrong. Please try again.',
    );
  }
}

//ADDGROUPMEMBERAPI

class AddGroupMembersApiResult {
  const AddGroupMembersApiResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

Future<AddGroupMembersApiResult> addGroupMembersApi({
  required String chatThreadId,
  required List<int> memberIds,
}) async {
  final requestBody = {'member_ids': memberIds};

  try {
    final token = Preference.pref.getString('token') ?? '';
    if (token.isEmpty) {
      debugPrint('Add Group Members API : missing token');
      return const AddGroupMembersApiResult(
        success: false,
        message: 'Not authenticated. Please login again.',
      );
    }

    final uri = Uri.parse('$baseUrl/api/v1/chat/groups/$chatThreadId/members');
    debugPrint('Add Group Members API Request URL : $uri');
    debugPrint(
      'Add Group Members API Request Body : ${jsonEncode(requestBody)}',
    );

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    debugPrint('Add Group Members API Status Code : ${response.statusCode}');
    debugPrint('Add Group Members API Response : ${response.body}');

    Map<String, dynamic>? jsonData;
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) jsonData = decoded;
      } catch (_) {}
    }

    final okStatus = response.statusCode == 200 || response.statusCode == 201;
    final okFlag = jsonData == null || jsonData['success'] == true;

    if (okStatus && okFlag) {
      return AddGroupMembersApiResult(
        success: true,
        message:
            jsonData?['message']?.toString() ?? 'Members added successfully.',
      );
    }

    return AddGroupMembersApiResult(
      success: false,
      message:
          jsonData?['message']?.toString() ??
          'Failed to add members (${response.statusCode}).',
    );
  } catch (e, st) {
    debugPrint('Add Group Members API Error : $e\n$st');
    return const AddGroupMembersApiResult(
      success: false,
      message: 'Something went wrong. Please try again.',
    );
  }
}

//Markthreadreadapi

Future<bool> markThreadReadApi({required String chatThreadId}) async {
  try {
    final token = Preference.pref.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/chat/threads/$chatThreadId/read'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    debugPrint('Mark Thread Read API : ${response.request?.url}');
    debugPrint('Status Code : ${response.statusCode}');
    debugPrint('Response : ${response.body}');

    final jsonData = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        jsonData['success'] == true) {
      return true;
    }
  } catch (e) {
    debugPrint('Mark Thread Read API Error : $e');
  }

  return false;
}

//sendMessageApi

Future<bool> sendMessageApi({
  required String chatThreadId,
  required String message,
}) async {
  try {
    final token = Preference.pref.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/chat/threads/$chatThreadId/messages'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': message}),
    );

    debugPrint('Send Message API : ${response.request?.url}');
    debugPrint('Status Code : ${response.statusCode}');
    debugPrint('Response : ${response.body}');

    final jsonData = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        jsonData['success'] == true) {
      return true;
    }
  } catch (e) {
    debugPrint('Send Message API Error : $e');
  }

  return false;
}

//getlistmessagesapi
Future<Getlistmessagemodal?> getListMessageApi({
  required String chatThreadId,
  int perPage = 50,
}) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    final url =
        '$baseUrl/api/v1/chat/threads/$chatThreadId/messages?per_page=$perPage';

    debugPrint('=========== Get List Messages API ===========');
    debugPrint('URL : $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    debugPrint('Status Code : ${response.statusCode}');
    debugPrint('Response : ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is Map<String, dynamic>) {
        return Getlistmessagemodal.fromJson(jsonData);
      }
    }
  } catch (e) {
    debugPrint('Get List Messages Exception : $e');
  }
  return null;
}

//showthreadapi
Future<Showthreadmodaldata?> showThreadApi(String threadId) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    final url = '$baseUrl/api/v1/chat/threads/$threadId';

    debugPrint('=========== Show Thread API ===========');
    debugPrint('URL : $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    debugPrint('Status Code : ${response.statusCode}');
    debugPrint('Response : ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is Map<String, dynamic>) {
        return Showthreadmodaldata.fromJson(jsonData);
      }
    }
  } catch (e) {
    debugPrint('Show Thread Exception : $e');
  }
  return null;
}

//createopendirectapi
Future<Createopendirectmodaldata?> createOpenDirectApi(int userId) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    final url = '$baseUrl/api/v1/chat/threads/direct';
    final body = {'user_id': userId};

    debugPrint('=========== Create/Open Direct API ===========');
    debugPrint('URL : $url');
    debugPrint('Request : ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    debugPrint('Status Code : ${response.statusCode}');
    debugPrint('Response : ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is Map<String, dynamic>) {
        return Createopendirectmodaldata.fromJson(jsonData);
      }
    }
  } catch (e) {
    debugPrint('Create/Open Direct API Exception : $e');
  }
  return null;
}

//sendvideomessageapi
Future<ChatMediaSendResult> sendVideoMessageApi({
  required String threadId,
  required String text,
  required String mediaDuration,
  required File videoFile,
}) async {
  try {
    if (!await videoFile.exists()) {
      debugPrint('sendVideoMessageApi: file missing at ${videoFile.path}');
      return const ChatMediaSendResult(
        success: false,
        errorMessage: 'Video file missing',
      );
    }

    final fileSize = await videoFile.length();
    debugPrint('=========== Send Video Message API ===========');
    debugPrint('File : ${videoFile.path}');
    debugPrint('Size : $fileSize bytes');
    debugPrint('Duration : $mediaDuration');

    if (fileSize <= 0) {
      return const ChatMediaSendResult(
        success: false,
        errorMessage: 'Empty video file',
      );
    }

    final uri = Uri.parse('$baseUrl/api/v1/chat/threads/$threadId/messages');
    final media = await _multipartChatMedia(
      videoFile,
      fallbackName: 'video.mp4',
      contentType: MediaType('video', 'mp4'),
    );

    final caption = text.trim().isEmpty ? 'Video' : text.trim();

    final response = await _sendMultipart(
      uri,
      fields: {
        'type': 'video',
        'text': caption,
        'media_duration': mediaDuration,
      },
      files: [media],
      timeout: const Duration(seconds: 120),
    );

    debugPrint('Send Video Status : ${response.statusCode}');
    debugPrint('Send Video Response : ${response.body}');

    final result = _parseChatMediaSendResponse(response);
    if (result.success && !result.hasServerMedia) {
      debugPrint(
        'sendVideoMessageApi WARNING: server saved message but media_path '
        'is null / is_video=${result.isVideo}. Backend is not storing the upload '
        '(check PHP upload_max_filesize / post_max_size / media disk).',
      );
      return ChatMediaSendResult(
        success: false,
        messageId: result.messageId,
        mediaDuration: result.mediaDuration,
        isVideo: result.isVideo,
        errorMessage:
            'Server did not save video file (media_path is null). Ask backend to fix media upload storage.',
      );
    }
    return result;
  } catch (e, st) {
    debugPrint('sendVideoMessageApi Error : $e');
    debugPrint('$st');
    return ChatMediaSendResult(success: false, errorMessage: '$e');
  }
}

//sendphotomessageapi
Future<ChatMediaSendResult> sendPhotoMessageApi({
  required String threadId,
  required String text,
  required File photoFile,
}) async {
  try {
    if (!await photoFile.exists()) {
      debugPrint('sendPhotoMessageApi: file missing at ${photoFile.path}');
      return const ChatMediaSendResult(
        success: false,
        errorMessage: 'Photo file missing',
      );
    }

    final fileSize = await photoFile.length();
    debugPrint('=========== Send Photo Message API ===========');
    debugPrint('File : ${photoFile.path}');
    debugPrint('Size : $fileSize bytes');

    if (fileSize <= 0) {
      return const ChatMediaSendResult(
        success: false,
        errorMessage: 'Empty photo file',
      );
    }

    final filename = photoFile.path.split(Platform.pathSeparator).last;
    final lower = filename.toLowerCase();
    final MediaType contentType;
    final String fallbackName;
    if (lower.endsWith('.png')) {
      contentType = MediaType('image', 'png');
      fallbackName = 'photo.png';
    } else if (lower.endsWith('.webp')) {
      contentType = MediaType('image', 'webp');
      fallbackName = 'photo.webp';
    } else {
      contentType = MediaType('image', 'jpeg');
      fallbackName = 'photo.jpg';
    }

    final uri = Uri.parse('$baseUrl/api/v1/chat/threads/$threadId/messages');
    final media = await _multipartChatMedia(
      photoFile,
      fallbackName: fallbackName,
      contentType: contentType,
    );

    final caption = text.trim().isEmpty ? 'Photo' : text.trim();

    final response = await _sendMultipart(
      uri,
      fields: {'type': 'photo', 'text': caption},
      files: [media],
      timeout: const Duration(seconds: 90),
    );

    debugPrint('Send Photo Status : ${response.statusCode}');
    debugPrint('Send Photo Response : ${response.body}');

    final result = _parseChatMediaSendResponse(response);
    if (result.success && !result.hasServerMedia) {
      debugPrint(
        'sendPhotoMessageApi WARNING: server saved message but media_path '
        'is null. Backend is not storing the upload.',
      );
      return ChatMediaSendResult(
        success: false,
        messageId: result.messageId,
        mediaDuration: result.mediaDuration,
        isVideo: result.isVideo,
        errorMessage:
            'Server did not save photo file (media_path is null). Ask backend to fix media upload storage.',
      );
    }
    return result;
  } catch (e, st) {
    debugPrint('sendPhotoMessageApi Error : $e');
    debugPrint('$st');
    return ChatMediaSendResult(success: false, errorMessage: '$e');
  }
}

/// Apply leave — POST /api/v1/leaves
Future<bool> applyLeaveApi(
  BuildContext context, {
  required int siteId,
  required String type,
  required String fromDate,
  required String toDate,
  required String description,
}) async {
  try {
    final token = Preference.pref.getString('token') ?? '';
    final url = '$baseUrl/api/v1/leaves';

    // Matches Postman: type is string (casual/sick/function), not an id.
    final body = {
      'site_id': siteId,
      'type': type,
      'from_date': fromDate,
      'to_date': toDate,
      'description': description,
    };

    debugPrint('[applyLeaveApi] POST $url');
    debugPrint('[applyLeaveApi] request: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    debugPrint('[applyLeaveApi] statusCode: ${response.statusCode}');
    debugPrint('[applyLeaveApi] response: ${response.body}');

    final data = decodeApiJson(response.body);
    final apiMessage = data?['message']?.toString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!context.mounted) return false;
      message(context, apiMessage ?? 'Leave applied successfully');
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to apply leave.');
    return false;
  } catch (e, stack) {
    debugPrint('[applyLeaveApi] error: $e');
    debugPrint('[applyLeaveApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

/// GET /api/v1/leaves/types

Future<Getleavetypemodal?> getLeaveTypeApi(BuildContext context) async {
  try {
    final url = '$baseUrl/api/v1/leaves/types';
    debugPrint('[getLeaveTypeApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    debugPrint('[getLeaveTypeApi] statusCode: ${response.statusCode}');
    debugPrint('[getLeaveTypeApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final model = Getleavetypemodal.fromJson(decoded);
      debugPrint('[getLeaveTypeApi] types: ${model.data?.items?.length ?? 0}');
      return model;
    }

    if (context.mounted) {
      message(context, apiMessage ?? 'Failed to fetch leave types.');
    }
    return null;
  } catch (e, stack) {
    debugPrint('[getLeaveTypeApi] error: $e');
    debugPrint('[getLeaveTypeApi] stack: $stack');
    if (context.mounted) {
      message(context, 'Something went wrong');
    }
    return null;
  }
}

/// GET /api/v1/leaves/mine
Future<Getmyleavedata?> getMyLeaveApi(
  BuildContext context, {
  int perPage = 20,
  int page = 1,
  String status = 'all',
}) async {
  try {
    final query = <String, String>{
      'per_page': perPage.toString(),
      'page': page.toString(),
      if (status.trim().isNotEmpty) 'status': status.trim(),
    };

    final uri = Uri.parse(
      '$baseUrl/api/v1/leaves/mine',
    ).replace(queryParameters: query);
    debugPrint('[getMyLeaveApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    debugPrint('[getMyLeaveApi] statusCode: ${response.statusCode}');
    debugPrint('[getMyLeaveApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final model = Getmyleavedata.fromJson(decoded);
      debugPrint('[getMyLeaveApi] leaves: ${model.data?.items?.length ?? 0}');
      return model;
    }

    if (context.mounted) {
      message(context, apiMessage ?? 'Failed to fetch my leaves.');
    }
    return null;
  } catch (e, stack) {
    debugPrint('[getMyLeaveApi] error: $e');
    debugPrint('[getMyLeaveApi] stack: $stack');
    if (context.mounted) {
      message(context, 'Something went wrong');
    }
    return null;
  }
}

/// GET /api/v1/leaves/{leaveId}
///
Future<Getshowleavemodal?> getShowLeaveApi(
  BuildContext context,
  String leaveId,
) async {
  try {
    final id = leaveId.trim();
    if (id.isEmpty) {
      if (context.mounted) {
        message(context, 'Leave id is missing.');
      }
      return null;
    }

    final url = '$baseUrl/api/v1/leaves/$id';
    debugPrint('[getShowLeaveApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    debugPrint('[getShowLeaveApi] statusCode: ${response.statusCode}');
    debugPrint('[getShowLeaveApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final model = Getshowleavemodal.fromJson(decoded);
      debugPrint('[getShowLeaveApi] leaveId: ${model.data?.id}');
      return model;
    }

    if (context.mounted) {
      message(context, apiMessage ?? 'Failed to fetch leave details.');
    }
    return null;
  } catch (e, stack) {
    debugPrint('[getShowLeaveApi] error: $e');
    debugPrint('[getShowLeaveApi] stack: $stack');
    if (context.mounted) {
      message(context, 'Something went wrong');
    }
    return null;
  }
}

/// DELETE /api/v1/leaves/{leaveId}
Future<bool> deleteLeaveApi(BuildContext context, String leaveId) async {
  try {
    final id = leaveId.trim();
    if (id.isEmpty) {
      if (context.mounted) {
        message(context, 'Leave id is missing.');
      }
      return false;
    }

    final url = '$baseUrl/api/v1/leaves/$id';
    debugPrint('[deleteLeaveApi] DELETE $url');

    final response = await http
        .delete(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    debugPrint('[deleteLeaveApi] statusCode: ${response.statusCode}');
    debugPrint('[deleteLeaveApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 200 || response.statusCode == 204) &&
        (decoded == null || decoded['success'] != false)) {
      if (!context.mounted) return false;
      message(context, apiMessage ?? 'Leave deleted successfully');
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to delete leave.');
    return false;
  } catch (e, stack) {
    debugPrint('[deleteLeaveApi] error: $e');
    debugPrint('[deleteLeaveApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//getleaverequesrHR

Future<Leaverequesthr?> getLeaveRequestHRListApi(
  BuildContext context, {
  int perPage = 20,
  int page = 1,
  String status = 'all',
  String type = '',
  String search = '',
}) async {
  try {
    final query = <String, String>{
      'per_page': perPage.toString(),
      'page': page.toString(),
      'status': status.trim().isEmpty ? 'all' : status.trim(),
      'type': type.trim(),
      'search': search.trim(),
    };

    final uri = Uri.parse(
      '$baseUrl/api/v1/leaves',
    ).replace(queryParameters: query);
    debugPrint('[getLeaveRequestHRListApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    debugPrint('[getLeaveRequestHRListApi] statusCode: ${response.statusCode}');
    debugPrint('[getLeaveRequestHRListApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final model = Leaverequesthr.fromJson(decoded);
      debugPrint(
        '[getLeaveRequestHRListApi] leaves: ${model.data?.items?.length ?? 0}',
      );
      return model;
    }

    if (context.mounted) {
      message(context, apiMessage ?? 'Failed to fetch leave requests.');
    }
    return null;
  } catch (e, stack) {
    debugPrint('[getLeaveRequestHRListApi] error: $e');
    debugPrint('[getLeaveRequestHRListApi] stack: $stack');
    if (context.mounted) {
      message(context, 'Something went wrong');
    }
    return null;
  }
}

//approveleave from HR

Future<bool> approveLeaveApi(
  BuildContext context, {
  required String leaveId,
}) async {
  try {
    final id = leaveId.trim();
    if (id.isEmpty) {
      if (context.mounted) {
        message(context, 'Leave id is missing.');
      }
      return false;
    }

    final url = '$baseUrl/api/v1/leaves/$id/approve';
    debugPrint('[approveLeaveApi] POST $url');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    debugPrint('[approveLeaveApi] statusCode: ${response.statusCode}');
    debugPrint('[approveLeaveApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      if (!context.mounted) return false;
      message(context, apiMessage ?? 'Leave approved successfully');
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to approve leave.');
    return false;
  } catch (e, stack) {
    debugPrint('[approveLeaveApi] error: $e');
    debugPrint('[approveLeaveApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//Rejectleave from HR

Future<bool> rejectLeaveApi(
  BuildContext context, {
  required String leaveId,
}) async {
  try {
    final id = leaveId.trim();
    if (id.isEmpty) {
      if (context.mounted) {
        message(context, 'Leave id is missing.');
      }
      return false;
    }

    final url = '$baseUrl/api/v1/leaves/$id/reject';
    debugPrint('[rejectLeaveApi] POST $url');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    debugPrint('[rejectLeaveApi] statusCode: ${response.statusCode}');
    debugPrint('[rejectLeaveApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      if (!context.mounted) return false;
      message(context, apiMessage ?? 'Leave rejected successfully');
      return true;
    }

    if (!context.mounted) return false;
    message(context, apiMessage ?? 'Failed to reject leave.');
    return false;
  } catch (e, stack) {
    debugPrint('[rejectLeaveApi] error: $e');
    debugPrint('[rejectLeaveApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//getreportsapi
Future<Getreportmodaldata?> getReportsApi(
  BuildContext context, {
  required int siteId,
}) async {
  try {
    final uri = Uri.parse(
      '$baseUrl/api/v1/reports',
    ).replace(queryParameters: {'site_id': siteId.toString()});

    print('[getReportsApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getReportsApi] statusCode: ${response.statusCode}');
    print('[getReportsApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return Getreportmodaldata.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load reports.');
    return null;
  } on TimeoutException {
    print('[getReportsApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getReportsApi] error: $e');
    print('[getReportsApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//getreportdetailapi — calls path from reports list item (e.g. /api/v1/reports/challan)
Future<Map<String, dynamic>?> getReportDetailApi(
  BuildContext context, {
  required String path,
  required int siteId,
  Map<String, String> queryParams = const {},
}) async {
  try {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final params = <String, String>{
      'site_id': siteId.toString(),
      ...queryParams,
    }..removeWhere((_, value) => value.trim().isEmpty);

    final uri = Uri.parse(
      '$baseUrl$normalizedPath',
    ).replace(queryParameters: params);

    print('[getReportDetailApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getReportDetailApi] statusCode: ${response.statusCode}');
    print('[getReportDetailApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] != false) {
      return decoded;
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load report.');
    return null;
  } on TimeoutException {
    print('[getReportDetailApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getReportDetailApi] error: $e');
    print('[getReportDetailApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

/// GET report Excel using `excel_url` from the reports list, plus the same
/// required params used by the report detail request (`site_id`, dates, etc.).
Future<Uint8List?> downloadReportExcelApi(
  BuildContext context, {
  required String excelUrl,
  required int siteId,
  Map<String, String> queryParams = const {},
}) async {
  try {
    var raw = excelUrl.trim();
    if (raw.isEmpty) {
      if (context.mounted) {
        message(context, 'Excel download is not available for this report.');
      }
      return null;
    }
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = '$baseUrl${raw.startsWith('/') ? raw : '/$raw'}';
    }

    final parsed = Uri.parse(raw);
    final params = <String, String>{
      ...parsed.queryParameters,
      'site_id': siteId.toString(),
      ...queryParams,
    }..removeWhere((_, value) => value.trim().isEmpty);

    final uri = parsed.replace(queryParameters: params);

    print('[downloadReportExcelApi] GET $uri');

    final response = await http
        .get(uri, headers: pdfAuthHeaders)
        .timeout(const Duration(seconds: 60));

    print(
      '[downloadReportExcelApi] statusCode: ${response.statusCode} bytes: ${response.bodyBytes.length}',
    );

    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      final bytes = response.bodyBytes;
      final looksJson =
          bytes.isNotEmpty &&
          (bytes[0] == 0x7B || bytes[0] == 0x5B); // '{' or '['
      if (looksJson) {
        final decoded = decodeApiJson(response.body);
        final apiMessage = decoded?['message']?.toString();
        if (!context.mounted) return null;
        message(context, apiMessage ?? 'Failed to download Excel.');
        return null;
      }
      return bytes;
    }

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();
    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to download Excel.');
    return null;
  } on TimeoutException {
    print('[downloadReportExcelApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[downloadReportExcelApi] error: $e');
    print('[downloadReportExcelApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//getattendancecalendarapi
Future<Getcalendermodal?> getAttendanceCalendarApi(
  BuildContext context, {
  int? siteId,
  required String month,
  int? userId,
  bool showErrors = false,
}) async {
  try {
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId == null) {
      if (showErrors && context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'month': month.trim(),
    };
    if (userId != null) {
      queryParams['user_id'] = userId.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/api/v1/attendances/calendar',
    ).replace(queryParameters: queryParams);

    print('[getAttendanceCalendarApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getAttendanceCalendarApi] statusCode: ${response.statusCode}');
    print('[getAttendanceCalendarApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return Getcalendermodal.fromJson(decoded);
    }

    if (showErrors && context.mounted) {
      message(context, apiMessage ?? 'Failed to load attendance calendar.');
    }
    return null;
  } on TimeoutException {
    print('[getAttendanceCalendarApi] request timed out');
    if (showErrors && context.mounted) {
      message(context, 'Request timed out. Please try again.');
    }
    return null;
  } catch (e, stack) {
    print('[getAttendanceCalendarApi] error: $e');
    print('[getAttendanceCalendarApi] stack: $stack');
    if (showErrors && context.mounted) {
      message(context, 'Something went wrong');
    }
    return null;
  }
}

//getoriginalcontractorapi
Future<Getoriginalcontractor?> getOriginalContractorsApi(
  BuildContext context, {
  int? siteId,
  String search = '',
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

    final queryParams = <String, String>{
      'site_id': resolvedSiteId.toString(),
      'per_page': perPage.toString(),
    };
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/api/v1/original-contractors',
    ).replace(queryParameters: queryParams);

    print('[getOriginalContractorsApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getOriginalContractorsApi] statusCode: ${response.statusCode}');
    print('[getOriginalContractorsApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] != false) {
      return Getoriginalcontractor.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load contractors.');
    return null;
  } on TimeoutException {
    print('[getOriginalContractorsApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getOriginalContractorsApi] error: $e');
    print('[getOriginalContractorsApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//createoriginalcontractorapi — POST /api/v1/original-contractors
Future<OriginalContractorItem?> createOriginalContractorApi(
  BuildContext context, {
  required int siteId,
  required String name,
  required String phone,
  required String address,
  required String status,
  required List<Map<String, dynamic>> works,
  required List<File> agreementFiles,
  required List<File> documentFiles,
  required File cancelChequeFile,
}) async {
  try {
    final url = '$baseUrl/api/v1/original-contractors';
    final worksPayload = works
        .map(
          (item) => {
            'work': item['work']?.toString().trim() ?? '',
            'rate': item['rate'] is num
                ? (item['rate'] as num).toInt()
                : int.tryParse(item['rate']?.toString() ?? '') ?? 0,
          },
        )
        .where((item) => (item['work'] as String).isNotEmpty)
        .toList();

    final files = <http.MultipartFile>[];
    for (final f in agreementFiles) {
      files.add(await _multipartImage('agreements[]', f));
    }
    for (final f in documentFiles) {
      files.add(await _multipartImage('documents[]', f));
    }
    files.add(await _multipartImage('cancel_cheque', cancelChequeFile));

    print('[createOriginalContractorApi] POST $url multipart');

    final response = await _sendMultipart(
      Uri.parse(url),
      fields: {
        'site_id': siteId.toString(),
        'name': name.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'status': status,
        'works': jsonEncode(worksPayload),
      },
      files: files,
    );

    print('[createOriginalContractorApi] statusCode: ${response.statusCode}');
    print('[createOriginalContractorApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded != null &&
        decoded['success'] == true) {
      if (context.mounted) {
        message(context, apiMessage ?? 'Original contractor created');
      }

      final data = decoded['data'];
      if (data is Map) {
        return OriginalContractorItem.fromJson(Map<String, dynamic>.from(data));
      }
      return OriginalContractorItem(
        siteId: siteId,
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
        status: status,
      );
    }

    if (!context.mounted) return null;
    message(
      context,
      _firstApiError(decoded) ?? apiMessage ?? 'Failed to create contractor.',
    );
    return null;
  } on TimeoutException {
    print('[createOriginalContractorApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[createOriginalContractorApi] error: $e');
    print('[createOriginalContractorApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

String? _firstApiError(Map<String, dynamic>? decoded) {
  final errors = decoded?['errors'];
  if (errors is! Map) return null;
  for (final value in errors.values) {
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value != null) return value.toString();
  }
  return null;
}

//getcontractorlistapi — GET /api/v1/original-contractors/{id}
Future<Getcclist?> getOriginalContractorApi(
  BuildContext context, {
  required int originalContractorId,
}) async {
  try {
    final url = '$baseUrl/api/v1/original-contractors/$originalContractorId';
    print('[getOriginalContractorApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getOriginalContractorApi] statusCode: ${response.statusCode}');
    print('[getOriginalContractorApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] != false) {
      return Getcclist.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(
      context,
      _firstApiError(decoded) ??
          apiMessage ??
          'Failed to load contractor details.',
    );
    return null;
  } on TimeoutException {
    print('[getOriginalContractorApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getOriginalContractorApi] error: $e');
    print('[getOriginalContractorApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//updateoriginalcontractorapi — PUT /api/v1/original-contractors/{id}
Future<Getcclist?> updateOriginalContractorApi(
  BuildContext context, {
  required int originalContractorId,
  required String name,
  required String phone,
  required String address,
  required String status,
  required List<Map<String, dynamic>> works,
  List<File> agreementFiles = const [],
  List<File> documentFiles = const [],
  File? cancelChequeFile,
}) async {
  try {
    final url = Uri.parse(
      '$baseUrl/api/v1/original-contractors/$originalContractorId',
    );
    final worksPayload = works
        .map(
          (item) => {
            'work': item['work']?.toString().trim() ?? '',
            'rate': item['rate'] is num
                ? (item['rate'] as num).toInt()
                : int.tryParse(item['rate']?.toString() ?? '') ?? 0,
          },
        )
        .where((item) => (item['work'] as String).isNotEmpty)
        .toList();

    final hasFiles =
        agreementFiles.isNotEmpty ||
        documentFiles.isNotEmpty ||
        cancelChequeFile != null;

    print('[updateOriginalContractorApi] ${hasFiles ? 'POST' : 'PUT'} $url');

    late final http.Response response;
    if (hasFiles) {
      final files = <http.MultipartFile>[];
      for (final f in agreementFiles) {
        files.add(await _multipartImage('agreements[]', f));
      }
      for (final f in documentFiles) {
        files.add(await _multipartImage('documents[]', f));
      }
      if (cancelChequeFile != null) {
        files.add(await _multipartImage('cancel_cheque', cancelChequeFile));
      }
      response = await _sendMultipart(
        url,
        fields: {
          'name': name.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'status': status,
          'works': jsonEncode(worksPayload),
        },
        files: files,
      );
    } else {
      response = await apiPut(
        url,
        headers: authHeaders,
        body: jsonEncode({
          'name': name.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'status': status,
          'works': worksPayload,
        }),
      ).timeout(const Duration(seconds: 30));
    }

    print('[updateOriginalContractorApi] statusCode: ${response.statusCode}');
    print('[updateOriginalContractorApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] != false) {
      if (context.mounted) {
        message(context, apiMessage ?? 'Original contractor updated');
      }
      return Getcclist.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(
      context,
      _firstApiError(decoded) ?? apiMessage ?? 'Failed to update contractor.',
    );
    return null;
  } on TimeoutException {
    print('[updateOriginalContractorApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[updateOriginalContractorApi] error: $e');
    print('[updateOriginalContractorApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//deletecontractorapi — DELETE /api/v1/original-contractors/{id}
Future<bool> deleteOriginalContractorApi(
  BuildContext context, {
  required int originalContractorId,
}) async {
  try {
    final url = '$baseUrl/api/v1/original-contractors/$originalContractorId';
    print('[deleteOriginalContractorApi] DELETE $url');

    final response = await http
        .delete(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[deleteOriginalContractorApi] statusCode: ${response.statusCode}');
    print('[deleteOriginalContractorApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 200 || response.statusCode == 204) &&
        (decoded == null || decoded['success'] != false)) {
      return true;
    }

    if (!context.mounted) return false;
    message(
      context,
      _firstApiError(decoded) ?? apiMessage ?? 'Failed to delete contractor.',
    );
    return false;
  } on TimeoutException {
    print('[deleteOriginalContractorApi] request timed out');
    if (!context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[deleteOriginalContractorApi] error: $e');
    print('[deleteOriginalContractorApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//employeekycapi — POST /api/v1/employee-kycs (updates authenticated user)
Future<bool> employeeKycApi(
  BuildContext context, {
  required String firstName,
  required String lastName,
  required String email,
  String? mobile,
  required int siteId,
  required String employmentType,
  required String joiningDate,
  required bool foodAllowance,
  String foodAllowanceType = '',
  String foodEmployeeAmount = '',
  required bool stayAllowance,
  String stayAllowanceType = '',
  String stayEmployeeAmount = '',
  required String emergencyContact,
  required String accountHolderName,
  required String bankName,
  required String accountNumber,
  required String ifscCode,
  required File pan,
  required File aadhaarFront,
  required File aadhaarBack,
  required File marksheet10,
  required File marksheet12,
  required File bankCheque,
}) async {
  try {
    final url = '$baseUrl/api/v1/employee-kycs';
    final fields = <String, String>{
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': email.trim(),
      'mobile': (mobile ?? '').trim(),
      'site_id': siteId.toString(),
      'employment_type': employmentType.trim(),
      'joining_date': joiningDate.trim(),
      'food_allowance': foodAllowance ? '1' : '0',
      if (foodAllowance) 'food_allowance_type': foodAllowanceType.trim(),
      'food_employee_amount': foodAllowance && foodAllowanceType == 'amount'
          ? foodEmployeeAmount.trim()
          : '0',
      'stay_allowance': stayAllowance ? '1' : '0',
      if (stayAllowance) 'stay_allowance_type': stayAllowanceType.trim(),
      'stay_employee_amount': stayAllowance && stayAllowanceType == 'amount'
          ? stayEmployeeAmount.trim()
          : '0',
      'emergency_contact': emergencyContact.trim(),
      if (accountHolderName.trim().isNotEmpty)
        'account_holder_name': accountHolderName.trim(),
      if (bankName.trim().isNotEmpty) 'bank_name': bankName.trim(),
      if (accountNumber.trim().isNotEmpty)
        'account_number': accountNumber.trim(),
      if (ifscCode.trim().isNotEmpty) 'ifsc_code': ifscCode.trim().toUpperCase(),
    };

    final files = [
      await _multipartImage('pan', pan, fallbackName: 'pan.jpg'),
      await _multipartImage(
        'aadhaar_front',
        aadhaarFront,
        fallbackName: 'aadhaar_front.jpg',
      ),
      await _multipartImage(
        'aadhaar_back',
        aadhaarBack,
        fallbackName: 'aadhaar_back.jpg',
      ),
      await _multipartImage(
        'marksheet_10',
        marksheet10,
        fallbackName: 'marksheet_10.jpg',
      ),
      await _multipartImage(
        'marksheet_12',
        marksheet12,
        fallbackName: 'marksheet_12.jpg',
      ),
      await _multipartImage(
        'bank_cheque',
        bankCheque,
        fallbackName: 'bank_cheque.jpg',
      ),
    ];

    print('[employeeKycApi] POST $url');
    print('[employeeKycApi] fields: $fields');
    print(
      '[employeeKycApi] files: pan, aadhaar_front, aadhaar_back, marksheet_10, marksheet_12, bank_cheque',
    );

    final response = await _sendMultipart(
      Uri.parse(url),
      fields: fields,
      files: files,
      timeout: const Duration(seconds: 90),
    );

    print('[employeeKycApi] statusCode: ${response.statusCode}');
    print('[employeeKycApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        (decoded == null || decoded['success'] != false)) {
      return true;
    }

    if (!context.mounted) return false;
    message(
      context,
      _firstApiError(decoded) ?? apiMessage ?? 'Failed to submit Employee KYC.',
    );
    return false;
  } on TimeoutException {
    print('[employeeKycApi] request timed out');
    if (!context.mounted) return false;
    message(context, 'Request timed out. Please try again.');
    return false;
  } catch (e, stack) {
    print('[employeeKycApi] error: $e');
    print('[employeeKycApi] stack: $stack');
    if (!context.mounted) return false;
    message(context, 'Something went wrong');
    return false;
  }
}

//mykycdata — GET /api/v1/employee-kycs/mine
Future<MyKycModalData?> getMyEmployeeKycApi(BuildContext context) async {
  try {
    final url = '$baseUrl/api/v1/employee-kycs/mine';
    print('[getMyEmployeeKycApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getMyEmployeeKycApi] statusCode: ${response.statusCode}');
    print('[getMyEmployeeKycApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    if (response.statusCode == 404) return null;

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true &&
        decoded['data'] is Map) {
      return MyKycModalData.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    }

    if (decoded != null && decoded['success'] == false) {
      return null;
    }

    if (!context.mounted) return null;
    if (response.statusCode != 200) {
      message(
        context,
        decoded?['message']?.toString() ?? 'Failed to load Employee KYC.',
      );
    }
    return null;
  } on TimeoutException {
    print('[getMyEmployeeKycApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getMyEmployeeKycApi] error: $e');
    print('[getMyEmployeeKycApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//employeekycrequestapi — GET /api/v1/employee-kycs
Future<GetMyEmployeeKycRequest?> getMyEmployeeKycRequestApi(
  BuildContext context, {
  int? siteId,
  int perPage = 20,
  int page = 1,
  String? status,
  String? search,
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
      'page': page.toString(),
    };
    if (status != null && status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/api/v1/employee-kycs',
    ).replace(queryParameters: queryParams);
    print('[getMyEmployeeKycRequestApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getMyEmployeeKycRequestApi] statusCode: ${response.statusCode}');
    print('[getMyEmployeeKycRequestApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true &&
        decoded['data'] is Map) {
      return GetMyEmployeeKycRequest.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    }

    if (!context.mounted) return null;
    message(
      context,
      _firstApiError(decoded) ??
          apiMessage ??
          'Failed to load Employee KYC requests.',
    );
    return null;
  } on TimeoutException {
    print('[getMyEmployeeKycRequestApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getMyEmployeeKycRequestApi] error: $e');
    print('[getMyEmployeeKycRequestApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//showemployeekycapi — GET /api/v1/employee-kycs/{id}
Future<Showemployyeskycmodal?> showEmployeeKycApi(
  BuildContext context, {
  required int employeeId,
  bool showErrors = true,
}) async {
  try {
    final url = '$baseUrl/api/v1/employee-kycs/$employeeId';
    print('[showEmployeeKycApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[showEmployeeKycApi] statusCode: ${response.statusCode}');
    print('[showEmployeeKycApi] response body: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      return Showemployyeskycmodal.fromJson(decoded);
    }

    if (!showErrors || !context.mounted) return null;
    message(
      context,
      _firstApiError(decoded) ??
          apiMessage ??
          'Failed to load Employee KYC details.',
    );
    return null;
  } on TimeoutException {
    print('[showEmployeeKycApi] request timed out');
    if (!showErrors || !context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[showEmployeeKycApi] error: $e');
    print('[showEmployeeKycApi] stack: $stack');
    if (!showErrors || !context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//employeekycapproveapi — POST /api/v1/employee-kycs/{id}/approve
Future<Approvekycmodal?> approveEmployeeKycApi(
  BuildContext context, {
  required int employeeId,
}) async {
  try {
    if (employeeId <= 0) {
      if (context.mounted) {
        message(context, 'KYC id is missing.');
      }
      return null;
    }

    final url = '$baseUrl/api/v1/employee-kycs/$employeeId/approve';
    print('[approveEmployeeKycApi] POST $url');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[approveEmployeeKycApi] statusCode: ${response.statusCode}');
    print('[approveEmployeeKycApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded != null &&
        decoded['success'] != false) {
      if (context.mounted) {
        message(context, apiMessage ?? 'Employee KYC approved');
      }
      return Approvekycmodal.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(
      context,
      _firstApiError(decoded) ??
          apiMessage ??
          'Failed to approve Employee KYC.',
    );
    return null;
  } on TimeoutException {
    print('[approveEmployeeKycApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[approveEmployeeKycApi] error: $e');
    print('[approveEmployeeKycApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//employeekycrejectapi — POST /api/v1/employee-kycs/{id}/reject
Future<Approvekycmodal?> rejectEmployeeKycApi(
  BuildContext context, {
  required int employeeId,
}) async {
  try {
    if (employeeId <= 0) {
      if (context.mounted) {
        message(context, 'KYC id is missing.');
      }
      return null;
    }

    final url = '$baseUrl/api/v1/employee-kycs/$employeeId/reject';
    print('[rejectEmployeeKycApi] POST $url');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[rejectEmployeeKycApi] statusCode: ${response.statusCode}');
    print('[rejectEmployeeKycApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded != null &&
        decoded['success'] != false) {
      if (context.mounted) {
        message(context, apiMessage ?? 'Employee KYC rejected');
      }
      return Approvekycmodal.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(
      context,
      _firstApiError(decoded) ?? apiMessage ?? 'Failed to reject Employee KYC.',
    );
    return null;
  } on TimeoutException {
    print('[rejectEmployeeKycApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[rejectEmployeeKycApi] error: $e');
    print('[rejectEmployeeKycApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//getlistnotificationapi — GET /api/v1/notifications
Future<GetListNotification?> getListNotificationApi(
  BuildContext context, {
  String? unread,
  String? mode,
  int? siteId,
  int perPage = 20,
  int page = 1,
}) async {
  try {
    final queryParams = <String, String>{
      'per_page': perPage.toString(),
      'page': page.toString(),
    };
    if (unread != null && unread.trim().isNotEmpty) {
      queryParams['unread'] = unread.trim();
    }
    if (mode != null && mode.trim().isNotEmpty) {
      queryParams['mode'] = mode.trim();
    }
    final resolvedSiteId = siteId ?? selectedSiteId();
    if (resolvedSiteId != null) {
      queryParams['site_id'] = resolvedSiteId.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/api/v1/notifications',
    ).replace(queryParameters: queryParams);
    print('[getListNotificationApi] GET $uri');

    final response = await http
        .get(uri, headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getListNotificationApi] statusCode: ${response.statusCode}');
    print('[getListNotificationApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] == true) {
      final rawData = decoded['data'];
      if (rawData is Map) {
        return GetListNotification.fromJson(Map<String, dynamic>.from(rawData));
      }
      if (rawData is List) {
        return GetListNotification.fromJson({'items': rawData});
      }
      return GetListNotification.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(
      context,
      _firstApiError(decoded) ?? apiMessage ?? 'Failed to load notifications.',
    );
    return null;
  } on TimeoutException {
    print('[getListNotificationApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getListNotificationApi] error: $e');
    print('[getListNotificationApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}

//marknotificationreadapi — POST /api/v1/notifications/{id}/read
Future<bool> markNotificationReadApi(
  BuildContext context, {
  required String notificationId,
  bool showError = true,
}) async {
  try {
    final id = notificationId.trim();
    if (id.isEmpty) {
      if (showError && context.mounted) {
        message(context, 'Notification id is missing.');
      }
      return false;
    }

    final url = '$baseUrl/api/v1/notifications/$id/read';
    print('[markNotificationReadApi] POST $url');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[markNotificationReadApi] statusCode: ${response.statusCode}');
    print('[markNotificationReadApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded != null &&
        decoded['success'] != false) {
      return true;
    }

    if (showError && context.mounted) {
      message(
        context,
        _firstApiError(decoded) ??
            apiMessage ??
            'Failed to mark notification as read.',
      );
    }
    return false;
  } on TimeoutException {
    print('[markNotificationReadApi] request timed out');
    if (showError && context.mounted) {
      message(context, 'Request timed out. Please try again.');
    }
    return false;
  } catch (e, stack) {
    print('[markNotificationReadApi] error: $e');
    print('[markNotificationReadApi] stack: $stack');
    if (showError && context.mounted) {
      message(context, 'Something went wrong');
    }
    return false;
  }
}

//markallreadnotificationapi — POST /api/v1/notifications/mark-read
Future<bool> markAllNotificationsReadApi(BuildContext context) async {
  try {
    final url = '$baseUrl/api/v1/notifications/mark-read';
    print('[markAllNotificationsReadApi] POST $url');

    final response = await http
        .post(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[markAllNotificationsReadApi] statusCode: ${response.statusCode}');
    print('[markAllNotificationsReadApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        decoded != null &&
        decoded['success'] != false) {
      return true;
    }

    if (context.mounted) {
      message(
        context,
        _firstApiError(decoded) ??
            apiMessage ??
            'Failed to mark all notifications as read.',
      );
    }
    return false;
  } on TimeoutException {
    print('[markAllNotificationsReadApi] request timed out');
    if (context.mounted) {
      message(context, 'Request timed out. Please try again.');
    }
    return false;
  } catch (e, stack) {
    print('[markAllNotificationsReadApi] error: $e');
    print('[markAllNotificationsReadApi] stack: $stack');
    if (context.mounted) {
      message(context, 'Something went wrong');
    }
    return false;
  }
}

//getnotificationapi — GET /api/v1/notifications/{id}
Future<Getnotificationmodaldata?> getNotificationApi(
  BuildContext context, {
  required String notificationId,
}) async {
  try {
    final id = notificationId.trim();
    if (id.isEmpty || id == '0') {
      if (context.mounted) {
        message(context, 'Notification id is missing.');
      }
      return null;
    }

    final url = '$baseUrl/api/v1/notifications/$id';
    print('[getNotificationApi] GET $url');

    final response = await http
        .get(Uri.parse(url), headers: authHeaders)
        .timeout(const Duration(seconds: 30));

    print('[getNotificationApi] statusCode: ${response.statusCode}');
    print('[getNotificationApi] response: ${response.body}');

    final decoded = decodeApiJson(response.body);
    final apiMessage = decoded?['message']?.toString();

    if (response.statusCode == 200 &&
        decoded != null &&
        decoded['success'] != false) {
      return Getnotificationmodaldata.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(
      context,
      _firstApiError(decoded) ?? apiMessage ?? 'Failed to load notification.',
    );
    return null;
  } on TimeoutException {
    print('[getNotificationApi] request timed out');
    if (!context.mounted) return null;
    message(context, 'Request timed out. Please try again.');
    return null;
  } catch (e, stack) {
    print('[getNotificationApi] error: $e');
    print('[getNotificationApi] stack: $stack');
    if (!context.mounted) return null;
    message(context, 'Something went wrong');
    return null;
  }
}
