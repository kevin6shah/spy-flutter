import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spy/create_game.dart';
import 'package:spy/firebase_options.dart';
import 'package:spy/game_lobby.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MyHomePage(title: 'Spy');
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Brightness _brightness = Brightness.light;
  Future<SharedPreferences>? _prefsFuture;
  SharedPreferences? _prefs;
  String? userName;
  bool _hasPromptedForUserName = false;

  @override
  void initState() {
    super.initState();
    _prefsFuture = SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      if (_prefs!.containsKey('userName')) {
        userName = _prefs!.getString('userName');
      }
      return prefs;
    });
  }

  void _toggleBrightness() {
    setState(() {
      _brightness =
          _brightness == Brightness.light ? Brightness.dark : Brightness.light;
    });
  }

  bool isLight() {
    return _brightness == Brightness.light;
  }

  Future<bool> checkGameCode(String gameCode) async {
    DocumentSnapshot documentSnapshot =
        await FirebaseFirestore.instance
            .collection('games')
            .doc(gameCode)
            .get();
    if (documentSnapshot.exists) {
      return true;
    } else {
      return false;
    }
  }

  void showErrorDialog(BuildContext context, String invalidMessage) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('$invalidMessage. Please try again.'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  bool validateGameCode(String gameCode) {
    if (gameCode.isEmpty ||
        gameCode.length != 6 ||
        !RegExp(r'^[A-Z]+$').hasMatch(gameCode)) {
      return false;
    }
    // Add any other validation logic here if needed
    return true;
  }

  Future<bool> checkUserName(String userName, String gameCode) async {
    DocumentSnapshot documentSnapshot =
        await FirebaseFirestore.instance
            .collection('games')
            .doc(gameCode)
            .get();
    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      List<dynamic> players = data['players'] ?? [];
      List<String> playerNames =
          players.map((e) => e['name'].toString()).toList();
      return !playerNames.contains(userName);
    }
    return false;
  }

  void joinGameLobby(BuildContext context, String value) async {
    if (value.isEmpty || !mounted) {
      return;
    }

    if (validateGameCode(value) && await checkGameCode(value)) {
      if (await checkUserName(userName!, value)) {
        await _prefs!.setString('gameCode', value);
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          CupertinoPageRoute(builder: (context) => GameLobby(prefs: _prefs!)),
        );
      } else {
        // ignore: use_build_context_synchronously
        showErrorDialog(context, 'Username is already taken');
      }
    } else {
      // ignore: use_build_context_synchronously
      showErrorDialog(context, 'Invalid game code');
    }
  }

  void joinGame(BuildContext context) {
    TextEditingController controller = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: const Text('Join Game'),
          ),
          content: CupertinoTextField(
            placeholder: 'Enter game code',
            textCapitalization: TextCapitalization.characters,
            controller: controller,
            onChanged: (value) => controller.text = value,
            onSubmitted: (value) => joinGameLobby(context, value),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: const Text('Join'),
              onPressed: () => joinGameLobby(context, controller.text),
            ),
          ],
        );
      },
    );
  }

  void _setUserName(context) {
    final TextEditingController controller = TextEditingController(
      text: userName ?? '',
    );

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: const Text('Set User Name'),
          ),
          content: CupertinoTextField(
            placeholder: 'Enter your name',
            controller: controller,
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () async {
                if (controller.text.isEmpty) {
                  return;
                }

                setState(() {
                  userName = controller.text;
                });

                if (_prefs != null) {
                  _prefs!.setString('userName', userName!);
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Spy',
      theme: CupertinoThemeData(
        brightness: _brightness,
        primaryColor:
            isLight()
                ? CupertinoColors.black
                : CupertinoColors.lightBackgroundGray,
        textTheme: CupertinoTextThemeData(
          primaryColor:
              isLight() ? CupertinoColors.black : CupertinoColors.white,
        ),
      ),
      home: FutureBuilder(
        future: _prefsFuture,
        builder: (context2, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          _prefs = snapshot.data;

          if (_prefs!.containsKey('userName')) {
            userName = _prefs!.getString('userName');
          } else if (!_hasPromptedForUserName) {
            _hasPromptedForUserName =
                true; // <-- Set flag so dialog only shows once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _setUserName(context2);
            });
          }

          if (_prefs!.containsKey('gameCode')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context2,
                CupertinoPageRoute(
                  builder: (context) => GameLobby(prefs: _prefs!),
                ),
              );
            });
          }

          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(widget.title),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _setUserName(context2),
                child: Icon(
                  CupertinoIcons.person,
                  color:
                      isLight() ? CupertinoColors.black : CupertinoColors.white,
                ),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _toggleBrightness,
                child: Icon(
                  _brightness == Brightness.light
                      ? CupertinoIcons.moon
                      : CupertinoIcons.sun_max,
                  color:
                      isLight() ? CupertinoColors.black : CupertinoColors.white,
                ),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/logos/spy.png',
                    color:
                        isLight()
                            ? CupertinoColors.black
                            : CupertinoColors.white,
                  ),
                  CupertinoButton.filled(
                    child: Text(
                      'Join Game',
                      style: TextStyle(
                        color:
                            isLight()
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                      ),
                    ),
                    onPressed: () => joinGame(context2),
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    child: Text(
                      'Create Game',
                      style: TextStyle(
                        color:
                            isLight()
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context2,
                        CupertinoPageRoute(
                          builder:
                              (context) => CreateGame(
                                userName: userName!,
                                prefs: _prefs!,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ThemeUtils {
  static bool isLightMode(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    return brightness == Brightness.light;
  }
}
