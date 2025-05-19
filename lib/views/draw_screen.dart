import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../controllers/game_controller.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final List<Offset> _points = [];
  int _seconds = 60;
  String? _word;
  Timer? _timer;

  late StreamSubscription<DatabaseEvent> _stateSubscription;
  late StreamSubscription<DatabaseEvent> _wordSubscription;
  late StreamSubscription<DatabaseEvent> _roundSubscription;

  int _currentRound = 1;

  void _sendPoints(List<Offset> points, String roomId) {
    final db = FirebaseDatabase.instance.ref();
    final formatted = points.map((e) => {'x': e.dx, 'y': e.dy}).toList();
    db.child('rooms/$roomId/canvas').set(formatted);
  }

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

  void _onTimeUp() {
    final game = Provider.of<GameController>(context, listen: false);
    game.advanceRoundOrEndGame();
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
    final game = Provider.of<GameController>(context, listen: false);
    _sendPoints(_points, game.roomId!);
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
        // Round ended
        _timer?.cancel();
        _clearCanvas(); // Clear drawing after round ends
        // The GameController will update round or state, triggering other listeners
      } else if (state == 'ready') {
        // New round started, get new word and start timer
        _startTimer();
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
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final game = Provider.of<GameController>(context, listen: false);

    FirebaseDatabase.instance
        .ref('rooms/${game.roomId}/word')
        .once()
        .then((snapshot) {
      if (snapshot.snapshot.exists) {
        setState(() => _word = snapshot.snapshot.value.toString());
      }
    });

    _listenToRoomState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stateSubscription.cancel();
    _wordSubscription.cancel();
    _roundSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameController>(context);

    return Scaffold(
      appBar: AppBar(
          title: Text("Draw: $_word | Round $_currentRound | $_seconds s")),
      body: GestureDetector(
        onPanUpdate: (details) {
          RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final localPos = box.globalToLocal(details.globalPosition);
            setState(() => _points.add(localPos));
            _sendPoints(_points, game.roomId!);
          }
        },
        onPanEnd: (_) => _points.add(Offset.zero),
        child: CustomPaint(
          size: Size.infinite,
          painter: DrawingPainter(points: _points),
        ),
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
