import 'package:grjoffice_apps/models/user_model.dart';

class LoginModel {
  const LoginModel({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  final String token;
  final String tokenType;
  final UserModel user;

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      token: json['token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}
