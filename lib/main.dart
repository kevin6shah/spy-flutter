import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spy/create_game.dart';
import 'package:spy/firebase_options.dart';

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

  void _setUserName(context) {
    final TextEditingController controller = TextEditingController(text: userName ?? '');

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
                    isLight()
                        ? 'assets/logos/spy.jpg'
                        : 'assets/logos/spy_dark.png',
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
                    onPressed: () {},
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
                        context,
                        CupertinoPageRoute(builder: (context2) => CreateGame()),
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
