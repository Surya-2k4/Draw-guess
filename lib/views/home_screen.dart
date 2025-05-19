import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final nameController = TextEditingController();
  final roomController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Draw & Guess")),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Enter your name"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter your name")),
                  );
                  return;
                }

                print("👉 Create Room button pressed with player name: $name");
                game.playerId = name;

                try {
                  await game.createRoom();
                  print("🏁 Room creation completed");

                  await game.assignWord();
                  print("🏁 Word assigned");

                  if (!context.mounted) return;
                  print("🚪 Navigating to /room");
                  Navigator.pushNamed(context, '/room');
                } catch (e) {
                  print("❌ Error during room creation: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to create room: $e")),
                  );
                }
              },
              child: const Text("🎨 Create Room"),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(labelText: "Enter Room ID"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final roomId = roomController.text.trim();

                if (name.isEmpty || roomId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Name and Room ID required")),
                  );
                  return;
                }

                game.playerId = name;

                try {
                  await game.joinRoom(roomId);
                  Navigator.pushNamed(context, '/room');
                } catch (e) {
                  print("❌ Failed to join room: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to join room: $e")),
                  );
                }
              },
              child: const Text("🔗 Join Room"),
            ),
          ],
        ),
      ),
    );
  }
}
