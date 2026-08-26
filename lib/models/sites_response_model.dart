import 'package:grjoffice_apps/models/pagination_model.dart';
import 'package:grjoffice_apps/models/site_model.dart';

class SitesResponseModel {
  const SitesResponseModel({
    required this.items,
    required this.pagination,
  });

  final List<SiteModel> items;
  final PaginationModel pagination;

  factory SitesResponseModel.fromJson(Map<String, dynamic> json) {
    return SitesResponseModel(
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => SiteModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      pagination: PaginationModel.fromJson(
        json['pagination'] is Map
            ? Map<String, dynamic>.from(json['pagination'] as Map)
            : const {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((site) => site.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}
