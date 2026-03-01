class UserLoginModel {
  bool? success;
  Data? data;

  UserLoginModel({this.success, this.data});

  UserLoginModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
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

class Data {
  User? user;
  String? accessToken;

  Data({this.user, this.accessToken});

  Data.fromJson(Map<String, dynamic> json) {
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    accessToken = json['access_token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['access_token'] = accessToken;
    return data;
  }
}

class User {
  int? id;
  String? role;
  String? fullName;
  String? email;
  String? phone;
  bool? isActive;
  bool? isVerified;
  String? profilePhotoUrl;
  String? createdAt;
  String? updatedAt;

  User({
    this.id,
    this.role,
    this.fullName,
    this.email,
    this.phone,
    this.isActive,
    this.isVerified,
    this.profilePhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    role = json['role'];
    fullName = json['fullName'];
    email = json['email'];
    phone = json['phone'];
    isActive = json['isActive'];
    isVerified = json['isVerified'];
    profilePhotoUrl = json['profilePhotoUrl'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['role'] = role;
    data['fullName'] = fullName;
    data['email'] = email;
    data['phone'] = phone;
    data['isActive'] = isActive;
    data['isVerified'] = isVerified;
    data['profilePhotoUrl'] = profilePhotoUrl;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
