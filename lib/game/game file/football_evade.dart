import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:football_evade/game/components/background.dart';
import 'package:football_evade/game/components/game_controller.dart';
import 'package:football_evade/game/components/game_painter.dart';
import 'package:football_evade/game/components/game_state.dart';
import 'package:football_evade/game/components/load_image.dart';
import 'package:football_evade/game/components/player_object.dart';
import 'package:football_evade/game/components/red_line.dart';
import 'package:football_evade/game/components/transparent_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserObject {
  double xPos;
  double yPos;
  double size;
  double screenWidth;
  _GameScreenState state;
  bool isGamePaused;

  double interactionRadiusRight = 30.0;
  double interactionRadiusLeft = 20.0;
  double interactionRadiusUp = 20.0;
  double interactionRadiusDown = 20.0;

  UserObject(
    this.xPos,
    this.yPos,
    this.size,
    this.state,
    this.screenWidth,
    this.isGamePaused,
  );

  bool isColliding(PlayerPin pin) {
    double xDistance = xPos - pin.xPos;
    double yDistance = yPos - pin.yPos;

    double collisionRadius =
        size / 2 + interactionRadiusLeft + interactionRadiusRight;

    bool isWithinCollisionArea = (xDistance.abs() <= collisionRadius &&
        yDistance.abs() <= collisionRadius);

    return isWithinCollisionArea;
  }

  void updateInteractionRadiusRight(double newRadius) {
    interactionRadiusRight = newRadius;
  }

  Widget buildUserWidget() {
    double centerX = xPos - (interactionRadiusLeft / 2);
    double centerY = yPos - (interactionRadiusUp / 2);

    double adjustedXPos = centerX - (size * 1.1);
    double adjustedYPos = centerY - (size * 1.1);

    double interactionWidth =
        size * 1.1 + interactionRadiusLeft + interactionRadiusRight;
    double interactionHeight =
        size * 1.1 + interactionRadiusUp + interactionRadiusDown;

    interactionRadiusRight = interactionWidth / 3;

    double maxXPos = screenWidth - interactionWidth + 100;
    double minXPos = -50;

    adjustedXPos = adjustedXPos.clamp(minXPos, maxXPos);

    return Positioned(
      left: adjustedXPos,
      top: adjustedYPos - 50,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          double newXPos = xPos + details.delta.dx;
          newXPos = newXPos.clamp(0.0, maxXPos);
          xPos = newXPos;
          state.setState(() {});
        },
        child: Image.asset(
          isGamePaused
              ? 'assets/rolling-football_paused.gif'
              : 'assets/rolling-football-ball-gif.gif',
          width: interactionWidth,
          height: interactionHeight,
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final bool isSoundOn2;
  final int pausedGameTimeInSecondsfull;

  GameScreen({
    required this.isSoundOn2,
    required this.pausedGameTimeInSecondsfull,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController gameController;
  int gameTimeInSeconds = 0;
  int gameTimeInSecondsfull = 0;

  int gameMinutes = 0;
  late Timer timer;
  UserObject? userObject;
  ui.Image? pinImage;
  bool firstTime = true;
  final List<Back> _Backs = <Back>[];
  late SharedPreferences prefs;
  bool isPrefsLoaded = false;
  int bestGameTimeInSeconds = 0;
  int bestGameMinutes = 0;
  bool isTimerRunning = false;
  int pausedGameTimeInSeconds = 0;
  int pausedGameMinutes = 0;
  bool isTimerPaused = false;
  Duration pausedDuration = Duration.zero;
  int pausedSeconds = 0;
  int pausedMinutes = 0;

  bool isGamePaused = false;
  bool isGameInitialized = false;

  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      prefs = await SharedPreferences.getInstance();
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      pausedGameTimeInSeconds = prefs.getInt('pausedGameTimeInSeconds') ?? 0;

      bestGameTimeInSeconds = prefs.getInt('bestGameTimeInSeconds') ?? 0;
      await _loadBestGameTime();
      setState(() {
        isPrefsLoaded = true;
      });
      userObject ??= await UserObject(
        screenWidth / 2,
        screenHeight * 0.9,
        40,
        this,
        screenWidth,
        isGamePaused,
      );

      gameController = GameController(
        gameState: GameState.standard(),
        userObject: userObject!,
        playCollisionSound: _playCollisionSound,
        isSoundOn2: widget.isSoundOn2,
        endGame: _endGame,
      );

      if (pinImage == null) {
        pinImage = await loadImage('assets/player.png');
        setState(() {});
      }

      startGame();
      isGameInitialized = true;
    });
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!isGamePaused) {
        setState(() {
          gameTimeInSeconds++;
          gameTimeInSecondsfull++;

          if (gameTimeInSeconds >= 60) {
            gameMinutes++;
            gameTimeInSeconds -= 60;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    prefs.setInt('gameTimeInSecondsfull', gameTimeInSecondsfull);

    audioPlayer.stop();
    audioPlayer.dispose();

    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    if (!isPrefsLoaded) {
      return CircularProgressIndicator();
    }

    List<Widget> getBacks() {
      if (firstTime) {
        firstTime = false;
        _Backs.add(Back(top: -3));
        _Backs.add(Back(top: screenHeight / 3 - 4));
        _Backs.add(Back(top: screenHeight / 3 * 2 - 5));
      }
      List<Widget> list = <Widget>[];
      for (Back back in _Backs) {
        list.add(
          Positioned(
            top: back.top,
            left: 0,
            child: Image.asset(
              "assets/background.png",
              width: screenWidth,
              height: screenHeight / 2.5,
              fit: BoxFit.fill,
            ),
          ),
        );
      }
      return list;
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          title: Row(
            children: List.generate(
              gameController.getUserLife(),
              (index) => const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 35,
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 30,
                ),
                Text(
                  '${gameMinutes}m. ${gameTimeInSeconds}s.',
                  style: GoogleFonts.playfairDisplay(
                      textStyle: const TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
                ),
              ],
            ),
            const SizedBox(
              width: 60,
            ),
            IconButton(
              iconSize: 30,
              icon: isGamePaused
                  ? const Icon(Icons.play_arrow, size: 30, color: Colors.white)
                  : const Icon(Icons.pause, size: 30, color: Colors.white),
              onPressed: () {
                setState(() {
                  isGamePaused = !isGamePaused;
                  if (isGamePaused) {
                    timer.cancel();
                    _pauseGame();
                  } else {
                    startGame();
                  }
                });
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            ...getBacks(),
            CustomPaint(
              size: Size(screenWidth, screenHeight),
              painter: pinImage != null
                  ? GamePainter(
                      gameState: gameController.gameState,
                      time: 0.01,
                      pinImage: pinImage!,
                    )
                  : null,
            ),
            userObject?.buildUserWidget() ?? Container(),
            RedLine(screenHeight - 1),
          ],
        ),
      ),
    );
  }

  @override
  void _playCollisionSound() async {
    await audioPlayer.play(AssetSource('interaction.wav'));
    audioPlayer.setReleaseMode(ReleaseMode.release);
  }

  void resetTimer() {
    setState(() {
      if (!isTimerRunning) {
        gameTimeInSeconds = 0;
        gameTimeInSecondsfull = 0;
        gameMinutes = 0;
      }
    });
  }

  Future<void> _saveBestGameTime() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('bestGameTimeInSeconds', bestGameTimeInSeconds);
  }

  Future<void> _loadBestGameTime() async {
    final prefs = await SharedPreferences.getInstance();
    bestGameTimeInSeconds = prefs.getInt('bestGameTimeInSeconds') ?? 0;
  }

  Future<void> _checkAndUpdateBestGameTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bestGameTimeFromPrefs =
        prefs.getInt('bestGameTimeInSecondsfull') ?? 0;

    if (gameTimeInSecondsfull > bestGameTimeFromPrefs) {
      prefs.setInt('bestGameTimeInSecondsfull', gameTimeInSecondsfull);
      print('New best game time: ${gameTimeInSecondsfull} seconds');
    }
  }

  @override
  void startGame() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    userObject?.isGamePaused = false;

    userObject ??= UserObject(
      screenWidth / 2,
      screenHeight * 0.9,
      40,
      this,
      screenWidth,
      isGamePaused,
    );

    final redLine = RedLine(screenHeight - 1);

    timer = Timer.periodic(Duration(milliseconds: 20), (_) {
      if (!isGamePaused) {
        gameController.updatePins(0.02, screenWidth, screenHeight);

        bool backToAdd = false;
        Back? backToDelete;
        setState(() {
          for (Back back in _Backs) {
            if (back.top! < -1 && back.top! >= -4) {
              backToAdd = true;
            }
            if (back.top! <= screenHeight + 0 &&
                back.top! >= screenHeight - 3) {
              backToDelete = back;
            }
            back.top = back.top! + 3;
          }
        });
        if (backToAdd) {
          _Backs.add(Back(top: -screenHeight / 3 + 1));
        }
        if (backToDelete != null) {
          _Backs.remove(backToDelete);
        }
      }
    });

    if (isTimerPaused) {
      setState(() {
        isTimerPaused = false;
        gameTimeInSeconds = pausedDuration.inSeconds;
        gameMinutes = pausedDuration.inMinutes;
      });
    } else {
      resetTimer();
    }
  }

  @override
  void _pauseGame() {
    setState(() {
      isGamePaused = true;
      timer.cancel();
      userObject?.isGamePaused = true;
    });

    pausedGameTimeInSeconds = gameTimeInSeconds;
    pausedGameMinutes = gameMinutes;
    prefs.setInt('pausedGameTimeInSeconds', pausedGameTimeInSeconds);

    pausedDuration =
        Duration(minutes: pausedGameMinutes, seconds: pausedGameTimeInSeconds);
    isTimerPaused = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: TransparentDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 350,
                  height: 110,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/button2.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      "Game Paused",
                      style: GoogleFonts.playfairDisplay(
                          textStyle: const TextStyle(
                        fontSize: 40.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      )),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Container(
                  width: 350,
                  height: 80,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/button2.png'),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        isGamePaused = false;
                        timer.cancel();
                        gameController.gameState.pins.clear();
                        gameController.userLife = 3;
                        startGame();
                        pausedSeconds = 0;
                        pausedMinutes = 0;
                        resetTimer();
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        "Restart",
                        style: GoogleFonts.playfairDisplay(
                            textStyle: const TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  width: 350,
                  height: 80,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/button2.png'),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        isGamePaused = false;
                        startGame();
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        "Resume",
                        style: GoogleFonts.playfairDisplay(
                            textStyle: const TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  width: 350,
                  height: 80,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/button2.png'),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        "Exit",
                        style: GoogleFonts.playfairDisplay(
                            textStyle: const TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _endGame() async {
    setState(() {
      isGamePaused = true;
      timer.cancel();
      userObject?.isGamePaused = true;
    });

    if (gameTimeInSecondsfull > bestGameTimeInSeconds) {
      bestGameTimeInSeconds = gameTimeInSecondsfull;

      prefs.setInt('bestGameTimeInSeconds', bestGameTimeInSeconds);
    }

    _checkAndUpdateBestGameTime();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: TransparentDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 350,
                  height: 100,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/button2.png'),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "Game Over!",
                      style: GoogleFonts.playfairDisplay(
                          textStyle: const TextStyle(
                        fontSize: 40.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      )),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Container(
                  width: 350,
                  height: 100,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/button2.png'),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Your time:\n \t ${gameMinutes}m.${gameTimeInSeconds}s.',
                      style: GoogleFonts.playfairDisplay(
                          textStyle: const TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      )),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  width: 350,
                  height: 80,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/button2.png'),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        isGamePaused = false;
                        timer.cancel();
                        gameController.gameState.pins.clear();
                        gameController.userLife = 3;

                        if (!isTimerPaused) {
                          pausedSeconds = 0;
                          pausedMinutes = 0;
                        }

                        if (isTimerPaused) {
                          isTimerPaused = false;
                          resetTimer();
                        }

                        startGame();
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        "Restart",
                        style: GoogleFonts.playfairDisplay(
                            textStyle: const TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  width: 350,
                  height: 80,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/button2.png'),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        "Exit",
                        style: GoogleFonts.playfairDisplay(
                            textStyle: const TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
