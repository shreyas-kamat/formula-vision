class User {
  final String id;
  final String name;
  final String email;
  final double currentBalance;
  final double lastTransactionAmount;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.currentBalance,
    required this.lastTransactionAmount,
  });

  // Factory constructor to create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      currentBalance: (json['current_balance'] as num).toDouble(),
      lastTransactionAmount:
          (json['last_transaction_amount'] as num).toDouble(),
    );
  }

  // Method to convert a User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'current_balance': currentBalance,
      'last_transaction_amount': lastTransactionAmount,
    };
  }
}
