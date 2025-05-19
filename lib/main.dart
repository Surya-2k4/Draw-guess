import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'controllers/game_controller.dart';
import './views/home_screen.dart';
import './views/room_screen.dart';
import './views/draw_screen.dart';
import './views/guess_screen.dart';
import './views/result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    // <-- Check to avoid duplicate initialization
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyD2Hw5xec6z8auLMcSEM04ylnOe_41kam0",
          authDomain: "draw-guess-f9bdf.firebaseapp.com",
          projectId: "draw-guess-f9bdf",
          storageBucket: "draw-guess-f9bdf.firebasestorage.app",
          messagingSenderId: "629624896413",
          appId: "1:629624896413:web:948fe67e6ab9fb4c8acd74",
          measurementId: "G-Q0PNBK8JRP",
          databaseURL: "https://draw-guess-f9bdf-default-rtdb.firebaseio.com/",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  }

  runApp(const MultiplayerGameApp());
}

class MultiplayerGameApp extends StatelessWidget {
  const MultiplayerGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameController(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Draw Guess Game',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: ColorScheme.dark(
            primary: Colors.purpleAccent,
            secondary: Colors.tealAccent,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/room': (context) => const RoomScreen(),
          '/draw': (context) => const DrawScreen(),
          '/guess': (context) => const GuessScreen(),
          '/result': (context) => const ResultScreen(),
        },
      ),
    );
  }
}
