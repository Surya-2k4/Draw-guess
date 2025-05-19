import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../controllers/game_controller.dart';
import 'draw_screen.dart';
import 'guess_screen.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late DatabaseReference _stateRef;
  late StreamSubscription<DatabaseEvent> _stateSubscription;

  @override
  void initState() {
    super.initState();

    // Safe way to access provider after widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = Provider.of<GameController>(context, listen: false);

      if (game.roomId == null) {
        print("❌ Error: Room ID is null");
        return;
      }

      _stateRef = FirebaseDatabase.instance.ref('rooms/${game.roomId}/state');

      _stateSubscription = _stateRef.onValue.listen((event) {
        final state = event.snapshot.value;
        print("📡 Room state updated: $state");

        if (state == 'ready') {
          if (!mounted) return;

          if (game.role == 'drawer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DrawScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GuessScreen()),
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameController>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Waiting Room")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Room ID: ${game.roomId}",
                style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 10),
            const Text("Waiting for another player..."),
          ],
        ),
      ),
    );
  }
}
