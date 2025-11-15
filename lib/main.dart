import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'package:cs261_project/firebase_options.dart';
import 'package:cs261_project/screen/auth.dart';
import 'package:cs261_project/screen/splash_screen.dart';
import 'package:cs261_project/service/user_role_dispatcher.dart';
import 'package:cs261_project/service/notification_service.dart';
import 'package:cs261_project/widget/connectivity_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully!");

    // Request push notification permissions (iOS and Android 13+)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    print("🔔 FCM permission status: ${settings.authorizationStatus}");

    // Show notifications while app is in foreground (iOS behavior)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications + FCM listeners
    await NotificationService().init();
    // Debug: print resolved storage bucket to verify configuration
    try {
      final defaultBucket = storage.FirebaseStorage.instance.bucket;
      print('🪣 Default Storage bucket: ' + defaultBucket);
      final explicitBucket =
          DefaultFirebaseOptions.currentPlatform.storageBucket;
      final storageFor =
          storage.FirebaseStorage.instanceFor(bucket: explicitBucket);
      print('🪣 Explicit Storage bucket: ${storageFor.bucket}');
      // Optional lightweight probe: list root (should succeed or give permission error, not bucket-not-found)
      try {
        await storageFor.ref().list(const storage.ListOptions(maxResults: 1));
        print('✅ Storage probe succeeded for bucket: ${storageFor.bucket}');
      } on storage.FirebaseException catch (e) {
        print(
            '🔎 Storage probe FirebaseException: code=${e.code} message=${e.message}');
      }
    } catch (e) {
      print('⚠️ Could not resolve Firebase Storage buckets: $e');
    }
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _lastInstituteId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstituteId();
  }

  Future<void> _loadInstituteId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastInstituteId = prefs.getString('lastInstituteId');
      _isLoading = false;
    });
    print("🏫 Loaded institute ID: $_lastInstituteId");
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(home: SplashScreen());
    }

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'CS261 Project',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      builder: (context, child) => ConnectivityBanner(
        child: child ?? const SizedBox.shrink(),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          if (snapshot.hasData) {
            print("🚀 Logged in as: ${snapshot.data!.uid}");
            if (_lastInstituteId != null) {
              print("✅ Using institute from prefs: $_lastInstituteId");
              return UserRoleDispatcher(instituteId: _lastInstituteId!);
            } else {
              print(
                  "⚠️ No institute found in prefs — redirecting to AuthScreen");
              return const AuthScreen();
            }
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
