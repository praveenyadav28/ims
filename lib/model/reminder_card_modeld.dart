class ReminderCardModel {
  final String customerId;
  final String name;
  final String remark;
  final int mobile;
  final int recieptNo;
  final String prefix;
  final DateTime reminderDate;
  final int closingBalance;

  ReminderCardModel({
    required this.customerId,
    required this.name,
    required this.remark,
    required this.mobile,
    required this.recieptNo,
    required this.prefix,
    required this.reminderDate,
    required this.closingBalance,
  });
}
