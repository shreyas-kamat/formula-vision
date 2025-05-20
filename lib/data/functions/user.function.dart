// All Imports
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// NOTE: Only use for Double values
Future<int> setFieldValue(String field, double value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? bearer = prefs.getString('jwt_token');
  String? userId = prefs.getString('user_id');

  var url = Uri.parse('${dotenv.env['API_URL']}/api/v1/users/$userId/$field');
  var response = await http.put(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $bearer',
    },
    body: jsonEncode({"value": value}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final newValue = double.parse(data[field]);
    print('$field: $newValue');
    return response.statusCode;
  } else {
    print('Failed to set $field');
    print(response.statusCode);
    return response.statusCode;
  }
}

Future<double> fetchCurrentBalance() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? bearer = prefs.getString('jwt_token');
  String? userId = prefs.getString('user_id');

  var url = Uri.parse(
      '${dotenv.env['API_URL']}/api/v1/users/$userId/current_balance');
  var response = await http.get(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $bearer',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final balance = data['current_balance']?.toDouble() ?? 0.0;
    print('Current Balance: $balance');
    return balance;
  } else {
    print('Failed to load current balance');
    return 0.0; // Return a default value in case of failure
  }
}

Future<double> fetchLastTransaction() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? bearer = prefs.getString('jwt_token');
  String? userId = prefs.getString('user_id');

  var url = Uri.parse(
      '${dotenv.env['API_URL']}/api/v1/transactions/last?userId=$userId');
  var response = await http.get(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $bearer',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final amount = data['amount']?.toDouble() ?? 0.0;
    print('Last Transaction Amount: $amount');
    return amount;
  } else {
    print('Failed to load last transaction');
    return 0.0; // Return a default value in case of failure
  }
}

Future<void> updateBalance(String userId, double amount, bool isDebit) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? bearer = prefs.getString('jwt_token');

  final finalBalance = isDebit
      ? await fetchCurrentBalance() - amount
      : await fetchCurrentBalance() + amount;

  var url =
      Uri.parse('${dotenv.env['API_URL']}/api/v1/users/1/current_balance');
  var response = await http.put(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $bearer',
    },
    body: jsonEncode({'value': finalBalance}),
  );

  if (response.statusCode == 200) {
    // Balance updated successfully
    print('Balance updated successfully');
  } else {
    // Handle error
    print('Error updating balance: ${response.body}');
  }
}
