import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/api_config.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/utils/app_helpers.dart';
import 'package:http/http.dart' as http;

//sites api
Future<List<Map<String, dynamic>>?> sitesApi(
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
        final items = (data['data']['items'] as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        await Preference.pref.setString('sites', jsonEncode(items));

        return items;
      } else {
        if (!context.mounted) return _cachedSites();
        message(context, data['message'].toString());
        throw Exception('Failed to load data');
      }
    } else {
      final data = json.decode(response.body);
      if (!context.mounted) return _cachedSites();
      message(context, data['message']?.toString() ?? 'Failed to load sites.');
      throw Exception('Failed to load data');
    }
  } catch (e) {
    print(e);
  }
  return _cachedSites();
}

List<Map<String, dynamic>>? _cachedSites() {
  final sitesJson = Preference.pref.getString('sites');
  if (sitesJson == null) return null;
  try {
    return (jsonDecode(sitesJson) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  } catch (_) {
    return null;
  }
}

List<String> siteNamesFromItems(List<Map<String, dynamic>> sites) {
  return sites.map((site) => site['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
}

String? siteNameById(List<Map<String, dynamic>> sites, int id) {
  for (final site in sites) {
    if (site['id'] == id) return site['name']?.toString();
  }
  return null;
}

String siteImageUrl(String? image) {
  if (image == null || image.isEmpty) return '';
  if (image.startsWith('http')) return image;
  return '$baseUrl/$image';
}
