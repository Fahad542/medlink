class PatientAppointmentHistoryModel {
  bool? success;
  List<PatientAppointmentHistoryData>? data;

  PatientAppointmentHistoryModel({this.success, this.data});

  PatientAppointmentHistoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <PatientAppointmentHistoryData>[];
      json['data'].forEach((v) {
        data!.add(PatientAppointmentHistoryData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PatientAppointmentHistoryData {
  int? appointmentId;
  String? patientName;
  String? appointmentName;
  String? chiefComplaint;
  String? date;

  PatientAppointmentHistoryData({
    this.appointmentId,
    this.patientName,
    this.appointmentName,
    this.chiefComplaint,
    this.date,
  });

  PatientAppointmentHistoryData.fromJson(Map<String, dynamic> json) {
    appointmentId = json['appointmentId'];
    patientName = json['patientName'];
    appointmentName = json['appointmentName'];
    chiefComplaint = json['chiefComplaint'];
    date = json['date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appointmentId'] = appointmentId;
    data['patientName'] = patientName;
    data['appointmentName'] = appointmentName;
    data['chiefComplaint'] = chiefComplaint;
    data['date'] = date;
    return data;
  }
}
