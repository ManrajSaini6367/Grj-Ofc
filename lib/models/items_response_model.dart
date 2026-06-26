import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/models/pagination_model.dart';

class ItemsResponseModel {
  const ItemsResponseModel({
    required this.items,
    required this.pagination,
  });

  final List<ItemModel> items;
  final PaginationModel pagination;

  factory ItemsResponseModel.fromJson(Map<String, dynamic> json) {
    return ItemsResponseModel(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => ItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}
