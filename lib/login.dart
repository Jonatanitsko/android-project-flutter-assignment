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
  String error_msg = "";

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
  }

  Future _buildSignUp(AuthRepository auth) async {
    return showModalBottomSheet(
        context: this.context,
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
                    errorText: _valid ? null : error_msg,
                  )),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      textStyle: buttonFont,
                      primary: Colors.green,
                      onPrimary: Colors.white),
                  onPressed: () async {
                    if (_password.text == _passwordvalidation.text) {
                      try {
                        await auth.signUp(_email.text, _password.text);
                        setState(() {
                          user_in = true;
                        });
                      } catch (e) {
                        print(e.runtimeType);
                        setState(() {
                          _valid = false;
                          FocusScope.of(context).unfocus();
                          if(_password.text.length<6){
                            error_msg="The password must be of length greater than 6 chars.";
                          }else {
                            error_msg = e.toString();
                          }
                        });
                      }
                    } else {
                      setState(() {
                        FocusScope.of(context).unfocus();
                        _valid = false;
                        error_msg = 'The passwords must match.';
                      });
                    }
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
                                    SnackBar(
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
                      if (_email.text.isEmpty) {
                        _valid = false;
                        error_msg =
                            'In order to sign up, you must provide an email.';
                      } else if (_password.text.isEmpty) {
                        _valid = false;
                        error_msg =
                            'In order to sign up, you must provide a password.';
                      } else {
                        _valid = true;
                      }
                    });
                    if (_valid) {
                      await _buildSignUp(auth);
                      if (_valid) Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(error_msg)));
                    }
                  },
                );
              }))
        ],
      ),
    );
  }
}
