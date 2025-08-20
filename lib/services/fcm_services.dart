import 'dart:convert';

import 'package:bogus_app/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

class FCMServices {
  /// Initializes Firebase Cloud Messaging (FCM) for the current device.
  Future<void> initializeCloudMessaging() => Future.wait([
    FirebaseMessaging.instance.requestPermission(),
    FirebaseMessaging.instance.setAutoInitEnabled(true),
  ]);

  /// Retrieves the default FCM token for the current device.
  Future<String?> getFCMToken() => FirebaseMessaging.instance.getToken();

  /// Sets up Listeners for Firebase Cloud Messaging (FCM) messages.
  void listenFCMMessage() {
    // Notification is received while app is open [Foreground]
    FirebaseMessaging.onMessage.listen(_handleFCMMessage);

    // User taps on a notification to open the app [background/terminated/closed]
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("Notification opened title: ${message.notification?.title}");
      log("Notification opened body: ${message.notification?.body}");
      NotificationService().onClickToNotification(
        jsonEncode({
          "title": message.notification?.title,
          "body": message.notification?.body,
        })
      );
    });
  }

  /// Handles FCM messages received while the app is in the foreground.
  Future<void> _handleFCMMessage(RemoteMessage message) async {
    log('Received FCM message title : ${message.notification?.title}');
    log('Received FCM message body: ${message.notification?.body}');
    await NotificationService().showNotification(message: message);

  }
}