// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

Getcontractordatamodal getcontractordatamodal(String str) => Getcontractordatamodal.fromJson(json.decode(str));

String getcontractordatamodalToJson(Getcontractordatamodal data) => json.encode(data.toJson());

class Getcontractordatamodal {
    bool? success;
    String? message;
    Data? data;

    Getcontractordatamodal({
         this.success,
         this.message,
         this.data,
    });

    factory Getcontractordatamodal.fromJson(Map<String, dynamic> json) => Getcontractordatamodal(
        success: json["success"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data!.toJson(),
    };
}

class Data {
    int ?id;
    int ?siteId;
    String ?name;
    String ?mobile;
    String ?address;
    String ?status;
    String ?masonRate;
    String ?beldarRate;
    String ?coolieRate;
    String ?masonOverRate;
    String ?beldarOverRate;
    String ?coolieOverRate;
    DateTime ?createdAt;
    DateTime ?updatedAt;
    Site ?site;

    Data({
         this.id,
         this.siteId,
         this.name,
         this.mobile,
         this.address,
         this.status,
         this.masonRate,
         this.beldarRate,
         this.coolieRate,
         this.masonOverRate,
         this.beldarOverRate,
         this.coolieOverRate,
         this.createdAt,
         this.updatedAt,
         this.site,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        siteId: json["site_id"],
        name: json["name"],
        mobile: json["mobile"],
        address: json["address"],
        status: json["status"],
        masonRate: json["mason_rate"],
        beldarRate: json["beldar_rate"],
        coolieRate: json["coolie_rate"],
        masonOverRate: json["mason_over_rate"],
        beldarOverRate: json["beldar_over_rate"],
        coolieOverRate: json["coolie_over_rate"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        site: Site.fromJson(json["site"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "site_id": siteId,
        "name": name,
        "mobile": mobile,
        "address": address,
        "status": status,
        "mason_rate": masonRate,
        "beldar_rate": beldarRate,
        "coolie_rate": coolieRate,
        "mason_over_rate": masonOverRate,
        "beldar_over_rate": beldarOverRate,
        "coolie_over_rate": coolieOverRate,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt!.toIso8601String(),
        "site": site!.toJson(),
    };
}

class Site {
    int ?id;
    String ?name;
    String ?address;
    String ?status;
    DateTime ?createdAt;
    DateTime ?updatedAt;
    String ?image;
    dynamic shortDescription;
    int ?tenderAmount;
    int ?emdDeposit;
    DateTime ?workStartDate;
    DateTime ?workEndDate;

    Site({
         this.id,
         this.name,
         this.address,
         this.status,
         this.createdAt,
         this.updatedAt,
         this.image,
         this.shortDescription,
         this.tenderAmount,
         this.emdDeposit,
         this.workStartDate,
         this.workEndDate,
    });

    factory Site.fromJson(Map<String, dynamic> json) => Site(
        id: json["id"],
        name: json["name"],
        address: json["address"],
        status: json["status"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        image: json["image"],
        shortDescription: json["short_description"],
        tenderAmount: json["tender_amount"],
        emdDeposit: json["emd_deposit"],
        workStartDate: DateTime.parse(json["work_start_date"]),
        workEndDate: DateTime.parse(json["work_end_date"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "address": address,
        "status": status,
        "created_at": createdAt!.toIso8601String(),
        "updated_at": updatedAt!.toIso8601String(),
        "image": image,
        "short_description": shortDescription,
        "tender_amount": tenderAmount,
        "emd_deposit": emdDeposit,
        "work_start_date": "${workStartDate!.year.toString().padLeft(4, '0')}-${workStartDate!.month.toString().padLeft(2, '0')}-${workStartDate!.day.toString().padLeft(2, '0')}",
        "work_end_date": "${workEndDate!.year.toString().padLeft(4, '0')}-${workEndDate!.month.toString().padLeft(2, '0')}-${workEndDate!.day.toString().padLeft(2, '0')}",
    };
}
