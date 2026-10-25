# IPO Pay Simulator

A Flutter app that teaches how IPO payment really works, inspired by
the @ashmit.codes reel about the Jio IPO payment flow.

## The idea (from the reel)

In an IPO, your money is NOT debited when you apply. A UPI mandate
(ASBA) only BLOCKS the amount. On allotment day:

- Shares allotted -> only that amount is debited
- No shares allotted -> the block is released (unblocked)

This is two-phase payment: first authorize (block), later capture
(debit) - only on allotment.

The reel ends with a question: what happens if you apply with the
same PAN via Zerodha and Groww? Answer, built into this app:
the second application is rejected. One PAN = one application
per IPO, even via different brokers.

## Features

- IPO list, including Jio Platforms Ltd with the reel's figures:
  issue size Rs 30,213 Cr, price band Rs 1,065-1,119, lot 12 shares,
  1 lot = Rs 13,428 at the upper band
- Apply with broker, PAN and lots; the amount is blocked, not debited
- Balance / Blocked / Available money shown at all times
- Run Allotment Day: winners get debited, losers get unblocked
- PAN duplicate check across brokers (the reel's quiz question)
- Learn tab: the two-phase flow, the Jio timeline, and the PAN rule
- Applications saved on the device with SharedPreferences

Demo note: this is a simulator for learning. It does not place
real IPO orders or move real money.

## Architecture

```
lib/
  main.dart                    Thin entry point
  models/ipo.dart              IPO + application models, PAN check
  data/ipo_repository.dart     Repository pattern (storage)
  controllers/ipo_controller.dart  All business logic
  screens/home_screen.dart     UI only: IPOs, Applications, Learn
test/
  ipo_test.dart                Unit tests for money logic
```

## How to run it

1. Install the Flutter SDK, then check it with `flutter doctor`
2. Open this folder in VS Code (or a terminal inside it)
3. `flutter pub get`
4. `flutter run`

## How to check quality

```
flutter analyze
flutter test
```
