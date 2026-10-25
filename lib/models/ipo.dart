// IPO and application models. Pure Dart, no Flutter dependency,
// so the money logic is easy to unit test.
//
// The two-phase payment idea comes from the reel: in an IPO,
// money is NOT debited when you apply. A UPI mandate (ASBA)
// only BLOCKS the amount. On allotment day, shares allotted
// means that amount is debited; no allotment means the block
// is released (unblocked).

enum ApplicationStatus { blocked, allotted, unblocked, rejected }

extension ApplicationStatusLabel on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.blocked:
        return 'Blocked';
      case ApplicationStatus.allotted:
        return 'Allotted — Debited';
      case ApplicationStatus.unblocked:
        return 'Unblocked';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }
}

class Ipo {
  const Ipo({
    required this.id,
    required this.name,
    required this.issueSize,
    required this.priceLow,
    required this.priceHigh,
    required this.lotSize,
    required this.openLabel,
    required this.closeLabel,
    required this.allotmentLabel,
    required this.unblockLabel,
    required this.listingLabel,
    this.isSample = false,
  });

  final String id;
  final String name;
  final String issueSize;
  final int priceLow;
  final int priceHigh;
  final int lotSize;
  final String openLabel;
  final String closeLabel;
  final String allotmentLabel;
  final String unblockLabel;
  final String listingLabel;
  final bool isSample;

  // Amount for one lot at the upper price band, exactly the
  // figure shown in the reel for Jio: 12 shares x Rs 1,119.
  int get oneLotAmount => lotSize * priceHigh;

  int amountForLots(int lots) => lots * oneLotAmount;
}

class IpoApplication {
  IpoApplication({
    required this.id,
    required this.ipoId,
    required this.ipoName,
    required this.broker,
    required this.pan,
    required this.lots,
    required this.amount,
    this.status = ApplicationStatus.blocked,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String ipoId;
  final String ipoName;
  final String broker;
  final String pan;
  final int lots;
  final int amount;
  final ApplicationStatus status;
  final DateTime createdAt;

  String get maskedPan {
    if (pan.length < 5) return pan;
    return '${pan.substring(0, 5)}*****';
  }

  IpoApplication copyWith({ApplicationStatus? status}) {
    return IpoApplication(
      id: id,
      ipoId: ipoId,
      ipoName: ipoName,
      broker: broker,
      pan: pan,
      lots: lots,
      amount: amount,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ipoId': ipoId,
      'ipoName': ipoName,
      'broker': broker,
      'pan': pan,
      'lots': lots,
      'amount': amount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory IpoApplication.fromJson(Map<String, dynamic> json) {
    return IpoApplication(
      id: json['id'] as String,
      ipoId: json['ipoId'] as String,
      ipoName: json['ipoName'] as String,
      broker: json['broker'] as String,
      pan: json['pan'] as String,
      lots: json['lots'] as int,
      amount: json['amount'] as int,
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ApplicationStatus.blocked,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

// PAN format: 5 letters, 4 digits, 1 letter, e.g. ABCDE1234F.
bool isValidPan(String pan) {
  return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan.trim());
}
