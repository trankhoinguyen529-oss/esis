class UserAccountItem {
  final String id;
  final String userId;
  final String accountNumber;
  final String bankName;
  final String accountName;
  final double balance;
  final String currency;

  const UserAccountItem({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.bankName,
    required this.accountName,
    required this.balance,
    required this.currency,
  });

  factory UserAccountItem.fromJson(Map<String, dynamic> json) {
    return UserAccountItem(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'VND',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'accountNumber': accountNumber,
        'bankName': bankName,
        'accountName': accountName,
        'balance': balance,
        'currency': currency,
      };
}
