import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/scan_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF050D1A),
  ));
  runApp(ChangeNotifierProvider(
    create: (_) => ScanProvider(),
    child: const HemoScanApp(),
  ));
}

class HemoScanApp extends StatelessWidget {
  const HemoScanApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HemoScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050D1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4C8),
          secondary: Color(0xFF1AFFE8),
          surface: Color(0xFF0A1628),
        ),
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashLoader();
          }
          if (snapshot.hasData && snapshot.data != null) return const HomeScreen();
          return const LoginScreen();
        },
      ),
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050D1A),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D4C8), Color(0xFF00A89E)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFF00D4C8).withOpacity(0.4), blurRadius: 32)],
        ),
        child: const Center(child: Text('🩸', style: TextStyle(fontSize: 38))),
      ),
      const SizedBox(height: 32),
      const SizedBox(width: 28, height: 28,
        child: CircularProgressIndicator(
          color: Color(0xFF00D4C8), strokeWidth: 2.5, strokeCap: StrokeCap.round)),
    ])),
  );
}