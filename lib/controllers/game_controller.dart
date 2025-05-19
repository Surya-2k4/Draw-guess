import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class GameController extends ChangeNotifier {
  String? roomId;
  String? playerId;
  String? role;
  String? word;

  final _db = FirebaseDatabase.instance.ref();
  final List<String> _words = [
    'apple',
    'car',
    'house',
    'banana',
    'tree',
    'phone'
  ];

  int currentRound = 1;
  static const int maxRounds = 5;
  Map<String, int> scores = {};

  Future<void> createRoom() async {
    if (playerId == null || playerId!.isEmpty) {
      throw Exception("Player ID must be set before creating a room.");
    }

    roomId = DateTime.now().millisecondsSinceEpoch.toString();
    role = "drawer";

    String safePlayerId = playerId!.replaceAll(RegExp(r'[.#$\[\]]'), '_');

    print("🚀 createRoom() started with playerId: $safePlayerId");

    try {
      await _db.child('rooms/$roomId').set({
        'state': 'waiting',
        'players': {safePlayerId: true},
        'round': 1,
        'scores': {safePlayerId: 0},
      });

      scores = {safePlayerId: 0};
      currentRound = 1;
      notifyListeners();
    } catch (e) {
      print("❌ Failed to create room: $e");
    }
  }

  Future<void> joinRoom(String inputRoomId) async {
    if (playerId == null || playerId!.isEmpty) {
      throw Exception("Player ID must be set before joining a room.");
    }

    roomId = inputRoomId;
    role = "guesser";

    String safePlayerId = playerId!.replaceAll(RegExp(r'[.#$\[\]]'), '_');

    try {
      final roomRef = _db.child('rooms/$roomId');

      // Add player to players list
      await roomRef.child('players/$safePlayerId').set(true);

      // Initialize player's score if not present
      await roomRef.child('scores/$safePlayerId').set(0);

      // Update state to ready
      await roomRef.child('state').set('ready');

      // Listen to round and scores updates
      roomRef.child('round').onValue.listen((event) {
        final roundValue = event.snapshot.value;
        if (roundValue is int) {
          currentRound = roundValue;
          notifyListeners();
        }
      });

      roomRef.child('scores').onValue.listen((event) {
        final scoreMap = Map<String, int>.from((event.snapshot.value as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as int))) ??
            {});
        scores = scoreMap;
        notifyListeners();
      });

      print("🔗 Joined room $roomId as $safePlayerId");
      notifyListeners();
    } catch (e) {
      print("❌ Failed to join room: $e");
    }
  }

  Future<void> assignWord() async {
    print("🎯 assignWord() started");

    final selected = (_words..shuffle()).first;
    word = selected;

    try {
      if (roomId != null) {
        await _db.child('rooms/$roomId/word').set(selected);
        print("✅ Word '$selected' assigned to room $roomId");
      }
    } catch (e) {
      print("❌ Error assigning word: $e");
    }
  }

  // Call this after a round ends, pass the player who scored a point
  Future<void> incrementScore(String scoringPlayerId) async {
    if (roomId == null) return;

    String safePlayerId = scoringPlayerId.replaceAll(RegExp(r'[.#$\[\]]'), '_');

    try {
      final scoreRef = _db.child('rooms/$roomId/scores/$safePlayerId');
      final snapshot = await scoreRef.get();
      int currentScore = 0;
      if (snapshot.exists) {
        currentScore = (snapshot.value as int);
      }
      currentScore++;
      await scoreRef.set(currentScore);
      print("🏅 Score updated for $safePlayerId to $currentScore");
    } catch (e) {
      print("❌ Failed to increment score: $e");
    }
  }

  // Call this to advance the round or end the game if max reached
  Future<void> advanceRoundOrEndGame() async {
    if (roomId == null) return;

    try {
      if (currentRound < maxRounds) {
        currentRound++;
        await _db.child('rooms/$roomId/round').set(currentRound);
        // Assign new word for next round if drawer
        if (role == 'drawer') {
          await assignWord();
        }
      } else {
        // Game over, set state to 'ended'
        await _db.child('rooms/$roomId/state').set('ended');
        print("🏁 Game ended after $maxRounds rounds");
      }
    } catch (e) {
      print("❌ Failed to advance round or end game: $e");
    }
  }

  // Optional: reset room or clean up after game ends
  Future<void> resetRoom() async {
    if (roomId == null) return;
    try {
      await _db.child('rooms/$roomId').remove();
      roomId = null;
      role = null;
      word = null;
      currentRound = 1;
      scores.clear();
      notifyListeners();
      print("♻️ Room reset");
    } catch (e) {
      print("❌ Failed to reset room: $e");
    }
  }
}
