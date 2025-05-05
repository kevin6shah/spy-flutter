import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spy/game_lobby.dart';
import 'package:spy/main.dart';

class GameView extends StatefulWidget {
  const GameView({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  String gameCode = '';
  String userName = '';

  bool isHost = false;

  int countdown = 5;
  Timer? countdownTimer;
  String lastWordState = '';

  void initializeGame() {
    // assign numbers of spies randomly from the list of players
    FirebaseFirestore.instance.collection('games').doc(gameCode).get().then((
      doc,
    ) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final players = data['players'] as List<dynamic>;
        final numSpies = data['numSpies'] as int;

        // Randomly assign spies
        List<int> spyIndices = [];
        final numPlayers = players.length;
        final random = Random();
        while (spyIndices.length < numSpies) {
          int randomIndex = random.nextInt(numPlayers);
          if (!spyIndices.contains(randomIndex)) {
            spyIndices.add(randomIndex);
          }
        }

        List<Map<String, dynamic>> updatedPlayers = [];
        for (int i = 0; i < players.length; i++) {
          final player = Map<String, dynamic>.from(players[i]);
          player['isSpy'] = spyIndices.contains(i);
          updatedPlayers.add(player);
        }
        FirebaseFirestore.instance.collection('games').doc(gameCode).update({
          'players': updatedPlayers,
        });

        FirebaseFirestore.instance.collection('games').doc(gameCode).update({
          'wordState': 'COUNTER',
        });
      }
    });
  }

  void startCountdown() {
    countdownTimer?.cancel();
    setState(() {
      countdown = 5;
    });
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 1) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
        FirebaseFirestore.instance.collection('games').doc(gameCode).update({
          'wordState': 'Hotel',
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize any necessary data or state here

    gameCode = widget.prefs.getString('gameCode') ?? '';
    userName = widget.prefs.getString('userName') ?? '';

    if (gameCode.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => const MyApp()),
        );
      });
    }

    FirebaseFirestore.instance.collection('games').doc(gameCode).get().then((
      doc,
    ) {
      if (doc.exists) {
        if (doc.data()!['wordState'] == 'INIT') {
          initializeGame();
        }
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('games')
                  .doc(gameCode)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CupertinoActivityIndicator());
            }
            final docSnapshot = snapshot.data as DocumentSnapshot;
            final gameData =
                docSnapshot.data() != null
                    ? docSnapshot.data() as Map<String, dynamic>
                    : {};

            if (gameData.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.prefs.remove('gameCode');
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(builder: (context) => const MyApp()),
                );
              });
            }

            String wordState = gameData['wordState'];

            // Only start countdown when wordState changes to 'COUNTER'
            if (wordState == 'COUNTER' && lastWordState != 'COUNTER') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                startCountdown();
              });
            }
            lastWordState = wordState;

            if (wordState == 'INIT') {
              initializeGame();
            } else if (wordState == 'COUNTER') {
              return Center(
                child: Text(
                  countdown.toString(),
                  style: const TextStyle(
                    fontSize: 100,
                    color: CupertinoColors.white,
                  ),
                ),
              );
            }

            isHost = gameData['host'] == userName;

            bool isSpy = gameData['players'].any(
              (player) => player['name'] == userName && player['isSpy'],
            );

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child:
                        isSpy
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/logos/spy_dark.png',
                                  width: 200,
                                ),
                                Text(
                                  'Shh... You are a spy!\n\nTry to guess the word\nand blend in...',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ],
                            )
                            : Center(
                              child: Text(
                                wordState,
                                style: const TextStyle(
                                  fontSize: 100,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                  ),

                  isHost
                      ? CupertinoButton.tinted(
                        color: CupertinoColors.white,
                        child: Text(
                          'Stop Game',
                          style: TextStyle(color: CupertinoColors.white),
                        ),
                        onPressed: () {
                          if (!mounted) {
                            return;
                          }

                          GameLobby.exitGame(context, gameCode, widget.prefs);
                        },
                      )
                      : CupertinoButton.tinted(
                        color: CupertinoColors.white,
                        child: Text(
                          'Leave Game',
                          style: TextStyle(color: CupertinoColors.white),
                        ),
                        onPressed: () async {
                          if (!mounted) {
                            return;
                          }

                          GameLobby.leaveGame(
                            context,
                            gameCode,
                            userName,
                            widget.prefs,
                          );
                        },
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
