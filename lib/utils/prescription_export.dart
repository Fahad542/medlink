import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Extracts the same fields as [PrescriptionView] bottom sheet for export.
Map<String, Object?> _extractExportData(Map<String, dynamic> detail) {
  final prescription = detail['prescription'] as Map? ?? {};
  final diagnosis = prescription['diagnosis'] ?? detail['diagnosis'] ?? 'N/A';
  final notes = prescription['notes']?.toString() ?? detail['notes']?.toString();
  final medications = prescription['items'] as List? ?? prescription['medications'] as List? ?? [];
  final tests = prescription['tests'] as List? ?? [];
  final testsPending = ((detail['testsPending'] ?? 0) as num).toInt();
  final testsCount = ((detail['testsCount'] ?? 0) as num).toInt();
  final reason = detail['reason']?.toString();
  final vitals = detail['vitals'] as Map?;
  final detailDoctor = detail['doctor'] as Map? ?? {};
  final doctorName = detailDoctor['fullName']?.toString() ?? 'Doctor';
  String specialty = '';
  final specialties = detailDoctor['doctorSpecialties'] as List?;
  if (specialties != null && specialties.isNotEmpty) {
    specialty = specialties[0]['specialty']?['name']?.toString() ?? '';
  }
  final scheduledStart = detail['scheduledStart'] != null
      ? DateTime.tryParse(detail['scheduledStart'].toString())
      : (detail['appointment']?['scheduledStart'] != null
          ? DateTime.tryParse(detail['appointment']['scheduledStart'].toString())
          : null);
  final consultKind = detail['consulKind']?.toString() ?? detail['appointment']?['consulKind']?.toString() ?? '';
  final appointmentId = detail['appointmentId']?.toString() ?? detail['id']?.toString() ?? '';

  return {
    'doctorName': doctorName,
    'specialty': specialty,
    'diagnosis': diagnosis,
    'notes': notes,
    'medications': medications,
    'tests': tests,
    'testsPending': testsPending,
    'testsCount': testsCount,
    'reason': reason,
    'vitals': vitals,
    'scheduledStart': scheduledStart,
    'consultKind': consultKind,
    'appointmentId': appointmentId,
  };
}

/// Plain-text summary for WhatsApp / SMS sharing.
String buildPrescriptionPlainText(Map<String, dynamic> detail) {
  final x = _extractExportData(detail);
  final doctorName = x['doctorName']! as String;
  final specialty = x['specialty']! as String;
  final diagnosis = x['diagnosis']! as String;
  final notes = x['notes'] as String?;
  final medications = x['medications']! as List;
  final tests = x['tests']! as List;
  final testsPending = x['testsPending']! as int;
  final testsCount = x['testsCount']! as int;
  final reason = x['reason'] as String?;
  final vitals = x['vitals'] as Map?;
  final scheduledStart = x['scheduledStart'] as DateTime?;
  final consultKind = x['consultKind']! as String;
  final appointmentId = x['appointmentId']! as String;

  final buf = StringBuffer()
    ..writeln('Medlink — E-Prescription')
    ..writeln('────────────────────────');

  if (appointmentId.isNotEmpty) {
    buf.writeln('Reference: #$appointmentId');
  }
  buf.writeln('Dr. $doctorName');
  if (specialty.isNotEmpty) buf.writeln(specialty);
  if (scheduledStart != null) {
    buf.writeln(DateFormat('MMM dd, yyyy • hh:mm a').format(scheduledStart.toLocal()));
  }
  if (consultKind.isNotEmpty) buf.writeln('Consultation: $consultKind');
  buf.writeln();

  if (reason != null && reason.isNotEmpty) {
    buf.writeln('Chief complaint / reason');
    buf.writeln(reason);
    buf.writeln();
  }

  buf.writeln('Diagnosis');
  buf.writeln(diagnosis);
  buf.writeln();

  if (vitals != null) {
    buf.writeln('Vitals');
    final v = vitals;
    if (v['bpSystolic'] != null && v['bpDiastolic'] != null) {
      buf.writeln('BP: ${v['bpSystolic']}/${v['bpDiastolic']} mmHg');
    }
    if (v['heartRate'] != null) buf.writeln('Heart rate: ${v['heartRate']} bpm');
    if (v['weightKg'] != null) buf.writeln('Weight: ${v['weightKg']} kg');
    final temp = v['temperature'] ?? v['temperatureC'];
    if (temp != null) buf.writeln('Temperature: $temp °C');
    buf.writeln();
  }

  if (medications.isNotEmpty) {
    buf.writeln('Medications');
    for (final med in medications) {
      if (med is! Map) continue;
      final name = med['medicineName'] ?? med['name'] ?? '';
      final dosage = med['dosage'] ?? '';
      final frequency = med['frequency'] ?? '';
      final duration = med['duration']?.toString() ?? '';
      buf.writeln('• $name');
      if (dosage.toString().isNotEmpty || frequency.toString().isNotEmpty) {
        buf.writeln('  ${[dosage, frequency].where((e) => e.toString().isNotEmpty).join(' • ')}');
      }
      if (duration.isNotEmpty) buf.writeln('  Duration: $duration');
    }
    buf.writeln();
  }

  if (tests.isNotEmpty) {
    buf.writeln('Tests');
    for (final test in tests) {
      if (test is! Map) continue;
      final testName = test['testName'] ?? test['name'] ?? test['test'] ?? '';
      final hasReport = test['reportUrl'] != null || test['reportId'] != null;
      buf.writeln('• $testName ${hasReport ? '(report uploaded)' : '(pending)'}');
    }
  } else if (testsCount > 0) {
    buf.writeln('Tests: $testsCount total, $testsPending pending');
    buf.writeln();
  }

  if (notes != null && notes.isNotEmpty) {
    buf.writeln('Doctor\'s notes');
    buf.writeln(notes);
    buf.writeln();
  }

  buf.writeln('— Shared from Medlink');
  return buf.toString();
}

