import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/api_config.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/main_shell.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/models/items_response_model.dart';
import 'package:grjoffice_apps/models/login_model.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/models/sites_response_model.dart';
import 'package:grjoffice_apps/models/user_model.dart';
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

int? selectedSiteId() =>
    Preference.pref.getInt('site_id') ?? Preference.pref.getInt('selectedSiteId');

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
