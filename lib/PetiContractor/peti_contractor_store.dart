import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grjoffice_apps/PetiContractor/peti_contractor.dart';
import 'package:grjoffice_apps/core/preference.dart';

class OriginalContractorStore extends ChangeNotifier {
  OriginalContractorStore._();

  static final OriginalContractorStore instance = OriginalContractorStore._();

  static const _prefsKey = 'original_contractors';

  final List<OriginalContractor> _items = [];
  bool _loaded = false;

  List<OriginalContractor> get items => List.unmodifiable(_items);

  Future<void> load() async {
    if (_loaded) return;
    final raw = Preference.pref.getString(_prefsKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items
            ..clear()
            ..addAll(
              decoded.whereType<Map>().map(
                    (item) => OriginalContractor.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  ),
            );
        }
      } catch (_) {
        // Keep an empty local list if stored JSON is invalid.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(OriginalContractor contractor) async {
    _items.insert(0, contractor);
    await _persist();
  }

  Future<void> update(OriginalContractor contractor) async {
    final index = _items.indexWhere((item) => item.id == contractor.id);
    if (index == -1) {
      _items.insert(0, contractor);
    } else {
      _items[index] = contractor;
    }
    await _persist();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    await Preference.pref.setString(
      _prefsKey,
      jsonEncode(_items.map((item) => item.toJson()).toList()),
    );
    notifyListeners();
  }
}
