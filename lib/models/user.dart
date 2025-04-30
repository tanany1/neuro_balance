import 'dart:math';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String userType;
  final String uniqueId;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userType,
    String? uniqueId,
  }) : uniqueId = uniqueId ?? _generateUniqueId();

  static String _generateUniqueId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        8,
            (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'userType': userType,
      'uniqueId': uniqueId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      userType: map['userType'],
      uniqueId: map['uniqueId'],
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, firstName: $firstName, lastName: $lastName, email: $email, userType: $userType, uniqueId: $uniqueId)';
  }
}