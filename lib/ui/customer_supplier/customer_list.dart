import 'package:flutter/material.dart';
import 'package:ims/component/side_menu.dart';
import 'package:ims/ui/customer_supplier/create.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';

class CustomerTableScreen extends StatefulWidget {
  const CustomerTableScreen({super.key});

  @override
  State<CustomerTableScreen> createState() => _CustomerTableScreenState();
}

class _CustomerTableScreenState extends State<CustomerTableScreen> {
  List<Customer> customerList = [];

  @override
  void initState() {
    super.initState();
    gstApi();
  }

  Future gstApi() async {
    var response = await ApiService.fetchData(
      "get/${selectedType == "Customer" ? "customer" : 'supplier'}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    List responseData = response['data'];
    setState(() {
      customerList = responseData.map((e) => Customer.fromJson(e)).toList();
    });
  }

  Future deleteApi(String id) async {
    var response = await ApiService.deleteData(
      "customer/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (response['status'] == true) {
      gstApi().then((value) {
        setState(() {});
      });
    }
  }

  void _showDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${customer.title} ${customer.firstName} ${customer.lastName}',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mobile: ${customer.mobile}"),
              Text("Email: ${customer.email}"),
              Text("Type: ${customer.customerType}"),
              Text("Company: ${customer.companyName}"),
              Text("Address: ${customer.address}"),
              const SizedBox(height: 8),
              const Text(
                "Documents:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              if (customer.documents.isEmpty)
                const Text("No documents uploaded."),
              for (var doc in customer.documents)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Image.network(doc.image, width: 40, height: 40),
                  title: Text(doc.title),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  List<String> typeList = ["Customer", "Supplier"];
  String selectedType = "Customer";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "${selectedType == "Customer" ? "Customer" : "Supplier"} Master",
        ),
        actions: [
          InkWell(
            onTap: () async {
              var data = await pushTo(
                CreateCusSup(
                  isCustomer: selectedType == "Customer" ? true : false,
                ),
              );
              if (data == "data") {
                gstApi().then((onValue) {
                  setState(() {});
                });
              }
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: Row(
        children: [
          Spacer(flex: 3),
          Expanded(
            flex: 1,
            child: CommonDropdownField<String>(
              hintText: "",
              value: selectedType,
              items: typeList.map((title) {
                return DropdownMenuItem(value: title, child: Text(title));
              }).toList(),
              onChanged: (val) {
                setState(() => selectedType = val!);
                gstApi().then((onValue) {
                  setState(() {});
                });
              },
            ),
          ),
        ],
      ),
      drawer: SideMenu(),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          width: Sizes.width,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blue.shade100),
            border: TableBorder.all(color: Colors.grey.shade300),
            columns: const [
              DataColumn(label: Text("Party Name")),
              DataColumn(label: Text("Type")),
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Mobile")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Action")),
            ],
            rows: customerList.map((customer) {
              return DataRow(
                cells: [
                  DataCell(Text(customer.companyName.toString())),
                  DataCell(Text(customer.customerType)),
                  DataCell(
                    Text(
                      "${customer.title} ${customer.firstName} ${customer.lastName}",
                    ),
                  ),
                  DataCell(Text(customer.mobile)),
                  DataCell(Text(customer.email)),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.blue,
                          ),
                          onPressed: () => _showDetails(customer),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            deleteApi(customer.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class Customer {
  final String id;
  final String licenceNo;
  final String branchId;
  final String customerType;
  final String title;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  final String companyName;
  final String address;
  final List<CustomerDocument> documents;

  Customer({
    required this.id,
    required this.licenceNo,
    required this.branchId,
    required this.customerType,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.companyName,
    required this.address,
    required this.documents,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'].toString(),
      licenceNo: json['licence_no'].toString(),
      branchId: json['branch_id'].toString(),
      customerType: json['customer_type'].toString(),
      title: json['title'].toString(),
      firstName: json['first_name'].toString(),
      lastName: json['last_name'].toString(),
      mobile: json['mobile'].toString(),
      email: json['email'].toString(),
      companyName: json['company_name'].toString(),
      address: json['address'].toString(),
      documents:
          (json['document'] as List?)
              ?.map((e) => CustomerDocument.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CustomerDocument {
  final String title;
  final String image;

  CustomerDocument({required this.title, required this.image});

  factory CustomerDocument.fromJson(Map<String, dynamic> json) {
    return CustomerDocument(
      title: json['duc_title'].toString(),
      image: json['image'].toString(),
    );
  }
}
