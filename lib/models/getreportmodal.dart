class Getreportmodaldata {
  Getreportmodaldata({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final ReportData? data;

  factory Getreportmodaldata.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return Getreportmodaldata(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: rawData is Map
          ? ReportData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }
}

class ReportData {
  ReportData({
    this.siteId,
    this.items,
  });

  final int? siteId;
  final List<ReportMenuItem>? items;

  factory ReportData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return ReportData(
      siteId: json['site_id'] is int
          ? json['site_id'] as int
          : int.tryParse(json['site_id']?.toString() ?? ''),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => ReportMenuItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class ReportMenuItem {
  ReportMenuItem({
    this.key,
    this.title,
    this.subtitle,
    this.path,
    this.requiredParams,
    this.itemId,
    this.itemName,
    this.unit,
  });

  final String? key;
  final String? title;
  final String? subtitle;
  final String? path;
  final List<String>? requiredParams;
  final int? itemId;
  final String? itemName;
  final String? unit;

  factory ReportMenuItem.fromJson(Map<String, dynamic> json) {
    final rawParams = json['required_params'];
    return ReportMenuItem(
      key: json['key']?.toString(),
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      path: json['path']?.toString(),
      requiredParams: rawParams is List
          ? rawParams.map((e) => e.toString()).toList()
          : const [],
      itemId: json['item_id'] is int
          ? json['item_id'] as int
          : int.tryParse(json['item_id']?.toString() ?? ''),
      itemName: json['item_name']?.toString(),
      unit: json['unit']?.toString(),
    );
  }
}
