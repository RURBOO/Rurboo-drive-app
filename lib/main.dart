import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'core/services/notification_service.dart';
import 'core/wrappers/connectivity_wrapper.dart';
import 'features/splash/views/splash_screen.dart';
import 'state/app_state_viewmodel.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/home/viewmodels/driver_voice_viewmodel.dart';
import 'features/auth/viewmodels/login_viewmodel.dart';
import 'features/auth/viewmodels/registration_viewmodel.dart';
import 'features/profile/viewmodels/vehicles_viewmodel.dart';
import 'state/language_provider.dart';
import 'core/services/driver_voice_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase init failed: $e');
  }

  // 🔐 FIREBASE APP CHECK
  try {
    await FirebaseAppCheck.instance.activate(
      // providerWeb: RecaptchaV3Provider('6Ld...'),
      // ignore: deprecated_member_use
      androidProvider: AndroidProvider.debug,
      // ignore: deprecated_member_use
      appleProvider: AppleProvider.debug,
    );
     // ✅ PROPER TOKEN REFRESH
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    debugPrint('🔐 App Check: Play Integrity active');
  } catch (e) {
    debugPrint('⚠️ App Check init issue: $e');
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ .env load failed: $e');
  }

  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('⚠️ Notification init failed: $e');
  }

  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => RegistrationViewModel()),
        ChangeNotifierProvider(create: (_) => VehiclesViewModel()),
        ChangeNotifierProvider(
          create: (_) => DriverVoiceViewModel()..init(),
        ),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
            return Listener(
              onPointerDown: (_) {
                // Pause voice announcements on ANY screen touch
                DriverVoiceService().stop();
              },
              child: MaterialApp(
                title: 'RURBOO Driver',
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'), // English
                  Locale('hi'), // Hindi
                ],
                locale: languageProvider.currentLocale,
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                  useMaterial3: true,
                ),
                builder: (context, child) {
                  return ConnectivityWrapper(child: child!);
                },
                home: const SplashScreen(),
              ),
            );
        },
      ),
    );
  }
}
