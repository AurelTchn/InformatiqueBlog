import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:informatiqueblog/pages_aurel/categories.dart';
import 'package:informatiqueblog/pages_aurel/listearticles.dart';
import 'package:informatiqueblog/pages_majoie/auth_screen.dart';
import 'package:informatiqueblog/pages_majoie/home_screen.dart';
import 'package:informatiqueblog/pages_majoie/welcome_screen.dart';
import 'package:informatiqueblog/pages_merveilles/contacts.dart';
import 'package:informatiqueblog/pages_merveilles/profil.dart';
import 'package:informatiqueblog/pages_simonne/connexion.dart';
import 'package:informatiqueblog/pages_simonne/welcome.dart';
import 'package:informatiqueblog/src/three_arched_circle/three_arched_circle.dart';
import 'package:informatiqueblog/src/three_rotating_dots/three_rotating_dots.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:provider/provider.dart';
import 'pages_aurel/theme_provider.dart';
import 'pages_aurel/articledetails.dart';

import 'package:shared_preferences/shared_preferences.dart';

//Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

//Cloudnary
import 'package:cloudinary_url_gen/cloudinary.dart';

final cloudinary = Cloudinary.fromStringUrl(
    'cloudinary://863377355295549:57YFSH3T5JeCVrhrZ_Tl5XWmLGM@drsyadv5i');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  cloudinary.config.urlConfig.secure = true;
  final bool isFirstLaunch = await checkFirstLaunch();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: MyApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

Future<bool> checkFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  bool? isFirstLaunch = prefs.getBool('isFirstLaunch');

  if (isFirstLaunch == null || isFirstLaunch) {
    await prefs.setBool('isFirstLaunch', false);
    return true;
  }
  return false;
}

class MyApp extends StatefulWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      themeMode: context.watch<ThemeProvider>().themeMode,
      theme: context.watch<ThemeProvider>().currentTheme,
      //home:  UserProfilePage(),
      initialRoute: '/',
      routes: {
        '/': (context) =>
            widget.isFirstLaunch ? WelcomeScreen() : AuthChecker(),
      },
    );
  }
}

class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          String uid = snapshot.data!.uid;
          Future.microtask(() {
            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 600),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return FadeTransition(
                    opacity: animation,
                    child: HomeScreen(uid: uid),
                  );
                },
              ),
              (route) => false,
            );
          });
        } else {
          Future.microtask(() {
            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 600),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return FadeTransition(
                    opacity: animation,
                    child: AuthScreen(),
                  );
                },
              ),
              (route) => false,
            );
          });
        }
        // Retourne un écran de chargement temporaire
        return LoadingOverlayPro(
          isLoading: true,
          progressIndicator: Stack(
            alignment: Alignment.center,
            children: [
              ThreeArchedCircle(color: Colors.blue, size: 130),
              ThreeRotatingDots(size: 50, color: Colors.blue),
            ],
          ),
          child: Scaffold(
            body: Center(
              child: Text(""),
            ),
          ),
        );
      },
    );
  }
}
