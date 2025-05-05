// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spy/game_lobby.dart';
import 'package:spy/main.dart';

class CreateGame extends StatefulWidget {
  final String userName;
  final SharedPreferences prefs;
  const CreateGame({super.key, required this.userName, required this.prefs});

  @override
  State<CreateGame> createState() => _CreateGameState();
}

class _CreateGameState extends State<CreateGame> {
  int numberOfPlayers = 3;
  int numberOfSpies = 1;

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => Container(
            height: 216,
            padding: const EdgeInsets.only(top: 6.0),
            // The Bottom margin is provided to align the popup above the system navigation bar.
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            // Provide a background color for the popup.
            color: CupertinoColors.systemBackground.resolveFrom(context),
            // Use a SafeArea widget to avoid system overlaps.
            child: SafeArea(top: false, child: child),
          ),
    );
  }

  Future<String> createGame() async {
    String gameCode = getRandom(6);
    await FirebaseFirestore.instance
        .collection('games')
        .doc(gameCode)
        .set({
          'host': widget.userName,
          'numPlayers': numberOfPlayers,
          'numSpies': numberOfSpies,
          'players': [
            {'name': widget.userName, 'isHost': true, 'isSpy': false},
          ],
          'wordState': 'INIT',
          'gameStarted': false,
        })
        .catchError((error) {
          gameCode = 'ERROR';
        });

    return gameCode;
  }

  String getRandom(int length) {
    const ch = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    Random r = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => ch.codeUnitAt(r.nextInt(ch.length))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Create Game')),

      // Form that can be used to create a game
      // choose number of players
      // choose number of spies
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Column(
              children: [
                GestureDetector(
                  onTap:
                      () => _showDialog(
                        CupertinoPicker(
                          magnification: 1.22,
                          squeeze: 1.2,
                          useMagnifier: true,
                          itemExtent: 32.0,
                          onSelectedItemChanged: (int selectedItem) {
                            setState(() {
                              numberOfPlayers = selectedItem + 3;
                            });
                          },
                          children: List<Widget>.generate(18, (int index) {
                            index = index + 3;
                            return Center(child: Text('$index'));
                          }),
                        ),
                      ),
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.person_3, size: 100),
                      Text('Players: $numberOfPlayers'),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap:
                      () => _showDialog(
                        CupertinoPicker(
                          magnification: 1.22,
                          squeeze: 1.2,
                          useMagnifier: true,
                          itemExtent: 32.0,
                          onSelectedItemChanged: (int selectedItem) {
                            setState(() {
                              numberOfSpies = selectedItem + 1;
                            });
                          },
                          children: List<Widget>.generate(numberOfPlayers, (
                            int index,
                          ) {
                            index = index + 1;
                            return Center(child: Text('$index'));
                          }),
                        ),
                      ),
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.eye_slash, size: 100),
                      Text('Spies: $numberOfSpies'),
                    ],
                  ),
                ),
              ],
            ),
            CupertinoButton.filled(
              child: Text(
                'Create Game',
                style: TextStyle(
                  color:
                      ThemeUtils.isLightMode(context)
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                ),
              ),
              onPressed: () async {
                if (!mounted) return;
                String gameCode = await createGame();
                await widget.prefs.setString('gameCode', gameCode);

                if (gameCode != 'ERROR') {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder:
                          (context) =>
                              GameLobby(prefs: widget.prefs, createdGame: true),
                    ),
                  );
                } else {
                  // Handle error
                  showCupertinoDialog(
                    context: context,
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('Error'),
                          content: const Text('Failed to create game.'),
                          actions: <Widget>[
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
