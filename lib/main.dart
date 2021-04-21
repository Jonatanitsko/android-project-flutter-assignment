import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:hello_me/favorites.dart';
import 'package:hello_me/login.dart';
import 'package:provider/provider.dart';
import 'package:hello_me/user.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

final biggerFont = const TextStyle(fontSize: 18);
final buttonFont = const TextStyle(fontSize: 16);

void _pushPage(BuildContext context, Widget page) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => AuthRepository.instance(),
        child: MaterialApp(
          title: 'Startup Name Generator',
          theme: ThemeData(
            primaryColor: Colors.red,
            backgroundColor: Colors.white,
          ),
          home: ProfilePage(),
        ));
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18);

  Widget _buildRow(WordPair pair) {
    return Consumer<AuthRepository>(
      builder: (context, auth, _) {
        final alreadySaved = auth.wordpair_list.contains(pair);
        return ListTile(
          title: Text(
            pair.asPascalCase,
            style: _biggerFont,
          ),
          trailing: Icon(
            alreadySaved ? Icons.favorite : Icons.favorite_border,
            color: alreadySaved ? Colors.red : null,
          ),
          onTap: () {
            setState(() {
              if (alreadySaved) {
                auth.remove_pair(pair);
              } else {
                auth.add_pair(pair);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return Divider();
          }

          final int index = i ~/ 2;

          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }

          return _buildRow(_suggestions[index]);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(builder: (context, auth, _) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Startup Name Generator'),
          actions: [
            IconButton(
                icon: Icon(Icons.list),
                onPressed: () => _pushPage(context, FavoritesScreen())),
            LoginButton(),
          ],
        ),
        body: _buildSuggestions(),
      );
    });
  }
}

class LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(builder: (context, auth, _) {
      return IconButton(
          icon: auth.status != Status.Authenticated
              ? Icon(Icons.login)
              : Icon(Icons.exit_to_app),
          onPressed: () => auth.status != Status.Authenticated
              ? _pushPage(context, LoginScreen())
              : auth.signOut());
    });
  }
}
