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
    this.status = OriginalContractorStatus.published,
  });

  final String id;
  final String name;
  final List<WorkRateItem> works;
  final OriginalContractorStatus status;

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
    List<WorkRateItem>? works,
    OriginalContractorStatus? status,
  }) {
    return OriginalContractor(
      id: id ?? this.id,
      name: name ?? this.name,
      works: works ?? this.works,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status == OriginalContractorStatus.published
            ? 'published'
            : 'unpublished',
        'works': works.map((w) => w.toJson()).toList(),
      };

  factory OriginalContractor.fromApiItem(OriginalContractorItem item) {
    return OriginalContractor(
      id: (item.id ?? 0).toString(),
      name: item.name ?? '',
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
    );
  }

  factory OriginalContractor.fromJson(Map<String, dynamic> json) {
    final rawWorks = json['works'];
    return OriginalContractor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
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
    );
  }
}
