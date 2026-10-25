import 'package:flutter/material.dart';

import '../controllers/ipo_controller.dart';
import '../models/ipo.dart';

// The screen only renders state and forwards taps to the
// controller. No business logic lives here.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final IpoController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _showApplyDialog(Ipo ipo) async {
    final panController = TextEditingController();
    String broker = IpoController.brokers.first;
    int lots = 1;

    final applied = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Apply: ${ipo.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price band: Rs ${ipo.priceLow} - Rs ${ipo.priceHigh}  ·  '
                      'Lot: ${ipo.lotSize} shares',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: broker,
                      decoration: const InputDecoration(
                        labelText: 'Broker',
                        border: OutlineInputBorder(),
                      ),
                      items: IpoController.brokers.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => broker = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: panController,
                      decoration: const InputDecoration(
                        labelText: 'PAN (e.g. ABCDE1234F)',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Lots: '),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: lots > 1
                              ? () => setDialogState(() => lots--)
                              : null,
                        ),
                        Text('$lots'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setDialogState(() => lots++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount to be BLOCKED (not debited): '
                      'Rs ${ipo.amountForLots(lots)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'This money stays in your account, only blocked. '
                      'It is debited only if shares are allotted.',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Apply & Block'),
                ),
              ],
            );
          },
        );
      },
    );

    if (applied == true) {
      final ok = await widget.controller.apply(
        ipo: ipo,
        broker: broker,
        pan: panController.text,
        lots: lots,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Applied! Rs ${ipo.amountForLots(lots)} blocked via UPI mandate.'
                : (widget.controller.lastError ?? 'Application failed.'),
          ),
        ),
      );
    }
    panController.dispose();
  }

  Color _statusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.blocked:
        return Colors.orange;
      case ApplicationStatus.allotted:
        return Colors.green;
      case ApplicationStatus.unblocked:
        return Colors.blue;
      case ApplicationStatus.rejected:
        return Colors.red;
    }
  }

  Widget _balanceCard(IpoController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _moneyColumn('Balance', controller.balance),
            _moneyColumn('Blocked', controller.blockedAmount),
            _moneyColumn('Available', controller.availableBalance),
          ],
        ),
      ),
    );
  }

  Widget _moneyColumn(String label, int amount) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          'Rs $amount',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _iposTab(IpoController controller) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _balanceCard(controller),
        const SizedBox(height: 16),
        const Text(
          'IPOs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...IpoController.ipos.map((ipo) {
          return Card(
            child: ListTile(
              title: Text(ipo.name),
              subtitle: Text(
                '${ipo.issueSize}\n'
                'Price: Rs ${ipo.priceLow}-${ipo.priceHigh}  ·  '
                'Lot: ${ipo.lotSize} shares  ·  '
                '1 lot = Rs ${ipo.oneLotAmount}'
                '${ipo.isSample ? '\nSample IPO for practice' : ''}',
              ),
              isThreeLine: true,
              trailing: FilledButton(
                onPressed: () => _showApplyDialog(ipo),
                child: const Text('Apply'),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _applicationsTab(IpoController controller) {
    final apps = controller.applications;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _balanceCard(controller),
        const SizedBox(height: 16),
        if (controller.blockedApplications.isNotEmpty)
          FilledButton.icon(
            onPressed: () async {
              await controller.runAllotment();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Allotment day done!')),
              );
            },
            icon: const Icon(Icons.event),
            label: const Text('Run Allotment Day'),
          ),
        const SizedBox(height: 8),
        if (apps.isNotEmpty)
          TextButton(
            onPressed: controller.clearHistory,
            child: const Text('Reset demo (clear history)'),
          ),
        const SizedBox(height: 8),
        if (apps.isEmpty)
          const Center(
            child: Text('No applications yet. Apply for an IPO first!'),
          ),
        ...apps.map((app) {
          return Card(
            child: ListTile(
              title: Text('${app.ipoName} — ${app.lots} lot(s)'),
              subtitle: Text(
                '${app.broker}  ·  PAN ${app.maskedPan}\nRs ${app.amount}',
              ),
              trailing: Chip(
                label: Text(app.status.label),
                backgroundColor:
                    _statusColor(app.status).withOpacity(0.2),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _learnTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'How IPO payment really works',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          '1. You apply: you choose an IPO, lots and broker, and '
          'approve a UPI mandate (ASBA).',
        ),
        SizedBox(height: 8),
        Text(
          '2. Money is BLOCKED, not debited. It stays in your '
          'bank account, but you cannot spend it.',
        ),
        SizedBox(height: 8),
        Text(
          '3. Allotment day: if you get shares, only that amount '
          'is debited. If you get no shares, the whole block is '
          'released and your money is free again.',
        ),
        SizedBox(height: 8),
        Text(
          'This is called two-phase payment: first authorize '
          '(block), later capture (debit) - only on allotment.',
        ),
        SizedBox(height: 16),
        Text(
          'Jio IPO timeline (from the reel)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('21 Oct: IPO opens'),
        Text('23 Oct: IPO closes'),
        Text('28 Oct: Allotment'),
        Text('29 Oct: Unblock / debit'),
        Text('30 Oct: Listing'),
        SizedBox(height: 16),
        Text(
          'One PAN, two brokers?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Applying for the same IPO with the same PAN via '
          'Zerodha and Groww does NOT give you two chances. '
          'The exchange rejects duplicate PAN applications for '
          'the same IPO. One PAN = one application per IPO. '
          'Try it in this app: apply twice with the same PAN '
          'and the second one is rejected.',
        ),
        SizedBox(height: 16),
        Text(
          'Demo note: this app is a simulator for learning. '
          'It does not place real IPO orders or move real money.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return Scaffold(
          appBar: AppBar(
            title: const Text('IPO Pay Simulator'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tab == 0
                  ? _iposTab(controller)
                  : _tab == 1
                      ? _applicationsTab(controller)
                      : _learnTab(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (index) => setState(() => _tab = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'IPOs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt),
                label: 'My Applications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'Learn',
              ),
            ],
          ),
        );
      },
    );
  }
}
