import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spy/main.dart';

class GameLobby extends StatefulWidget {
  const GameLobby({super.key, required this.prefs, this.createdGame = false});
  final SharedPreferences prefs;
  final bool createdGame;

  @override
  State<GameLobby> createState() => _GameLobbyState();
}

class _GameLobbyState extends State<GameLobby> {
  String gameCode = '';
  String userName = '';

  bool isHost = false;

  Future<bool> userExists(String gameCode, String userName) async {
    final doc = await FirebaseFirestore.instance
        .collection('games')
        .doc(gameCode)
        .get();

    if (doc.exists) {
      final players = doc.data()?['players'] as List<dynamic>;
      return players.any((player) => player['name'] == userName);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    gameCode = widget.prefs.getString('gameCode') ?? '';
    userName = widget.prefs.getString('userName') ?? '';

    if (gameCode.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => const MyApp()),
        );
      });
    } else {
      userExists(gameCode, userName).then((exists) {
        if (!exists) {
          FirebaseFirestore.instance
              .collection('games')
              .doc(gameCode)
              .update({
                'players': FieldValue.arrayUnion([
                  {'name': userName, 'isHost': false, 'isSpy': false},
                ]),
              });
        }
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Game Lobby')),
      child: StreamBuilder<Object>(
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

          // Check if the user is the host
          isHost = gameData['host'] == userName;

          List<Map<String, dynamic>> allPlayers =
              (gameData['players'] as List<dynamic>)
                  .map((e) => e as Map<String, dynamic>)
                  .toList();

          // Aggregate the players into rows of 4
          List<List<Map<String, dynamic>>> rows = [];
          for (int i = 0; i < allPlayers.length; i += 4) {
            rows.add(
              allPlayers.sublist(
                i,
                i + 4 > allPlayers.length ? allPlayers.length : i + 4,
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    SizedBox(height: 30),
                    CupertinoButton.tinted(
                      child: Text(
                        'Game Code: $gameCode',
                        style: const TextStyle(fontSize: 24),
                      ),
                      onPressed: () {},
                    ),
                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoButton.tinted(
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.person_fill, size: 30),
                              SizedBox(width: 10),
                              Text('${gameData['numPlayers']}'),
                            ],
                          ),
                          onPressed: () {
                            if (!isHost) {
                              return;
                            }

                            _showDialog(
                              CupertinoPicker(
                                magnification: 1.22,
                                squeeze: 1.2,
                                useMagnifier: true,
                                itemExtent: 32.0,
                                onSelectedItemChanged: (int selectedItem) {
                                  FirebaseFirestore.instance
                                      .collection('games')
                                      .doc(gameCode)
                                      .update({'numPlayers': selectedItem + 3});
                                },
                                children: List<Widget>.generate(18, (
                                  int index,
                                ) {
                                  index = index + 3;
                                  return Center(child: Text('$index'));
                                }),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 10),
                        CupertinoButton.tinted(
                          child: Row(
                            children: [
                              Text('${gameData['numSpies']}'),
                              SizedBox(width: 10),
                              Icon(CupertinoIcons.eye_slash, size: 30),
                            ],
                          ),
                          onPressed: () {
                            if (!isHost) {
                              return;
                            }

                            _showDialog(
                              CupertinoPicker(
                                magnification: 1.22,
                                squeeze: 1.2,
                                useMagnifier: true,
                                itemExtent: 32.0,
                                onSelectedItemChanged: (int selectedItem) {
                                  FirebaseFirestore.instance
                                      .collection('games')
                                      .doc(gameCode)
                                      .update({'numSpies': selectedItem + 1});
                                },
                                children: List<Widget>.generate(5, (int index) {
                                  index = index + 1;
                                  return Center(child: Text('$index'));
                                }),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 30),

                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                rows[index]
                                    .map(
                                      (player) => profileCard(
                                        context,
                                        player['name'],
                                        player['isHost'],
                                      ),
                                    )
                                    .toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                isHost
                    ? Column(
                      children: [
                        CupertinoButton.tinted(
                          color: CupertinoColors.systemFill,
                          child: Text(
                            'Start Game',
                            style: TextStyle(
                              color:
                                  (allPlayers.length < gameData['numPlayers'])
                                      ? CupertinoColors.inactiveGray
                                      : CupertinoColors.label,
                            ),
                          ),
                          onPressed: () {
                            if (allPlayers.length < gameData['numPlayers']) {
                              showCupertinoDialog(
                                context: context,
                                builder:
                                    (context) => CupertinoAlertDialog(
                                      title: const Text('Not enough players'),
                                      content: const Text(
                                        'Please wait for more players to join.',
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('OK'),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                              );
                            } else {}
                          },
                        ),
                        SizedBox(height: 15),
                        CupertinoButton.filled(
                          child: Text('Exit Game'),
                          onPressed: () {
                            if (!mounted) {
                              return;
                            }

                            FirebaseFirestore.instance
                                .collection('games')
                                .doc(gameCode)
                                .delete();

                            widget.prefs.remove('gameCode');

                            Navigator.pushReplacement(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => const MyApp(),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                    : CupertinoButton.filled(
                      child: Text('Leave Game'),
                      onPressed: () async {
                        if (!mounted) {
                          return;
                        }

                        FirebaseFirestore.instance
                            .collection('games')
                            .doc(gameCode)
                            .set({
                              'players': FieldValue.arrayRemove([
                                {
                                  'name': userName,
                                  'isHost': false,
                                  'isSpy': false,
                                },
                                {
                                  'name': userName,
                                  'isHost': false,
                                  'isSpy': true,
                                },
                              ]),
                            }, SetOptions(merge: true));

                        await widget.prefs.remove('gameCode');

                        Navigator.pushReplacement(
                          // ignore: use_build_context_synchronously
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const MyApp(),
                          ),
                        );
                      },
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget profileCard(BuildContext context, String playerName, bool isHost) {
  return CupertinoButton(
    onPressed: () {
      // Handle button press
    },
    child: Column(
      children: [
        Icon(CupertinoIcons.person, size: 40),
        Text(playerName),
        if (isHost)
          Text(
            '(host)',
            style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
          ),
      ],
    ),
  );
}
