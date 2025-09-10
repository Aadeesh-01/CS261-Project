import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Create a new user using Cloud Function
  Future<String?> createNewUser({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('createNewUser');

      final response = await callable.call(<String, dynamic>{
        'email': email,
        'password': password,
        'role': role,
      });

      return response.data['message']; // ✅ success message from function
    } on FirebaseFunctionsException catch (e) {
      return "❌ FirebaseFunctionsException: ${e.message}";
    } catch (e) {
      return "❌ Error: $e";
    }
  }
}
