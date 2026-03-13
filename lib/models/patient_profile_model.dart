class PatientProfileModel {
  bool? success;
  PatientProfileData? data;

  PatientProfileModel({this.success, this.data});

  PatientProfileModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? PatientProfileData.fromJson(json['data']) : null;
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

class PatientProfileData {
  String? name;
  String? gender;
  int? age;
  String? bps;
  int? heartRate;
  int? weight;
  int? pastVisitsCount;
  int? unsubmittedReportsCount;

  PatientProfileData(
      {this.name,
      this.gender,
      this.age,
      this.bps,
      this.heartRate,
      this.weight,
      this.pastVisitsCount,
      this.unsubmittedReportsCount});

  PatientProfileData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    gender = json['gender'];
    age = json['age'];
    bps = json['bps'];
    heartRate = json['heartRate'];
    weight = json['weight'];
    pastVisitsCount = json['pastVisitsCount'];
    unsubmittedReportsCount = json['unsubmittedReportsCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['gender'] = gender;
    data['age'] = age;
    data['bps'] = bps;
    data['heartRate'] = heartRate;
    data['weight'] = weight;
    data['pastVisitsCount'] = pastVisitsCount;
    data['unsubmittedReportsCount'] = unsubmittedReportsCount;
    return data;
  }
}
