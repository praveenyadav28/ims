class UserModel {
  final String id;
  final int licenceNo;
  final String branchId;
  final String userName;
  final String password;
  final String role;

  UserModel({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    required this.userName,
    required this.password,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      licenceNo: json['licence_no'] ?? 0,
      branchId: json['branch_id']?.toString() ?? '',
      userName: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}
