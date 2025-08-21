//import 'package:cs261_project/admin/admin_home_screen.dart';
import 'package:cs261_project/screen/auth.dart';
//import 'package:cs261_project/screen/home_screen.dart';
//import 'package:cs261_project/screen/splash_screen.dart';
//import 'package:cs261_project/screen/admin_home_screen.dart';
//import 'package:cs261_project/screen/user_home_screen.dart';
//import 'package:cs261_project/widget/user_role_dispatcher.dart';

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
          /* if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            // Correct! `snapshot.data` here is a User object.
            // We pass control to the dispatcher which will handle the database check.
            return const UserRoleDispatcher();
          }
          return const AuthScreen();
        },*/
          return AuthScreen();
        },
      ),
    );
  }
}
