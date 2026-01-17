
// =====================================================
// ===================== MODELS ========================
// =====================================================

class EmployeeModel {
  final String id;
  final String licenceNo;
  final String branchId;
  final String title;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  final String gender;
  final String address;
  final List<EmployeeDocument> documents;

  EmployeeModel({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.gender,
    required this.address,
    required this.documents,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['_id'].toString(),
      licenceNo: json['licence_no'].toString(),
      branchId: json['branch_id'].toString(),
      title: json['title'].toString(),
      firstName: json['first_name'].toString(),
      lastName: json['last_name'].toString(),
      mobile: json['mobile'].toString(),
      email: json['email'].toString(),
      gender: json['gender'].toString(),
      address: json['address'].toString(),
      documents:
          (json['document'] as List?)
              ?.map((e) => EmployeeDocument.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EmployeeDocument {
  final String title;
  final String image;

  EmployeeDocument({required this.title, required this.image});

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeeDocument(
      title: json['duc_title'].toString(),
      image: json['image'].toString(),
    );
  }
}
