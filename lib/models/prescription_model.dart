class PrescriptionModel {
  final String id;
  final String doctorName;
  final DateTime date;
  final List<String> medications;
  final String instructions;
  final String? pdfUrl;

  PrescriptionModel({
    required this.id,
    required this.doctorName,
    required this.date,
    required this.medications,
    required this.instructions,
    this.pdfUrl,
  });
}
