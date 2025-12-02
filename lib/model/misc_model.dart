import 'dart:convert';

List<Staffmodel> staffmodelFromJson(String str) =>
    List<Staffmodel>.from(json.decode(str).map((x) => Staffmodel.fromJson(x)));

String staffmodelToJson(List<Staffmodel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Staffmodel {
  final int id;
  final String staffName;

  Staffmodel({required this.id, required this.staffName});

  factory Staffmodel.fromJson(Map<String, dynamic> json) =>
      Staffmodel(id: json["id"], staffName: json["staff_Name"]);

  Map<String, dynamic> toJson() => {"id": id, "staff_Name": staffName};
}

MiscResponse miscResponseFromJson(String str) =>
    MiscResponse.fromJson(json.decode(str));

String miscResponseToJson(MiscResponse data) => json.encode(data.toJson());

class MiscResponse {
  final bool status;
  final List<MiscItem> data;

  MiscResponse({required this.status, required this.data});

  factory MiscResponse.fromJson(Map<String, dynamic> json) => MiscResponse(
    status: json["status"],
    data: List<MiscItem>.from(json["data"].map((x) => MiscItem.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class MiscItem {
  final String ? id;
  final String ? licenceNo;
  final String ? branchId;
  final String ? name;
  final String ? miscId;
  final DateTime ? createdAt;
  final DateTime ? updatedAt;

  MiscItem({
     this.id,
     this.licenceNo,
     this.branchId,
     this.name,
     this.miscId,
     this.createdAt,
     this.updatedAt,
  });

  factory MiscItem.fromJson(Map<String, dynamic> json) => MiscItem(
    id: json["_id"].toString(),
    licenceNo: json["licence_no"].toString(),
    branchId: json["branch_id"].toString(),
    name: json["name"].toString(),
    miscId: json["misc_id"].toString(),
    createdAt: DateTime.parse(json["createdAt"]),
    updatedAt: DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "licence_no": licenceNo,
    "branch_id": branchId,
    "name": name,
    "misc_id": miscId,
    "createdAt": createdAt!.toIso8601String(),
    "updatedAt": updatedAt!.toIso8601String(),
  };
}
