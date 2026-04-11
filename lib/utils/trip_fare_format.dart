import 'package:intl/intl.dart';

/// Parses fare from trip / payment JSON (multiple backend shapes) and formats West African CFA.
class TripFareFormat {
  TripFareFormat._();

  static const String _defaultCfaSuffix = 'CFA';

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  /// Best-effort amount in major currency units (not cents), first positive match wins.
  static double? parseAmount(Map<String, dynamic> json) {
    double? useIfPositive(double? v) {
      if (v == null || v <= 0 || !v.isFinite) return null;
      return v;
    }

    double? fromMap(Map<String, dynamic> m) {
      const keys = [
        'fareAmount',
        'totalFare',
        'totalAmount',
        'tripFare',
        'fare',
        'amount',
        'price',
        'finalAmount',
        'grandTotal',
        'total',
        'driverEarning',
        'driverEarnings',
        'earningAmount',
        'earnings',
        'payoutAmount',
        'invoiceTotal',
      ];
      for (final k in keys) {
        final v = useIfPositive(_toDouble(m[k]));
        if (v != null) return v;
      }
      final pay = m['payment'];
      if (pay is Map) {
        final pm = Map<String, dynamic>.from(pay);
        for (final k in ['amount', 'total', 'fareAmount', 'paidAmount']) {
          final v = useIfPositive(_toDouble(pm[k]));
          if (v != null) return v;
        }
      }
      return null;
    }

    final direct = fromMap(json);
    if (direct != null) return direct;

    final trip = json['trip'];
    if (trip is Map) {
      final nested = fromMap(Map<String, dynamic>.from(trip));
      if (nested != null) return nested;
    }

    final sos = json['sos'];
    if (sos is Map) {
      final nested = fromMap(Map<String, dynamic>.from(sos));
      if (nested != null) return nested;
    }

    return null;
  }

  /// Human-readable CFA (XOF-style grouping). Uses backend `currency` when it is CFA/XOF.
  static String formatCfa(double amount, {String? currencyHint}) {
    final c = (currencyHint ?? '').toUpperCase();
    final useCfa = c.isEmpty ||
        c == 'XOF' ||
        c == 'CFA' ||
        c.contains('CFA');
    if (!useCfa && c.isNotEmpty) {
      final fmt = NumberFormat('#,##0.##', 'fr_FR');
      return '${fmt.format(amount)} $c';
    }
    final fmt = NumberFormat('#,##0', 'fr_FR');
    return '${fmt.format(amount.round())} $_defaultCfaSuffix';
  }

  /// List / card label: `1 500 F CFA` or `—` when unknown / zero.
  static String display(Map<String, dynamic> json) {
    final v = parseAmount(json);
    if (v == null) return '—';
    final cur = json['currency']?.toString() ??
        json['fareCurrency']?.toString() ??
        (json['payment'] is Map
            ? (json['payment'] as Map)['currency']?.toString()
            : null);
    return formatCfa(v, currencyHint: cur);
  }

  /// First positive amount among known keys (for fare breakdown lines).
  static double? amountForKeys(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = _toDouble(json[k]);
      if (v != null && v > 0 && v.isFinite) return v;
    }
    return null;
  }
}
