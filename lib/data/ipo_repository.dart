import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ipo.dart';

// Repository pattern: the UI only talks to this abstract class,
// never directly to SharedPreferences.
abstract class IpoRepository {
  Future<List<IpoApplication>> loadApplications();
  Future<void> saveApplications(List<IpoApplication> applications);
  Future<int> loadBalance();
  Future<void> saveBalance(int balance);
}

class SharedPreferencesIpoRepository implements IpoRepository {
  static const String _applicationsKey = 'ipo_applications_v1';
  static const String _balanceKey = 'ipo_demo_balance_v1';
  static const int _startingBalance = 200000;

  @override
  Future<List<IpoApplication>> loadApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_applicationsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => IpoApplication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveApplications(List<IpoApplication> applications) async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        jsonEncode(applications.map((item) => item.toJson()).toList());
    await prefs.setString(_applicationsKey, raw);
  }

  @override
  Future<int> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_balanceKey) ?? _startingBalance;
  }

  @override
  Future<void> saveBalance(int balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, balance);
  }
}
