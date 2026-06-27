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
import 'package:grjoffice_apps/contractors/labour_contractor.dart';
import 'package:grjoffice_apps/items/item.dart';
import 'package:grjoffice_apps/models/getemployeemodal.dart';
import 'package:grjoffice_apps/models/getsupplier.dart';
import 'package:grjoffice_apps/models/getsupplierlist.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/models/itemhistorymodal.dart';
import 'package:grjoffice_apps/models/items_response_model.dart';
import 'package:grjoffice_apps/models/listcontractor.dart';
import 'package:grjoffice_apps/models/login_model.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/models/sites_response_model.dart';
import 'package:grjoffice_apps/models/user_model.dart';
import 'package:grjoffice_apps/models/viewemployeeprofile.dart';
import 'package:grjoffice_apps/suppliers/supplier.dart';
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

    final response = await http.get(
      Uri.parse(url),
      headers: authHeaders,
    );

    print('[getSupplierApi] statusCode: ${response.statusCode}');
    print('[getSupplierApi] response body: ${response.body}');

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final apiMessage = decoded['message']?.toString();

    if (response.statusCode == 200 && decoded['success'] == true) {
      return Getsuppilerdata.fromJson(decoded);
    }

    if (!context.mounted) return null;
    if (apiMessage != null) message(context, apiMessage);
    return null;
  } catch (e, stack) {
    print('[getSupplierApi] error: $e');
    print('[getSupplierApi] stack: $stack');
    return null;
  }
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
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final uri = Uri.parse('$baseUrl/api/v1/suppliers').replace(
      queryParameters: {
        'site_id': resolvedSiteId.toString(),
        'search': search,
        'per_page': perPage.toString(),
      },
    );

    print('[getSuppliersApi] GET $uri');

    final response = await http.get(uri, headers: authHeaders);

    print('[getSuppliersApi] statusCode: ${response.statusCode}');
    print('[getSuppliersApi] response body: ${response.body}');

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final apiMessage = decoded['message']?.toString();

    if (response.statusCode == 200 && decoded['success'] == true) {
      return Getsupplierlistdata.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load suppliers.');
    return null;
  } catch (e, stack) {
    print('[getSuppliersApi] error: $e');
    print('[getSuppliersApi] stack: $stack');
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
      if (context.mounted) {
        message(context, 'Please select a site first.');
      }
      return null;
    }

    final uri = Uri.parse('$baseUrl/api/v1/contractors').replace(
      queryParameters: {
        'site_id': resolvedSiteId.toString(),
        'search': search,
        'per_page': perPage.toString(),
      },
    );

    print('[getContractorListApi] GET $uri');

    final response = await http.get(uri, headers: authHeaders);

    print('[getContractorListApi] statusCode: ${response.statusCode}');
    print('[getContractorListApi] response body: ${response.body}');

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final apiMessage = decoded['message']?.toString();

    if (response.statusCode == 200 && decoded['success'] == true) {
      return Contractorlistdatamodal.fromJson(decoded);
    }

    if (!context.mounted) return null;
    message(context, apiMessage ?? 'Failed to load contractors.');
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