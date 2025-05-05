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

        if (data['gameStarted'] == false) {
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            CupertinoPageRoute(
              builder: (context) => GameLobby(prefs: widget.prefs),
            ),
          );
        }

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

  Future<String> getRandomWord(String pack) async {
    // Fetch a random word from the specified pack
    List<String> words = await FirebaseFirestore.instance
        .collection('packs')
        .doc(pack)
        .get()
        .then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['words']);
      } else {
        return [];
      }
    });

    return words[Random().nextInt(words.length)];
  }

  void startCountdown(bool isHost, String pack) {
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
        if (isHost) {
          getRandomWord(pack).then((word) {
            FirebaseFirestore.instance.collection('games').doc(gameCode).update(
              {'wordState': word},
            );
          });
        }
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
            isHost = gameData['host'] == userName;
            String pack = gameData['pack'];

            // Only start countdown when wordState changes to 'COUNTER'
            if (wordState == 'COUNTER' && lastWordState != 'COUNTER') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                startCountdown(isHost, pack);
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
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoButton.tinted(
                            color: CupertinoColors.white,
                            child: Text(
                              'Back to Lobby',
                              style: TextStyle(color: CupertinoColors.white),
                            ),
                            onPressed: () {
                              if (!mounted) {
                                return;
                              }

                              FirebaseFirestore.instance
                                  .collection('games')
                                  .doc(gameCode)
                                  .update({
                                    'wordState': 'INIT',
                                    'gameStarted': false,
                                  });

                              Navigator.pushReplacement(
                                context,
                                CupertinoPageRoute(
                                  builder:
                                      (context) =>
                                          GameLobby(prefs: widget.prefs),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 10),
                          CupertinoButton.tinted(
                            color: CupertinoColors.white,
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              color: CupertinoColors.destructiveRed,
                            ),
                            onPressed: () {
                              if (!mounted) {
                                return;
                              }

                              // Prompt for confirmation
                              showCupertinoDialog(
                                context: context,
                                builder: (context) {
                                  return CupertinoAlertDialog(
                                    title: const Text('Stop Game'),
                                    content: const Text(
                                      'Are you sure you want to stop the game?',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: const Text('Cancel'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      CupertinoDialogAction(
                                        child: const Text('Stop'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          GameLobby.exitGame(
                                            context,
                                            gameCode,
                                            widget.prefs,
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(width: 10),
                          CupertinoButton.tinted(
                            color: CupertinoColors.white,
                            child: Text(
                              'Next Round',
                              style: TextStyle(color: CupertinoColors.white),
                            ),
                            onPressed: () {
                              if (!mounted) {
                                return;
                              }

                              initializeGame();
                            },
                          ),
                        ],
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
