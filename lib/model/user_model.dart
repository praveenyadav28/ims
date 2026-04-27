class UserModel {
  final String id;
  final int licenceNo;
  final String branchId;
  final String userName;
  final String password;
  final String role;
  final List<SingleRight>? singleRight;

  final List<String> rightList;

  UserModel({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    required this.userName,
    required this.password,
    required this.role,
    required this.singleRight,
    required this.rightList,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      licenceNo: json['licence_no'] ?? 0,
      branchId: json['branch_id']?.toString() ?? '',
      userName: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      singleRight: json["single_right"] == null
          ? []
          : List<SingleRight>.from(
              json["single_right"]!.map((x) => SingleRight.fromJson(x)),
            ),

      rightList: json["right_list"] == null
          ? []
          : json["right_list"] is List
          ? List<String>.from(json["right_list"])
          : json["right_list"]
                .toString()
                .replaceAll('[', '')
                .replaceAll(']', '')
                .split(',')
                .map((e) => e.trim())
                .toList(),
    );
  }
}

class SingleRight {
  String? module;
  bool? view;
  bool? create;
  bool? update;
  bool? delete;
  String? id;

  SingleRight({
    this.module,
    this.view,
    this.create,
    this.update,
    this.delete,
    this.id,
  });

  factory SingleRight.fromJson(Map<String, dynamic> json) => SingleRight(
    module: json["module"],
    view: json["view"],
    create: json["create"],
    update: json["update"],
    delete: json["delete"],
    id: json["_id"],
  );

  Map<String, dynamic> toJson() => {
    "module": module,
    "view": view,
    "create": create,
    "update": update,
    "delete": delete,
    "_id": id,
  };
}
