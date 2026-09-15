import 'package:grjoffice_apps/models/getoriginalcontractor.dart';

enum OriginalContractorStatus { published, unpublished }

class WorkRateItem {
  const WorkRateItem({
    required this.work,
    required this.rate,
  });

  final String work;
  final int rate;

  Map<String, dynamic> toJson() => {
        'work': work,
        'rate': rate,
      };

  factory WorkRateItem.fromJson(Map<String, dynamic> json) {
    return WorkRateItem(
      work: json['work']?.toString() ?? '',
      rate: int.tryParse(json['rate']?.toString() ?? '') ?? 0,
    );
  }
}

class OriginalContractor {
  const OriginalContractor({
    required this.id,
    required this.name,
    required this.works,
    this.phone = '',
    this.address = '',
    this.remarks = '',
    this.status = OriginalContractorStatus.published,
    this.agreements = const [],
    this.documents = const [],
    this.cancelCheque,
  });

  final String id;
  final String name;
  final String phone;
  final String address;
  final String remarks;
  final List<WorkRateItem> works;
  final OriginalContractorStatus status;
  final List<String> agreements;
  final List<String> documents;
  final String? cancelCheque;

  bool get isPublished => status == OriginalContractorStatus.published;

  String get worksSummary {
    final items = works.where((w) => w.work.trim().isNotEmpty).toList();
    if (items.isEmpty) return 'No work rates added';
    return items
        .map((w) => '${w.work} ₹${w.rate}')
        .join(' · ');
  }

  OriginalContractor copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? remarks,
    List<WorkRateItem>? works,
    OriginalContractorStatus? status,
    List<String>? agreements,
    List<String>? documents,
    String? cancelCheque,
  }) {
    return OriginalContractor(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      remarks: remarks ?? this.remarks,
      works: works ?? this.works,
      status: status ?? this.status,
      agreements: agreements ?? this.agreements,
      documents: documents ?? this.documents,
      cancelCheque: cancelCheque ?? this.cancelCheque,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'remarks': remarks,
        'status': status == OriginalContractorStatus.published
            ? 'published'
            : 'unpublished',
        'works': works.map((w) => w.toJson()).toList(),
        'agreements': agreements,
        'documents': documents,
        if (cancelCheque != null) 'cancel_cheque': cancelCheque,
      };

  factory OriginalContractor.fromApiItem(OriginalContractorItem item) {
    return OriginalContractor(
      id: (item.id ?? 0).toString(),
      name: item.name ?? '',
      phone: item.phone ?? '',
      address: item.address ?? '',
      remarks: item.remarks ?? '',
      status: item.status == 'unpublished'
          ? OriginalContractorStatus.unpublished
          : OriginalContractorStatus.published,
      works: (item.works ?? const [])
          .map(
            (work) => WorkRateItem(
              work: work.work ?? '',
              rate: work.rate ?? 0,
            ),
          )
          .toList(),
      agreements: item.agreements ?? const [],
      documents: item.documents ?? const [],
      cancelCheque: item.cancelCheque,
    );
  }

  factory OriginalContractor.fromJson(Map<String, dynamic> json) {
    final rawWorks = json['works'];
    return OriginalContractor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      status: json['status']?.toString() == 'unpublished'
          ? OriginalContractorStatus.unpublished
          : OriginalContractorStatus.published,
      works: rawWorks is List
          ? rawWorks
              .whereType<Map>()
              .map((item) => WorkRateItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
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
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  final out = <String>[];
  for (final item in value) {
    final s = item?.toString().trim() ?? '';
    if (s.isNotEmpty && s != 'null') out.add(s);
  }
  return out;
}
