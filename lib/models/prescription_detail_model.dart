class PrescriptionDetailModel {
  bool? success;
  PrescriptionDetailData? data;

  PrescriptionDetailModel({this.success, this.data});

  PrescriptionDetailModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? PrescriptionDetailData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class PrescriptionDetailData {
  String? chiefComplaint;
  String? diagnosis;
  String? bps;
  int? heartRate;
  int? temperature;
  List<Medications>? medications;
  String? doctorsRemark;
  List<PrescribedTests>? tests;

  PrescriptionDetailData({
    this.chiefComplaint,
    this.diagnosis,
    this.bps,
    this.heartRate,
    this.temperature,
    this.medications,
    this.doctorsRemark,
    this.tests,
  });

  PrescriptionDetailData.fromJson(Map<String, dynamic> json) {
    chiefComplaint = json['chiefComplaint'];
    diagnosis = json['diagnosis'];
    bps = json['bps'];
    heartRate = json['heartRate'];
    temperature = json['temperature'];
    if (json['medications'] != null) {
      medications = <Medications>[];
      json['medications'].forEach((v) {
        medications!.add(Medications.fromJson(v));
      });
    }
    doctorsRemark = json['doctorsRemark'];
    if (json['tests'] != null) {
      tests = <PrescribedTests>[];
      json['tests'].forEach((v) {
        tests!.add(PrescribedTests.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['chiefComplaint'] = chiefComplaint;
    data['diagnosis'] = diagnosis;
    data['bps'] = bps;
    data['heartRate'] = heartRate;
    data['temperature'] = temperature;
    if (medications != null) {
      data['medications'] = medications!.map((v) => v.toJson()).toList();
    }
    data['doctorsRemark'] = doctorsRemark;
    if (tests != null) {
      data['tests'] = tests!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Medications {
  String? medicineName;
  String? dosage;
  String? frequency;
  String? duration;
  String? instructions;

  Medications({
    this.medicineName,
    this.dosage,
    this.frequency,
    this.duration,
    this.instructions,
  });

  Medications.fromJson(Map<String, dynamic> json) {
    medicineName = json['medicineName'];
    dosage = json['dosage'];
    frequency = json['frequency'];
    duration = json['duration'];
    instructions = json['instructions'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['medicineName'] = medicineName;
    data['dosage'] = dosage;
    data['frequency'] = frequency;
    data['duration'] = duration;
    data['instructions'] = instructions;
    return data;
  }
}

class PrescribedTests {
  String? testName;
  String? status;
  String? reportUrl;

  PrescribedTests({this.testName, this.status, this.reportUrl});

  PrescribedTests.fromJson(Map<String, dynamic> json) {
    testName = json['testName'];
    status = json['status'];
    reportUrl = json['reportUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['testName'] = testName;
    data['status'] = status;
    data['reportUrl'] = reportUrl;
    return data;
  }
}
