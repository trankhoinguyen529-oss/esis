class WalletItem {
  final int? id;
  final String userId;
  final String name;
  final String type;
  final double balance;
  final bool isDefault;

  const WalletItem({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.isDefault,
  });

  factory WalletItem.fromJson(Map<String, dynamic> json) {
    return WalletItem(
      id: json['id'] as int?,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      isDefault: (json['isDefault'] ?? json['default']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'userId': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'isDefault': isDefault,
      'default': isDefault,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
