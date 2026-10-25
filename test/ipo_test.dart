import 'package:flutter_test/flutter_test.dart';
import 'package:ipo_pay_simulator/controllers/ipo_controller.dart';
import 'package:ipo_pay_simulator/data/ipo_repository.dart';
import 'package:ipo_pay_simulator/models/ipo.dart';

// Fake repository for tests: no SharedPreferences, no phone needed.
class FakeIpoRepository implements IpoRepository {
  List<IpoApplication> stored = [];
  int balance = 200000;

  @override
  Future<List<IpoApplication>> loadApplications() async => List.of(stored);

  @override
  Future<void> saveApplications(List<IpoApplication> apps) async {
    stored = List.of(apps);
  }

  @override
  Future<int> loadBalance() async => balance;

  @override
  Future<void> saveBalance(int value) async {
    balance = value;
  }
}

void main() {
  final jio = IpoController.ipos.firstWhere((ipo) => ipo.id == 'jio');

  test('One Jio lot costs 12 x 1119 = 13428, as in the reel', () {
    expect(jio.oneLotAmount, 13428);
    expect(jio.amountForLots(2), 26856);
  });

  test('PAN validation accepts the reel format and rejects bad PANs', () {
    expect(isValidPan('ABCDE1234F'), isTrue);
    expect(isValidPan('ABCDE1234'), isFalse);
    expect(isValidPan('abcde1234f'), isFalse);
    expect(isValidPan(''), isFalse);
  });

  test('Applying blocks money but does not debit it', () async {
    final controller = IpoController(FakeIpoRepository());
    await controller.load();
    final ok = await controller.apply(
      ipo: jio,
      broker: 'Zerodha',
      pan: 'ABCDE1234F',
      lots: 1,
    );
    expect(ok, isTrue);
    expect(controller.balance, 200000);
    expect(controller.blockedAmount, 13428);
    expect(controller.availableBalance, 200000 - 13428);
  });

  test('Same PAN, same IPO, different broker is rejected', () async {
    final controller = IpoController(FakeIpoRepository());
    await controller.load();
    await controller.apply(
      ipo: jio,
      broker: 'Zerodha',
      pan: 'ABCDE1234F',
      lots: 1,
    );
    final second = await controller.apply(
      ipo: jio,
      broker: 'Groww',
      pan: 'ABCDE1234F',
      lots: 1,
    );
    expect(second, isFalse);
    expect(controller.applications.length, 1);
  });

  test('Allotment debits winners and unblocks losers', () async {
    final controller = IpoController(FakeIpoRepository());
    await controller.load();
    await controller.apply(
      ipo: jio,
      broker: 'Zerodha',
      pan: 'ABCDE1234F',
      lots: 1,
    );
    await controller.runAllotment(decide: (_) => true);
    expect(controller.applications.first.status, ApplicationStatus.allotted);
    expect(controller.balance, 200000 - 13428);
    expect(controller.blockedAmount, 0);

    await controller.apply(
      ipo: jio,
      broker: 'Groww',
      pan: 'FGHIJ5678K',
      lots: 1,
    );
    await controller.runAllotment(decide: (_) => false);
    expect(controller.applications.last.status, ApplicationStatus.unblocked);
    expect(controller.availableBalance, 200000 - 13428);
  });
}
