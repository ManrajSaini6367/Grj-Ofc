class Getoriginalcontractor {
  Getoriginalcontractor({
    this.success,
    this.message,
    this.data,
  });

  bool? success;
  String? message;
  Data? data;

  factory Getoriginalcontractor.fromJson(Map<String, dynamic> json) {
    return Getoriginalcontractor(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map
          ? Data.fromJson(Map<String, dynamic>.from(json['data'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

typedef GetOriginalContractor = Getoriginalcontractor;

class Data {
  Data({
    this.items,
    this.pagination,
  });

  List<OriginalContractorItem>? items;
  Pagination? pagination;

  factory Data.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is List) {
      return Data(
        items: rawItems
            .whereType<Map>()
            .map(
              (item) => OriginalContractorItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(),
        pagination: json['pagination'] is Map
            ? Pagination.fromJson(
                Map<String, dynamic>.from(json['pagination'] as Map),
              )
            : null,
      );
    }

    // Create API returns a single contractor object in `data`.
    if (json['id'] != null || json['name'] != null) {
      return Data(items: [OriginalContractorItem.fromJson(json)]);
    }

    return Data();
  }

  Map<String, dynamic> toJson() => {
        if (items != null)
          'items': items!.map((item) => item.toJson()).toList(),
        if (pagination != null) 'pagination': pagination!.toJson(),
      };
}

class OriginalContractorItem {
  OriginalContractorItem({
    this.id,
    this.siteId,
    this.name,
    this.phone,
    this.address,
    this.remarks,
    this.status,
    this.works,
    this.agreements,
    this.documents,
    this.cancelCheque,
  });

  int? id;
  int? siteId;
  String? name;
  String? phone;
  String? address;
  String? remarks;
  String? status;
  List<OriginalContractorWork>? works;
  List<String>? agreements;
  List<String>? documents;
  String? cancelCheque;

  factory OriginalContractorItem.fromJson(Map<String, dynamic> json) {
    final rawWorks = json['works'] ??
        json['work_rates'] ??
        json['original_contractor_works'];
    return OriginalContractorItem(
      id: _toInt(json['id']),
      siteId: _toInt(json['site_id']),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      remarks: json['remarks']?.toString(),
      status: json['status']?.toString(),
      works: rawWorks is List
          ? rawWorks.map(_parseWork).whereType<OriginalContractorWork>().toList()
          : const [],
      agreements: _stringList(json['agreements']),
      documents: _stringList(json['documents']),
      cancelCheque: () {
        final a = json['cancel_cheque']?.toString().trim();
        if (a != null && a.isNotEmpty && a != 'null') return a;
        final b = json['cancel_cheque_url']?.toString().trim();
        if (b != null && b.isNotEmpty && b != 'null') return b;
        return null;
      }(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'site_id': siteId,
        'name': name,
        'phone': phone,
        'address': address,
        'remarks': remarks,
        'status': status,
        if (works != null)
          'works': works!.map((work) => work.toJson()).toList(),
        if (agreements != null) 'agreements': agreements,
        if (documents != null) 'documents': documents,
        if (cancelCheque != null) 'cancel_cheque': cancelCheque,
      };
}

class OriginalContractorWork {
  OriginalContractorWork({
    this.work,
    this.rate,
  });

  String? work;
  int? rate;

  Map<String, dynamic> toJson() => {
        'work': work,
        'rate': rate,
      };
}

class Pagination {
  Pagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
    this.prevPageUrl,
    this.nextPageUrl,
  });

  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  dynamic from;
  dynamic to;
  dynamic prevPageUrl;
  dynamic nextPageUrl;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: _toInt(json['current_page']),
      lastPage: _toInt(json['last_page']),
      perPage: _toInt(json['per_page']),
      total: _toInt(json['total']),
      from: json['from'],
      to: json['to'],
      prevPageUrl: json['prev_page_url'],
      nextPageUrl: json['next_page_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
        'from': from,
        'to': to,
        'prev_page_url': prevPageUrl,
        'next_page_url': nextPageUrl,
      };
}

OriginalContractorWork? _parseWork(dynamic raw) {
  if (raw is Map) {
    final json = Map<String, dynamic>.from(raw);
    return OriginalContractorWork(
      work: (json['work'] ?? json['name'] ?? json['title'])?.toString(),
      rate: _toInt(json['rate'] ?? json['amount']),
    );
  }
  return null;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

List<String>? _stringList(dynamic value) {
  if (value is! List) return null;
  final out = <String>[];
  for (final item in value) {
    final s = item?.toString().trim() ?? '';
    if (s.isNotEmpty && s != 'null') out.add(s);
  }
  return out;
}