Future<Uint8List> buildPrescriptionPdfBytes(Map<String, dynamic> detail) async {
  final x = _extractExportData(detail);
  final doctorName = x['doctorName']! as String;
  final specialty = x['specialty']! as String;
  final diagnosis = x['diagnosis']! as String;
  final notes = x['notes'] as String?;
  final medications = x['medications']! as List;
  final tests = x['tests']! as List;
  final testsPending = x['testsPending']! as int;
  final testsCount = x['testsCount']! as int;
  final reason = x['reason'] as String?;
  final vitals = x['vitals'] as Map?;
  final scheduledStart = x['scheduledStart'] as DateTime?;
  final consultKind = x['consultKind']! as String;
  final appointmentId = x['appointmentId']! as String;

  final brand = PdfColor.fromInt(0xFF009688);
  final muted = PdfColors.grey700;

  pw.Widget sectionTitle(String title) => pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 10, bottom: 6),
        padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: brand, width: 3)),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11.5,
            fontWeight: pw.FontWeight.bold,
            color: brand,
            letterSpacing: 0.3,
          ),
        ),
      );

  pw.Widget card(pw.Widget child) => pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: child,
      );

  pw.Widget bodyText(String text, {double size = 10.5}) => pw.Text(
        text,
        style: pw.TextStyle(fontSize: size, height: 1.35, color: PdfColors.grey900),
      );

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: pw.BoxDecoration(
            color: brand,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'E-PRESCRIPTION',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.white,
                  letterSpacing: 1.2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Dr. $doctorName',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (specialty.isNotEmpty)
                pw.Text(specialty, style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
              if (scheduledStart != null)
                pw.Text(
                  DateFormat("MMM dd, yyyy 'at' hh:mm a").format(scheduledStart.toLocal()),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                ),
              if (consultKind.isNotEmpty)
                pw.Text(
                  consultKind,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        if (appointmentId.isNotEmpty)
          pw.Text(
            'Reference #$appointmentId',
            style: pw.TextStyle(fontSize: 9, color: muted, fontWeight: pw.FontWeight.bold),
          ),
        if (appointmentId.isNotEmpty) pw.SizedBox(height: 6),
        if (reason != null && reason.isNotEmpty) ...[
          sectionTitle('REASON FOR VISIT'),
          card(pw.Align(alignment: pw.Alignment.centerLeft, child: bodyText(reason))),
        ],
        sectionTitle('DIAGNOSIS'),
        card(bodyText(diagnosis)),
        if (vitals != null) ...[
          sectionTitle('VITALS'),
          card(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (vitals['bpSystolic'] != null && vitals['bpDiastolic'] != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: bodyText(
                      'Blood pressure  ${vitals['bpSystolic']}/${vitals['bpDiastolic']} mmHg',
                    ),
                  ),
                if (vitals['heartRate'] != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: bodyText('Heart rate  ${vitals['heartRate']} bpm'),
                  ),
                if (vitals['weightKg'] != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: bodyText('Weight  ${vitals['weightKg']} kg'),
                  ),
                if (vitals['temperature'] != null || vitals['temperatureC'] != null)
                  bodyText(
                    'Temperature  ${vitals['temperature'] ?? vitals['temperatureC']} deg C',
                  ),
              ],
            ),
          ),
        ],
        if (medications.isNotEmpty) ...[
          sectionTitle('MEDICATIONS'),
          ...medications.map<pw.Widget>((med) {
            if (med is! Map) return pw.SizedBox();
            final name = med['medicineName'] ?? med['name'] ?? '';
            final dosage = med['dosage'] ?? '';
            final frequency = med['frequency'] ?? '';
            final line2 = [dosage, frequency]
                .where((e) => e.toString().isNotEmpty)
                .join(', ');
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: card(
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    bodyText(name.toString(), size: 11),
                    if (line2.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                          line2,
                          style: pw.TextStyle(fontSize: 10, color: brand, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
        if (tests.isNotEmpty) ...[
          sectionTitle('TESTS REQUIRED'),
          ...tests.map<pw.Widget>((test) {
            if (test is! Map) return pw.SizedBox();
            final testName = test['testName'] ?? test['name'] ?? test['test'] ?? '';
            final hasReport = test['reportUrl'] != null || test['reportId'] != null;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: card(
                bodyText(
                  '$testName  (${hasReport ? 'report uploaded' : 'pending'})',
                ),
              ),
            );
          }),
        ] else if (testsCount > 0) ...[
          sectionTitle('TESTS'),
          card(
            bodyText('Total $testsCount - $testsPending pending upload'),
          ),
        ],
        if (notes != null && notes.isNotEmpty) ...[
          sectionTitle('DOCTOR\'S NOTES'),
          card(bodyText(notes)),
        ],
        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Text(
            'Generated by Medlink',
            style: pw.TextStyle(fontSize: 8, color: muted),
          ),
        ),
      ],
    ),
  );

  return doc.save();
}
