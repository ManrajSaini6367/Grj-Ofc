import 'package:flutter/foundation.dart';
import 'package:grjoffice_apps/models/user_model.dart';

/// Notifies UI when the logged-in user profile/role changes.
class UserSession extends ChangeNotifier {
  UserSession._();

  static final UserSession instance = UserSession._();

  UserModel? _user;

  UserModel? get user => _user;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
