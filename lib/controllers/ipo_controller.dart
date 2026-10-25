import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/ipo_repository.dart';
import '../models/ipo.dart';

// All business logic lives here, not in the widgets.
class IpoController extends ChangeNotifier {
  IpoController(this._repository);

  final IpoRepository _repository;
  List<IpoApplication> _applications = [];
  int _balance = 0;
  bool _isLoading = true;
  String? _lastError;

  List<IpoApplication> get applications =>
      List.unmodifiable(_applications);
  int get balance => _balance;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // Money currently blocked by pending (Blocked) applications.
  int get blockedAmount => _applications
      .where((item) => item.status == ApplicationStatus.blocked)
      .fold(0, (sum, item) => sum + item.amount);

  // Money actually available to spend right now.
  int get availableBalance => _balance - blockedAmount;

  List<IpoApplication> get blockedApplications => _applications
      .where((item) => item.status == ApplicationStatus.blocked)
      .toList();

  static const List<Ipo> ipos = [
    Ipo(
      id: 'jio',
      name: 'Jio Platforms Ltd',
      issueSize: 'Rs 30,213 Cr',
      priceLow: 1065,
      priceHigh: 1119,
      lotSize: 12,
      openLabel: '21 Oct',
      closeLabel: '23 Oct',
      allotmentLabel: '28 Oct',
      unblockLabel: '29 Oct',
      listingLabel: '30 Oct',
    ),
    Ipo(
      id: 'sample-a',
      name: 'Sample IPO A',
      issueSize: 'Rs 500 Cr (sample)',
      priceLow: 100,
      priceHigh: 110,
      lotSize: 15,
      openLabel: 'Day 1',
      closeLabel: 'Day 3',
      allotmentLabel: 'Day 6',
      unblockLabel: 'Day 7',
      listingLabel: 'Day 8',
      isSample: true,
    ),
    Ipo(
      id: 'sample-b',
      name: 'Sample IPO B',
      issueSize: 'Rs 1,200 Cr (sample)',
      priceLow: 240,
      priceHigh: 250,
      lotSize: 20,
      openLabel: 'Day 1',
      closeLabel: 'Day 3',
      allotmentLabel: 'Day 6',
      unblockLabel: 'Day 7',
      listingLabel: 'Day 8',
      isSample: true,
    ),
  ];

  static const List<String> brokers = [
    'Zerodha',
    'Groww',
    'Upstox',
    'Angel One',
  ];

  Future<void> load() async {
    _applications = await _repository.loadApplications();
    _balance = await _repository.loadBalance();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _repository.saveApplications(_applications);
    await _repository.saveBalance(_balance);
  }

  // Returns true if the application was accepted (blocked).
  // A second application with the same PAN for the same IPO
  // is rejected - this is the answer to the reel's final
  // question: one PAN, two brokers, same IPO does not work.
  Future<bool> apply({
    required Ipo ipo,
    required String broker,
    required String pan,
    required int lots,
  }) async {
    _lastError = null;
    final cleanPan = pan.trim().toUpperCase();
    if (!isValidPan(cleanPan)) {
      _lastError = 'PAN format is wrong. Use 5 letters, 4 digits, 1 letter.';
      notifyListeners();
      return false;
    }
    final duplicate = _applications.any(
      (item) =>
          item.ipoId == ipo.id &&
          item.pan == cleanPan &&
          item.status != ApplicationStatus.rejected,
    );
    if (duplicate) {
      _lastError =
          'Rejected: this PAN already applied for ${ipo.name}. '
          'One PAN gets only one application per IPO, even via a different broker.';
      notifyListeners();
      return false;
    }
    final amount = ipo.amountForLots(lots);
    if (amount > availableBalance) {
      _lastError = 'Not enough available balance for Rs $amount blocked.';
      notifyListeners();
      return false;
    }
    _applications.add(
      IpoApplication(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        ipoId: ipo.id,
        ipoName: ipo.name,
        broker: broker,
        pan: cleanPan,
        lots: lots,
        amount: amount,
      ),
    );
    notifyListeners();
    await _persist();
    return true;
  }

  // Simulates allotment day for every blocked application.
  // [decide] is only for tests; in the app it is a coin flip.
  Future<void> runAllotment({bool Function(IpoApplication)? decide}) async {
    final random = Random();
    _applications = _applications.map((item) {
      if (item.status != ApplicationStatus.blocked) return item;
      final allotted = decide != null ? decide(item) : random.nextBool();
      if (allotted) {
        // Capture: the blocked money is actually debited.
        _balance -= item.amount;
        return item.copyWith(status: ApplicationStatus.allotted);
      }
      // No allotment: the block is released, money never left.
      return item.copyWith(status: ApplicationStatus.unblocked);
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> clearHistory() async {
    _applications = [];
    _balance = 200000;
    notifyListeners();
    await _persist();
  }
}
