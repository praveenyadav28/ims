class ReminderCardModel {
  final String customerId;
  final String name;
  final DateTime reminderDate;
  final int closingBalance;

  ReminderCardModel({
    required this.customerId,
    required this.name,
    required this.reminderDate,
    required this.closingBalance,
  });
}
