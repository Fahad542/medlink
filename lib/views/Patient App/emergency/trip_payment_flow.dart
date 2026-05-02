import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/views/Patient%20App/emergency/emergency_viewmodel.dart';
import 'package:medlink/utils/utils.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

/// Cash vs card for completed ambulance trip — can be shown from any route (e.g. [MainScreen] socket listener).
Future<void> showTripPaymentPromptDialog(
  BuildContext context,
  TripPaymentPromptEvent event,
) async {
  final api = ApiServices();

  Future<void> cashFlow() async {
    final emergencyVM = Provider.of<EmergencyViewModel>(context, listen: false);
    Navigator.of(context).pop();
    try {
      await api.patientTripPaymentCash(event.tripId);
      if (context.mounted) {
        await emergencyVM.markTripPaymentSettled(event.tripId);
        if (!context.mounted) return;
        Utils.toastMessage(
          context,
          'Recorded. Please pay your driver in cash.',
        );
      }
    } catch (e) {
      if (context.mounted) Utils.toastError(context, e);
    }
  }

  Future<void> cardFlow() async {
    Navigator.of(context).pop();
    if (!context.mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => TripStripePaymentPage(
          tripId: event.tripId,
          titleSuffix:
              event.fareAmount > 0 ? '${event.fareAmount.toStringAsFixed(0)} ${event.currency}' : null,
        ),
      ),
    );
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Trip completed'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.driverName != null &&
              event.driverName!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Driver: ${event.driverName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          Text(
            event.fareAmount > 0
                ? 'Pay ${event.fareAmount.toStringAsFixed(0)} ${event.currency}'
                : 'How would you like to settle?',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: cashFlow,
          child: const Text('Cash'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: cardFlow,
          child: const Text('Pay online'),
        ),
      ],
    ),
  );
}

/// Loads Stripe Payment Sheet for trip fare and confirms with backend (no appointment booking).
class TripStripePaymentPage extends StatefulWidget {
  final String tripId;
  final String? titleSuffix;

  const TripStripePaymentPage({
    super.key,
    required this.tripId,
    this.titleSuffix,
  });

  @override
  State<TripStripePaymentPage> createState() => _TripStripePaymentPageState();
}

class _TripStripePaymentPageState extends State<TripStripePaymentPage> {
  bool _busy = true;
  String? _error;

  /// Backend responses can be:
  /// - { success: true, data: { paymentIntent, ... } }
  /// - { success: true, data: { success: true, data: { paymentIntent, ... } } }
  Map<String, dynamic>? _extractStripePayload(dynamic response) {
    if (response is! Map) return null;
    final root = Map<String, dynamic>.from(response);

    bool hasStripeKeys(Map<String, dynamic> m) =>
        m['paymentIntent'] != null &&
        m['ephemeralKey'] != null &&
        m['customer'] != null;

    if (hasStripeKeys(root)) return root;

    final data = root['data'];
    if (data is Map) {
      final d1 = Map<String, dynamic>.from(data);
      if (hasStripeKeys(d1)) return d1;

      final innerData = d1['data'];
      if (innerData is Map) {
        final d2 = Map<String, dynamic>.from(innerData);
        if (hasStripeKeys(d2)) return d2;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_run);
  }

  Future<void> _run() async {
    try {
      final res = await ApiServices().patientTripPaymentCheckout(widget.tripId);
      final stripePayload = _extractStripePayload(res);
      if (stripePayload == null) {
        throw Exception('Invalid checkout response');
      }
      await _presentStripe(stripePayload);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (_isStripeUserCancelled(e)) {
        if (mounted) Navigator.of(context).pop(false);
        return;
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _presentStripe(Map<String, dynamic> paymentData) async {
    final emergencyVM = Provider.of<EmergencyViewModel>(context, listen: false);
    final pIntentRaw = paymentData['paymentIntent'];
    final eKeyRaw = paymentData['ephemeralKey'];
    final customerRaw = paymentData['customer'];
    final publishableKeyRaw = paymentData['publishableKey'];

    if (pIntentRaw == null || eKeyRaw == null || customerRaw == null) {
      throw Exception('Missing Stripe payment data');
    }

    final paymentIntent = pIntentRaw.toString();
    final ephemeralKey = eKeyRaw.toString();
    final customer = customerRaw.toString();
    final publishableKey = publishableKeyRaw?.toString();

    if (publishableKey != null && publishableKey.isNotEmpty) {
      Stripe.publishableKey = publishableKey;
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntent,
        customerEphemeralKeySecret: ephemeralKey,
        customerId: customer,
        merchantDisplayName: 'MedLink Africa',
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: AppColors.primary,
          ),
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    final paymentIntentId = paymentIntent.split('_secret_')[0];
    final confirm = await ApiServices()
        .patientTripPaymentConfirmOnline(widget.tripId, paymentIntentId);

    if (confirm is Map && confirm['success'] == true) {
      if (mounted) {
        await emergencyVM.markTripPaymentSettled(widget.tripId);
        if (!mounted) return;
        Utils.toastMessage(context, 'Payment successful. Thank you!');
      }
    } else {
      throw Exception('Could not confirm payment');
    }
  }

  bool _isStripeUserCancelled(Object e) {
    if (e is StripeException) {
      return e.error.code == FailureCode.Canceled;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titleSuffix != null
              ? 'Pay ${widget.titleSuffix}'
              : 'Trip payment',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _busy
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Preparing secure payment…'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'Something went wrong',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Close'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
