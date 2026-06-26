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
          .map((item) => SiteModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
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
