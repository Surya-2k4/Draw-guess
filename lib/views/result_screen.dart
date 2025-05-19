import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      final game = Provider.of<GameController>(context, listen: false);
      game.resetRoom();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameController>(context);
    final scores = game.scores;
    if (scores.isEmpty) {
      return Scaffold(body: Center(child: Text('No scores found.')));
    }

    // Determine winner
    final winner = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Game Over')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Winner: ${winner.key}',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('Score: ${winner.value}',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            ...scores.entries.map((e) => Text('${e.key}: ${e.value}',
                style: const TextStyle(fontSize: 20))),
            const SizedBox(height: 40),
            const Text('Returning to Home Screen in 5 seconds...',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
