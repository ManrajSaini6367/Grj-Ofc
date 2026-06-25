import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/api_config.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/main_shell.dart';
import 'package:grjoffice_apps/utils/app_helpers.dart';
import 'package:http/http.dart' as http;

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
      }),
    );
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final loginData = data['data'];
        final user = loginData['user'];

        await Preference.pref.setString('token', loginData['token'].toString());
        await Preference.pref.setString('userId', user['id'].toString());
        await Preference.pref.setString('phone', user['mobile'] ?? '');
        await Preference.pref.setString('email', user['email'].toString());
        await Preference.pref.setString('name', user['name'] ?? '');
        await Preference.pref.setString('user', jsonEncode(user));
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

bool get isLoggedIn => Preference.pref.getString('token') != null;

Map<String, String> get authHeaders {
  final token = Preference.pref.getString('token');
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

//profile api
Future<Map<String, dynamic>?> profileApi(BuildContext context) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/profile'),
      headers: authHeaders,
    );
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final profile = data['data'] as Map<String, dynamic>;

        await Preference.pref.setString('userId', profile['id'].toString());
        await Preference.pref.setString('phone', profile['mobile']?.toString() ?? '');
        await Preference.pref.setString('email', profile['email']?.toString() ?? '');
        await Preference.pref.setString('name', profile['name']?.toString() ?? '');
        await Preference.pref.setString('user', jsonEncode(profile));

        return profile;
      } else {
        if (!context.mounted) return null;
        message(context, data['message'].toString());
        throw Exception('Failed to load data');
      }
    } else {
      final data = json.decode(response.body);
      if (!context.mounted) return null;
      message(context, data['message']?.toString() ?? 'Failed to load profile.');
      throw Exception('Failed to load data');
    }
  } catch (e) {
    print(e);
  }
  return null;
}

String profileAvatarUrl(String? avatar) {
  if (avatar == null || avatar.isEmpty) return '';
  if (avatar.startsWith('http')) return avatar;
  return '$baseUrl/$avatar';
}

String profileRoleLabel(List<dynamic>? roles) {
  if (roles == null || roles.isEmpty) return 'User';
  final role = roles.first.toString();
  if (role.isEmpty) return 'User';
  return role[0].toUpperCase() + role.substring(1);
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
