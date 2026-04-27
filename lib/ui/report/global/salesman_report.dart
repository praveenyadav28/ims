import 'package:flutter/material.dart';
import 'package:ims/model/employee_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';
import 'package:searchfield/searchfield.dart';

class SalesmanReportScreen extends StatefulWidget {
  const SalesmanReportScreen({super.key});

  @override
  State<SalesmanReportScreen> createState() => _SalesmanReportScreenState();
}

class _SalesmanReportScreenState extends State<SalesmanReportScreen> {
  List<EmployeeModel> employeeList = [];
  String? employeeId;

  List<dynamic> dataList = [];
  List<dynamic> filteredList = [];
  List receiptsList = [];
  List<ItemModel> itemList = [];
  ItemModel? selectedItem;
  TextEditingController itemController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  TextEditingController salesPersonController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  String selectedType = "invoices";

  final typeList = [
    {"name": "Sale Invoice", "key": "invoices"},
    {"name": "Estimate", "key": "estimate"},
    {"name": "Delivery Challan", "key": "dilvery"},
    {"name": "Proforma Invoice", "key": "proforma"},
  ];

  @override
  void initState() {
    super.initState();
    fetchEmployee();
  }

  // ================= EMPLOYEE =================
  Future<void> fetchEmployee() async {
    var response = await ApiService.fetchData(
      "get/employee",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    List responseData = response['data'] ?? [];

    setState(() {
      employeeList = responseData
          .map((e) => EmployeeModel.fromJson(e))
          .toList();
    });
  }

  Future<void> fetchReport() async {
    if (employeeId == null) return;

    var res = await ApiService.fetchData(
      "get/employee/$employeeId",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final data = res['data'] ?? {};
    receiptsList = data['reciepts'] ?? [];
    // ✅ sabse pehle tempList define karo
    List tempList = data[selectedType] ?? [];

    List<ItemModel> tempItems = [];

    // 👇 ab ye chalega
    for (var e in tempList) {
      for (var item in (e['item_details'] ?? [])) {
        final name = item['item_name'] ?? "";
        final code = item['item_no'] ?? "";

        if (!tempItems.any((i) => i.name == name && i.code == code)) {
          tempItems.add(ItemModel(name: name, code: code));
        }
      }
    }

    setState(() {
      dataList = tempList;
      filteredList = tempList;
      itemList = tempItems;
      selectedItem = null;
      itemController.clear();
    });
  }

  void applyFilters() {
    DateTime? fromDate;
    DateTime? toDate;

    if (fromDateController.text.isNotEmpty) {
      fromDate = DateTime.parse(fromDateController.text);
    }

    if (toDateController.text.isNotEmpty) {
      toDate = DateTime.parse(toDateController.text);
    }

    List tempList = dataList;

    /// 🔥 DATE FILTER (FIRST APPLY)
    tempList = tempList.where((e) {
      final dateStr =
          e['estimate_date'] ??
          e['invoice_date'] ??
          e['proforma_date'] ??
          e['dilvery_date'];

      if (dateStr == null) return false;

      final itemDate = DateTime.parse(dateStr);

      if (fromDate != null && itemDate.isBefore(fromDate)) return false;
      if (toDate != null && itemDate.isAfter(toDate)) return false;

      return true;
    }).toList();

    /// 🔍 SEARCH
    if (searchController.text.isNotEmpty) {
      tempList = tempList.where((e) {
        return (e['customer_name'] ?? "").toLowerCase().contains(
          searchController.text.toLowerCase(),
        );
      }).toList();
    }

    /// 📦 ITEM FILTER
    if (selectedItem != null) {
      tempList = tempList.where((e) {
        return (e['item_details'] ?? []).any((item) {
          return item['item_no'] == selectedItem!.code ||
              item['item_name'].toLowerCase().contains(
                selectedItem!.name.toLowerCase(),
              );
        });
      }).toList();
    }

    setState(() {
      filteredList = tempList;
    });
  }

  double getTotalAmount() {
    double total = 0;

    for (var e in filteredList) {
      total += (e['totle_amo'] ?? 0).toDouble();
    }

    return total;
  }

  double getReceivedAmount(String invoiceNo) {
    double total = 0;

    for (var r in receiptsList) {
      if ((r['invoice_no'] ?? '') == invoiceNo) {
        total += (r['amount'] ?? 0).toDouble();
      }
    }

    return total;
  }

  double getTotalReceived() {
    double total = 0;

    for (var e in filteredList) {
      String invoiceNo = "${e['prefix']}${e['no']}";
      total += getReceivedAmount(invoiceNo);
    }

    return total;
  }

  double getTotalPending() {
    return getTotalAmount() - getTotalReceived();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salesman Report"),
        backgroundColor: AppColor.primary,
      ),
      backgroundColor: AppColor.white,
      bottomNavigationBar: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            /// 📊 Total Invoices
            Expanded(
              child: Text(
                "Total Transection: ${filteredList.length}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Spacer(flex: 4),

            /// 💰 Total Amount
            Text(
              "Pending: ₹${getTotalPending().toStringAsFixed(2)}",
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            SizedBox(width: 20),
            Text(
              "Total: ₹${getTotalAmount().toStringAsFixed(2)}",
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            SizedBox(width: 20),
            Text(
              "Received: ₹${getTotalReceived().toStringAsFixed(2)}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CommonSearchableDropdownField<EmployeeModel>(
                    controller: salesPersonController,
                    hintText: "Select Sales Person",
                    suggestions: employeeList.map((e) {
                      return SearchFieldListItem<EmployeeModel>(
                        "${e.firstName} ${e.lastName}",
                        item: e,
                      );
                    }).toList(),
                    onSuggestionTap: (value) {
                      final emp = value.item!;
                      salesPersonController.text =
                          "${emp.firstName} ${emp.lastName}";

                      employeeId = emp.id;

                      fetchReport();
                    },
                  ),
                ),

                /// 🔹 Employee Dropdown
                const SizedBox(width: 10),

                /// 🔹 Type Dropdown
                employeeId == null
                    ? Spacer()
                    : Expanded(
                        flex: 2,
                        child: CommonDropdownField<String>(
                          value: selectedType,
                          items: typeList.map((e) {
                            return DropdownMenuItem(
                              value: e['key'],
                              child: Text(e['name'] ?? ""),
                            );
                          }).toList(),
                          onChanged: (val) {
                            selectedType = val!;
                            fetchReport();
                          },
                        ),
                      ),

                const SizedBox(width: 10),
                employeeId == null
                    ? Spacer()
                    : Expanded(
                        flex: 2,
                        child: CommonSearchableDropdownField<ItemModel>(
                          controller: itemController,
                          hintText: "Select Item",
                          suggestions: itemList.map((e) {
                            return SearchFieldListItem<ItemModel>(
                              "${e.name} (${e.code})", // 👈 dono show
                              item: e,
                            );
                          }).toList(),

                          onSuggestionTap: (value) {
                            final item = value.item!;
                            selectedItem = item;

                            itemController.text = "${item.name} (${item.code})";

                            applyFilters();
                          },
                        ),
                      ),

                /// 🔹 Item Dropdown (NEW 🔥)
                const SizedBox(width: 10),

                /// 🔹 Search
                employeeId == null
                    ? Spacer()
                    : Expanded(
                        flex: 2,
                        child: CommonTextField(
                          controller: searchController,

                          hintText: "Search Customer...",
                          onChanged: (value) {
                            applyFilters();
                          },
                        ),
                      ),

                const SizedBox(width: 10),
                employeeId == null
                    ? Spacer()
                    : Expanded(
                        child: CommonTextField(
                          controller: fromDateController,
                          hintText: "From Date",
                          readOnly: true,
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDate: DateTime.now(),
                            );

                            if (picked != null) {
                              fromDateController.text = DateFormat(
                                "yyyy-MM-dd",
                              ).format(picked);
                              applyFilters();
                            }
                          },
                        ),
                      ),

                const SizedBox(width: 10),
                employeeId == null
                    ? Spacer()
                    : Expanded(
                        child: CommonTextField(
                          controller: toDateController,
                          hintText: "To Date",
                          readOnly: true,
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDate: DateTime.now(),
                            );

                            if (picked != null) {
                              toDateController.text = DateFormat(
                                "yyyy-MM-dd",
                              ).format(picked);
                              applyFilters();
                            }
                          },
                        ),
                      ),
              ],
            ),

            SizedBox(height: Sizes.height * .03),
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColor.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Row(
                children: [
                  _headerCell("No"),
                  _divider(),
                  _headerCell("Date"),
                  _divider(),
                  _headerCell("Customer"),
                  _divider(),
                  _headerCell("Basic"),
                  _divider(),
                  _headerCell("GST"),
                  _divider(),
                  _headerCell("Total"),
                  if (selectedType == "invoices") _divider(),
                  if (selectedType == "invoices") _headerCell("Received"),
                ],
              ),
            ),
            Expanded(
              child: filteredList.isEmpty
                  ? const Center(child: Text("No Data"))
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final isExpanded = expandedIndex == index;

                        return InkWell(
                          onDoubleTap: () {
                            setState(() {
                              expandedIndex = expandedIndex == index
                                  ? null
                                  : index;
                            });
                          },
                          child: Column(
                            children: [
                              /// 🔹 MAIN ROW
                              Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isExpanded
                                      ? Colors.green.withOpacity(.1)
                                      : Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _cell("${item['prefix']}${item['no']}"),
                                    _divider(),
                                    _cell(
                                      DateFormat("dd MMM yyyy").format(
                                        DateTime.parse(
                                          item['estimate_date'] ??
                                              item['invoice_date'] ??
                                              item['proforma_date'] ??
                                              item['dilvery_date'],
                                        ),
                                      ),
                                    ),
                                    _divider(),
                                    _cell(item['customer_name'] ?? ""),
                                    _divider(),
                                    _cell(
                                      (item['sub_totle'] ?? 0).toStringAsFixed(
                                        2,
                                      ),
                                    ),
                                    _divider(),
                                    _cell(
                                      (item['sub_gst'] ?? 0).toStringAsFixed(2),
                                    ),
                                    _divider(),
                                    _cell(
                                      "₹${(item['totle_amo'] ?? 0).toStringAsFixed(2)}",
                                    ),
                                    if (selectedType == "invoices") _divider(),
                                    if (selectedType == "invoices")
                                      _cell(
                                        "₹${getReceivedAmount("${item['prefix']}${item['no']}").toStringAsFixed(2)}",
                                      ),
                                  ],
                                ),
                              ),

                              /// 🔽 EXPANDED ITEM TABLE
                              if (isExpanded)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  color: Colors.green.withOpacity(.08),
                                  child: Column(
                                    children: [
                                      /// HEADER
                                      Row(
                                        children: [
                                          _itemHeader("Item Name"),
                                          _itemHeader("Item No"),
                                          _itemHeader("Code"),
                                          _itemHeader("Qty"),
                                          _itemHeader("Price"),
                                          _itemHeader("GST"),
                                          _itemHeader("Amount"),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      /// DATA
                                      ...(item['item_details'] ?? [])
                                          .map<Widget>((e) {
                                            return Row(
                                              children: [
                                                _itemCell(e['item_name']),
                                                _itemCell(e['item_no']),
                                                _itemCell(e['hsn_code']),
                                                _itemCell("${e['qty']}"),
                                                _itemCell("₹${e['price']}"),
                                                _itemCell(
                                                  "${e['gst_tax_rate']}%",
                                                ),
                                                _itemCell("₹${e['amount']}"),
                                              ],
                                            );
                                          })
                                          .toList(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  int? expandedIndex;

  Widget _cell(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: Colors.grey.shade300);
  }

  Widget _itemHeader(String text) {
    return Expanded(
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _itemCell(String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ItemModel {
  final String name;
  final String code;

  ItemModel({required this.name, required this.code});
}
