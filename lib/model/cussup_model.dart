class Customer {
  final String id;
  final int licenceNo;
  final String branchId;
  final String customerType;
  final String title;
  final String firstName;
  final String lastName;
  final String related;
  final String parents;
  final String parentsLast;
  final String companyName;
  final String email;
  final String? phone;
  final String mobile;
  final String pan;
  final String gstType;
  final String gstNo;
  final String address;
  final String city;
  final String state;
  final int openingBalance;
  final int closingBalance;
  final String address0;
  final String address1;
  final List<CustomerDocument> documents;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  Customer({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    required this.customerType,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.related,
    required this.parents,
    required this.parentsLast,
    required this.companyName,
    required this.email,
    this.phone,
    required this.mobile,
    required this.pan,
    required this.gstType,
    required this.gstNo,
    required this.address,
    required this.city,
    required this.state,
    required this.openingBalance,
    required this.closingBalance,
    required this.address0,
    required this.address1,
    required this.documents,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id']?.toString() ?? '',
      licenceNo: json['licence_no'] ?? 0,
      branchId: json['branch_id']?.toString() ?? '',
      customerType: json['customer_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      related: json['related']?.toString() ?? '',
      parents: json['parents']?.toString() ?? '',
      parentsLast: json['parents_last']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
      pan: json['pan']?.toString() ?? '',
      gstType: json['gst_type']?.toString() ?? '',
      gstNo: json['gst_no']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      openingBalance: json['opening_balance'] ?? 0,
      closingBalance: json['closing_balance'] ?? 0,
      address0: json['address_0']?.toString() ?? '',
      address1: json['address_1']?.toString() ?? '',
      documents: (json['document'] as List?)
              ?.map((e) => CustomerDocument.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      v: json['__v'] ?? 0,
    );
  }
}
class CustomerDocument {
  final String title;
  final String image;

  CustomerDocument({
    required this.title,
    required this.image,
  });

  factory CustomerDocument.fromJson(Map<String, dynamic> json) {
    return CustomerDocument(
      title: json['duc_title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}
