import 'package:flutter/cupertino.dart';
import 'package:spy/create_game.dart';

void main() {
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

  void _toggleBrightness() {
    setState(() {
      _brightness =
          _brightness == Brightness.light ? Brightness.dark : Brightness.light;
    });
  }

  bool isLight() {
    return _brightness == Brightness.light;
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
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.title),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _toggleBrightness,
            child: Icon(
              _brightness == Brightness.light
                  ? CupertinoIcons.moon
                  : CupertinoIcons.sun_max,
              color: isLight() ? CupertinoColors.black : CupertinoColors.white,
            ),
          ),
        ),
        child: Builder(
          builder:
              (context) => Center(
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
                          CupertinoPageRoute(builder: (context) => CreateGame()),
                        );
                      },
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
