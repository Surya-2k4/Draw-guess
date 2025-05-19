import 'dart:ui';

class Game {
  final String roomId;
  final String word;
  final String drawerId;
  final String guesserId;
  final List<Offset> canvasPoints;
  final String gameState; // waiting, drawing, guessed

  Game({
    required this.roomId,
    required this.word,
    required this.drawerId,
    required this.guesserId,
    required this.canvasPoints,
    required this.gameState,
  });
}
