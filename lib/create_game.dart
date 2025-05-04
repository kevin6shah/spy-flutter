import 'dart:math';

import 'package:flutter/cupertino.dart';

class CreateGame extends StatefulWidget {
  const CreateGame({super.key});

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
                          children: List<Widget>.generate(5, (int index) {
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
              child: Text('Create Game'),
              onPressed: () {
                print(getRandom(6));
              },
            ),
          ],
        ),
      ),
    );
  }
}
