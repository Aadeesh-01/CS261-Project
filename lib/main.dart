//import 'package:cs261_project/admin/admin_home_screen.dart';
import 'package:cs261_project/screen/auth.dart';
//import 'package:cs261_project/screen/home_screen.dart';
import 'package:cs261_project/screen/splash_screen.dart';
//import 'package:cs261_project/screen/admin_home_screen.dart';
//import 'package:cs261_project/screen/user_home_screen.dart';
import 'package:cs261_project/student/user_role_dispatcher.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 63, 17, 177),
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show a splash screen while checking for a logged-in user.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // If the snapshot has data, it means a user is logged in.
          if (snapshot.hasData) {
            // Pass control to your dispatcher to handle user roles.
            return const UserRoleDispatcher();
          }

          // If there's no data, show the authentication screen.
          return const AuthScreen();
        },
      ),
    );
  }
}
