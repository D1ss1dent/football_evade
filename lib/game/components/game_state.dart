import 'package:football_evade/game/components/player_object.dart';

class GameState {
  List<PlayerPin> pins;

  GameState({required this.pins});

  factory GameState.standard() => GameState(pins: []);
}
