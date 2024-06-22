import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:football_evade/game/game%20file/football_evade.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  AudioPlayer audioPlayer = AudioPlayer();
  bool isSoundOn = true;
  int bestScore = 0;
  int bestSeconds = 0;
  int bestMinutes = 0;
  AudioPlayer audioPlayer2 = AudioPlayer();
  bool isSoundOn2 = true;

  @override
  void initState() {
    super.initState();
    _playBackgroundMusic();
    _loadBestScore();
  }

  void _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScore = prefs.getInt('bestGameTimeInSeconds') ?? 0;
      bestMinutes = bestScore ~/ 60;
      bestSeconds = bestScore % 60;
    });
  }

  void _playBackgroundMusic() async {
    await audioPlayer.play(AssetSource('background.wav'));
    audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void _toggleSound() {
    setState(() {
      isSoundOn = !isSoundOn;
      if (isSoundOn) {
        _playBackgroundMusic();
      } else {
        audioPlayer.stop();
      }
    });
  }

  void _toggleSound2() {
    setState(() {
      if (isSoundOn2) {
        print('sound on');
      } else {
        print('sound off');
        audioPlayer2.stop();
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.stop();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background_menu.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Positioned(
                top: 10.0,
                right: 10.0,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleSound,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: 60.0,
                        height: 60.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/button1.png',
                            ),
                            Icon(
                              isSoundOn ? Icons.music_note : Icons.music_off,
                              color: Colors.black,
                              size: 25.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isSoundOn2 = !isSoundOn2;
                        });
                        _toggleSound2();
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: 60.0,
                        height: 60.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/button1.png',
                            ),
                            Icon(
                              isSoundOn2 ? Icons.volume_up : Icons.volume_off,
                              color: Colors.black,
                              size: 25.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      height: 100,
                    ),
                    Container(
                      width: 410,
                      height: 130,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/button2.png'),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "FOOTBALL EVADE",
                          style: GoogleFonts.playfairDisplay(
                              textStyle: const TextStyle(
                            fontSize: 40.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              isSoundOn2: isSoundOn2,
                              pausedGameTimeInSecondsfull: 0,
                            ),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/play.png',
                        width: 300,
                      ),
                    ),
                    Container(
                      width: 320,
                      height: 100,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/button2.png'),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Best Result: \n \t $bestMinutes m. $bestSeconds s.",
                          style: GoogleFonts.playfairDisplay(
                              textStyle: const TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
