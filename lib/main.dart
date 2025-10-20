import 'package:chat/screens/auth_check_screen.dart';
import 'package:chat/screens/contacts_screen.dart';
import 'package:chat/screens/home_screen.dart';
import 'package:chat/screens/landing_screen.dart';
import 'package:chat/screens/phone_number%20entry.dart';
import 'package:chat/database/database_helper.dart';
import 'package:chat/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // optional
      systemNavigationBarColor: Color.fromARGB(
        255,
        19,
        19,
        19,
      ), // dark background
      systemNavigationBarIconBrightness: Brightness.light, // icons = white
    ),
  );

  await setupLocator();

  await getIt<DatabaseHelper>().database;

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111B21),
        // primaryColor: const Color(0xFF121B22),
        colorScheme: ColorScheme.dark(
          primary: Colors.white, // same as primaryColor
          secondary: Color(0xFF25D366), // WhatsApp green
          surface: Color(0xFF202C33), // chat bubbles
          onPrimary: Color.fromARGB(255, 204, 205, 206), // text on buttons
          onSurface: Colors.white, // secondary text
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1F2C34),
          foregroundColor: const Color(0xFFE9EDEF),
          elevation: 0,
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: Color(0xFFE9EDEF),
          unselectedLabelColor: Color(0xFF8696A0),
          indicatorColor: Color(0xFF25D366),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: Color(0xFF8696A0)),
          labelStyle: TextStyle(color: Colors.grey),
        ),
      ),
      // home: ContactsScreen(),
      initialRoute: "/",
  routes: {
    "/": (context) => const AuthCheckScreen(),
    "/landing": (context) => LandingScreen(),
    "/home": (context) => Homescreen(),
    "/contacts":(context) => ContactsScreen(),
    "/phone_verification":(context) => PhoneNumberScreen(),
  },
    );
  }
}
