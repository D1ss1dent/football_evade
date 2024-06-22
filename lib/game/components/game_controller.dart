import 'dart:math';

import 'package:football_evade/game/components/game_state.dart';
import 'package:football_evade/game/components/player_object.dart';
import 'package:football_evade/game/components/red_line.dart';
import 'package:football_evade/game/game%20file/football_evade.dart';

class GameController {
  GameState gameState;
  UserObject userObject;
  double lastPinTime = 0;
  double pinSpawnInterval = 0.5;
  int userLife = 3;
  final void Function() playCollisionSound;
  final void Function() endGame;
  bool isSoundOn2;

  GameController(
      {required this.gameState,
      required this.userObject,
      required this.playCollisionSound,
      required this.endGame,
      required this.isSoundOn2});

  int getUserLife() {
    return userLife;
  }

  void updatePins(double time, double screenWidth, double screenHeight) {
    List<PlayerPin> pinsToRemove = [];
    bool gameEnded = false;
    final redLine = RedLine(screenHeight - 1);

    for (var pin in gameState.pins) {
      pin.update(time, screenWidth, screenHeight);

      if (!pin.isActive ||
          pin.yPos < 0 ||
          pin.isCollidingWithRedLine(redLine)) {
        pinsToRemove.add(pin);
      } else if (pin.isActive && userObject.isColliding(pin)) {
        pin.isActive = false;
        pinsToRemove.add(pin);

        userLife--;

        if (userLife <= 0) {
          gameEnded = true;
        }

        if (isSoundOn2) {
          playCollisionSound();
        }
      }
    }

    gameState.pins.removeWhere((pin) => pinsToRemove.contains(pin));

    double currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

    if (currentTime - lastPinTime > pinSpawnInterval) {
      int groupSize = Random().nextInt(3) + 1;

      for (int i = 0; i < groupSize; i++) {
        double randomXPos;
        double pinSize = 20.0;
        double pinSpeed = 150.0;
        bool canAddPin = true;

        do {
          randomXPos = Random().nextDouble() * screenWidth;
          canAddPin = !gameState.pins
              .any((pin) => (pin.xPos - randomXPos).abs() < pinSize * 2);
        } while (!canAddPin);

        gameState.pins.add(PlayerPin(
          xPos: randomXPos,
          yPos: 0,
          size: pinSize,
          speed: pinSpeed,
          direction: pi / 2,
          isActive: true,
        ));
      }

      lastPinTime = currentTime + (Random().nextDouble() * 5.0 + 2.0);
    }

    if (gameEnded) {
      endGame();
    }
  }
}
