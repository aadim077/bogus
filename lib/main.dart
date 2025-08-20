import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/fcm_services.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'utils/constants.dart';
import 'utils/flag_secure.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessagingHandler(RemoteMessage message) async {
  log("firebaseBackgroundMessagingHandler main: $message");
  await Firebase.initializeApp();
  NotificationService().initializeLocalNotifications();
  NotificationService().showNotification(message: message);
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //  Block screenshots & screen recording for the whole app
  await ScreenSecurity.enableSecure();

  // Initialize and listen for FCM messages
  final FCMServices fcmServices = FCMServices();
  NotificationService().initializeLocalNotifications();
  await fcmServices.initializeCloudMessaging();
  fcmServices.listenFCMMessage();
  String? fcmToken = await fcmServices.getFCMToken();
  log("fcm token: $fcmToken");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Reels',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: kBrandColor,
          scaffoldBackgroundColor: kScaffold,
        ),
        home: const RootPage(),
      ),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  Future<String?> _getUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.get('role') as String?;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user role: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: true);

    return StreamBuilder<UserState?>(
      stream: auth.userStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder<String?>(
          future: _getUserRole(user.uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            final role = roleSnap.data ?? "user";
            if (role == "admin") {
              return const AdminDashboard();
            } else {
              return HomeScreen(userState: user);
            }
          },
        );
      },
    );
  }
}