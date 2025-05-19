import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../controllers/game_controller.dart';

class GuessScreen extends StatefulWidget {
  const GuessScreen({super.key});

  @override
  State<GuessScreen> createState() => _GuessScreenState();
}

class _GuessScreenState extends State<GuessScreen> {
  List<Offset> _points = [];
  final _controller = TextEditingController();
  String _feedback = "";
  String? _word;
  int _seconds = 60;
  int _currentRound = 1;

  Timer? _timer;
  late StreamSubscription<DatabaseEvent> _canvasSubscription;
  late StreamSubscription<DatabaseEvent> _stateSubscription;
  late StreamSubscription<DatabaseEvent> _wordSubscription;
  late StreamSubscription<DatabaseEvent> _roundSubscription;

  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
        _onTimeUp();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _onTimeUp() async {
    final game = Provider.of<GameController>(context, listen: false);
    await FirebaseDatabase.instance
        .ref('rooms/${game.roomId}/state')
        .set('timeup');
    // Waiting for game controller to handle round advance or end
  }

  void _listenToCanvas(String roomId) {
    final canvasRef = FirebaseDatabase.instance.ref('rooms/$roomId/canvas');

    // Use onChildAdded and onChildChanged for more granular updates to reduce lag
    _canvasSubscription = canvasRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is List) {
        List<Offset> newPoints = [];
        for (var item in data) {
          if (item is Map) {
            final x = (item['x'] ?? 0).toDouble();
            final y = (item['y'] ?? 0).toDouble();
            newPoints.add(Offset(x, y));
          }
        }
        setState(() => _points = newPoints);
      } else {
        // If no data or cleared, clear points too
        setState(() => _points = []);
      }
    });
  }

  void _listenToRoomState() {
    final game = Provider.of<GameController>(context, listen: false);
    final roomId = game.roomId!;
    final stateRef = FirebaseDatabase.instance.ref('rooms/$roomId/state');
    final wordRef = FirebaseDatabase.instance.ref('rooms/$roomId/word');
    final roundRef = FirebaseDatabase.instance.ref('rooms/$roomId/round');

    _stateSubscription = stateRef.onValue.listen((event) {
      final state = event.snapshot.value;
      if (state == 'guessed' || state == 'timeup') {
        _timer?.cancel();
        setState(() {
          _feedback = "";
          _points.clear(); // Clear drawing when round ends
        });
      } else if (state == 'ready') {
        _startTimer();
        setState(() {
          _feedback = "";
          _points.clear();
        });
      } else if (state == 'ended') {
        _timer?.cancel();
        Navigator.pushReplacementNamed(context, '/result');
      }
    });

    _wordSubscription = wordRef.onValue.listen((event) {
      final newWord = event.snapshot.value;
      if (newWord != null && newWord is String) {
        setState(() => _word = newWord);
      }
    });

    _roundSubscription = roundRef.onValue.listen((event) {
      final round = event.snapshot.value;
      if (round != null && round is int && round != _currentRound) {
        setState(() {
          _currentRound = round;
          _feedback = "";
          _points.clear();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final game = Provider.of<GameController>(context, listen: false);
    _listenToCanvas(game.roomId!);
    _listenToRoomState();

    FirebaseDatabase.instance
        .ref('rooms/${game.roomId}/word')
        .once()
        .then((snapshot) {
      if (snapshot.snapshot.exists) {
        setState(() => _word = snapshot.snapshot.value.toString());
      }
    });

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _canvasSubscription.cancel();
    _stateSubscription.cancel();
    _wordSubscription.cancel();
    _roundSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameController>(context);
    return Scaffold(
      appBar:
          AppBar(title: Text("Guessing | Round $_currentRound | $_seconds s")),
      body: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: DrawingPainter(points: _points),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: "Your Guess"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_controller.text.trim().toLowerCase() ==
                        _word?.toLowerCase()) {
                      setState(() => _feedback = "Correct!");

                      await FirebaseDatabase.instance
                          .ref('rooms/${game.roomId}/state')
                          .set('guessed');
                      _timer?.cancel();
                      // Wait for round advance handled by GameController
                    } else {
                      setState(() => _feedback = "Try again!");
                    }
                    _controller.clear();
                  },
                  child: const Text("Submit"),
                ),
                const SizedBox(height: 10),
                Text(_feedback),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
