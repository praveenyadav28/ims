import 'dart:convert';

List<BranchList> branchListFromJson(dynamic jsonData) {
  if (jsonData is List) {
    return List<BranchList>.from(
      jsonData.map((x) => BranchList.fromJson(x as Map<String, dynamic>)),
    );
  } else if (jsonData is Map<String, dynamic>) {
    return [BranchList.fromJson(jsonData)];
  } else {
    throw Exception("Invalid JSON format for branch list");
  }
}

String branchListToJson(List<BranchList> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BranchList {
  String? id;
  int? licenceNo;
  String? contactNo;
  String? name;
  String? branchName;
  String? bAddress;
  String? bCity;
  String? bState;
  dynamic other1;
  dynamic other2;
  dynamic other3;
  dynamic other4;
  dynamic other5;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<User>? user;

  BranchList({
    this.id,
    this.licenceNo,
    this.contactNo,
    this.name,
    this.branchName,
    this.bAddress,
    this.bCity,
    this.bState,
    this.other1,
    this.other2,
    this.other3,
    this.other4,
    this.other5,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory BranchList.fromJson(Map<String, dynamic> json) {
    final branch =
        json["branch"] ?? json; // handle if data doesn't have "branch"
    final users = json["users"];

    final dynamic rawLicenceNo = branch["licence_no"];
    int? parsedLicenceNo;

    if (rawLicenceNo is int) {
      // If it's already an int (like 10001), use it directly
      parsedLicenceNo = rawLicenceNo;
    } else if (rawLicenceNo is String) {
      // If it's a String (like "10001"), safely parse it
      parsedLicenceNo = int.tryParse(rawLicenceNo);
    }
    // If it's null or neither, parsedLicenceNo remains null.

    return BranchList(
      id: branch["_id"],
      licenceNo: parsedLicenceNo,
      contactNo: branch["contact_no"],
      name: branch["name"],
      branchName: branch["branch_name"],
      bAddress: branch["address"],
      bCity: branch["city"],
      bState: branch["state"],
      other1: branch["other1"],
      other2: branch["other2"],
      other3: branch["other3"],
      other4: branch["other4"],
      other5: branch["other5"],
      createdAt: branch["createdAt"] == null
          ? null
          : DateTime.tryParse(branch["createdAt"]),
      updatedAt: branch["updatedAt"] == null
          ? null
          : DateTime.tryParse(branch["updatedAt"]),
      user: users == null
          ? []
          : users is List
          ? List<User>.from(users.map((x) => User.fromJson(x)))
          : [User.fromJson(users)],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "licence_no": licenceNo,
    "contact_no": contactNo,
    "name": name,
    "branch_name": branchName,
    "b_address": bAddress,
    "b_city": bCity,
    "b_state": bState,
    "other1": other1,
    "other2": other2,
    "other3": other3,
    "other4": other4,
    "other5": other5,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "users": user == null
        ? []
        : List<dynamic>.from(user!.map((x) => x.toJson())),
  };
}

class User {
  String? id;
  String? branchId;
  String? username;
  String? password;
  String? role;

  User({this.id, this.branchId, this.username, this.password, this.role});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["_id"],
    branchId: json["branch_id"],
    username: json["username"],
    password: json["password"],
    role: json["role"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "branch_id": branchId,
    "username": username,
    "password": password,
    "role": role,
  };
}
