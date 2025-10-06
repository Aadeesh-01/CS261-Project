import 'package:cs261_project/screen/auth.dart';
import 'package:cs261_project/screen/splash_screen.dart';
import 'package:cs261_project/service/notification_service.dart';
import 'package:cs261_project/student/user_role_dispatcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔔 Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();

  // 🔔 Ask for notification permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Alumni Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 63, 17, 177),
        ),
      ),

      // 🔥 StreamBuilder listens for login/logout events
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // 🔐 If user is logged in → check their role and navigate
          if (snapshot.hasData) {
            return const UserRoleDispatcher();
          }

          // 👤 If not logged in → show login screen
          return const AuthScreen();
        },
      ),
    );
  }
}
