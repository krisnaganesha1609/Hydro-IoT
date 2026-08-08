import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydro_iot/core/app.dart';
import 'package:hydro_iot/res/colors.dart';
import 'package:hydro_iot/utils/local_notification_helper.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'utils/fcm_helper.dart';

final LocalNotificationHelper localNotificationHelper = LocalNotificationHelper();

// Must be a top-level function to handle background messages from FCM (because separate isolate)
// See: https://firebase.flutter.dev/docs/messaging/usage/#background-messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await localNotificationHelper.initialize();
  await Firebase.initializeApp();
  debugPrint('Received a foreground message: ${message.messageId}');
  if (message.notification != null) {
    debugPrint('Message also contained a notification: ${message.notification}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localNotificationHelper.initialize();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: ColorValues.green500, statusBarBrightness: Brightness.light, statusBarIconBrightness: Brightness.dark),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting();
  final container = ProviderContainer();
  fcmProviderContainer = container; // Assign to global variable for FCM helper
  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
