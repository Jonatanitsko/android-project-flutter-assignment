import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hello_me/user.dart';
import 'package:hello_me/main.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();
  TextEditingController _passwordvalidation = TextEditingController();
  bool _loadingin = false;
  bool _valid = true;
  bool user_in = false;

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
  }

  Future _buildSignUp(AuthRepository auth) async {
    return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return ListView(
            children: [
              Text(
                'Please confirm your password below:',
                style: biggerFont,
              ),
              Divider(),
              TextField(
                  style: biggerFont,
                  controller: _passwordvalidation,
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Password',
                    errorText: _valid ? null : 'Passwords mush match',
                  )),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      textStyle: buttonFont,
                      primary: Colors.green,
                      onPrimary: Colors.white),
                  onPressed: () async {
                    _password.text == _passwordvalidation.text
                        ? (await auth.signUp(_email.text, _password.text) !=
                                null
                            ? setState(() {
                                user_in = true;
                              })
                            : setState(() {
                                FocusScope.of(context).unfocus();
                                const SnackBar(
                                    content: Text(
                                        'There was an error signing up into the app'));
                              }))
                        : setState(() {
                            FocusScope.of(context).unfocus();
                            _valid = false;
                          });
                  },
                  child: Text('Confirm'))
            ],
          );
        });
  }

/**/
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: ListView(
        children: [
          Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              child: Text(
                'Welcome to Startup Names Generator, please log in below',
                style: biggerFont,
              )),
          Container(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: _email,
              decoration: InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Email',
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: _password,
              decoration: InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Password',
              ),
            ),
          ),
          Container(
              padding: EdgeInsets.all(8),
              child: Consumer<AuthRepository>(
                  builder: (context, auth, _) => !_loadingin
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red,
                            textStyle: buttonFont,
                            onPrimary: Colors.white,
                            shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(27.0),
                            ),
                          ),
                          child: Text('Log in'),
                          onPressed: () async {
                            setState(() {
                              _loadingin = true;
                            });
                            await auth.signIn(_email.text, _password.text)
                                ? Navigator.pop(context)
                                : ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'There was an error logging into the app')));
                          },
                        )
                      : LinearProgressIndicator(
                          semanticsLabel: 'Login loading indicator',
                        ))),
          Container(
              padding: EdgeInsets.all(8),
              child: Consumer<AuthRepository>(builder: (context, auth, _) {
                user_in ? Navigator.pop(context) : print('Hi');
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    textStyle: buttonFont,
                    primary: Colors.green,
                    onPrimary: Colors.white,
                    shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(27.0),
                    ),
                  ),
                  child: Text('New user? Click to sign up'),
                  onPressed: () async {
                    setState(() {
                      _valid = true;
                    });
                    await _buildSignUp(auth);
                    Navigator.pop(context);
                  },
                );
              }))
        ],
      ),
    );
  }
}
