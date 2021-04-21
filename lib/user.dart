import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:hello_me/main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;
  List<WordPair> _wordpairList = <WordPair>[];
  String? _photo;

  List<WordPair> get wordpair_list => _wordpairList;

  void add_pair(WordPair pair) {
    _wordpairList.add(pair);
    notifyListeners();
  }

  bool remove_pair(WordPair pair) {
    final res = _wordpairList.remove(pair);
    notifyListeners();
    return res;
  }

  AuthRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.signOut();
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _photo=_user!.photoURL;
    _onAuthStateChanged(_user);
  }

  String? get photo=> _photo;

  Status get status => _status;

  User? get user => _user;

  bool get isAuthenticated => status == Status.Authenticated;

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      UserCredential user_res = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      FirebaseFirestore _firestore = FirebaseFirestore.instance;
      await _firestore
          .collection("favorites")
          .doc(user!.email)
          .set({"list": []});
      return user_res;
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await getFav();
      return true;
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  void updateFav() async {
    try {
      if (!isAuthenticated) return;
      FirebaseFirestore _firestore = FirebaseFirestore.instance;
      List<String> to_up = _wordpairList
          .map((WordPair wordPairItem) => wordPairItem.asPascalCase.toString())
          .toList();
      await _firestore
          .collection("favorites")
          .doc(user!.email)
          .set({"list": to_up});
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return;
    }
  }

  Future<bool> getFav() async {
    try {
      if (!isAuthenticated) return false;
      FirebaseFirestore _firestore = FirebaseFirestore.instance;
      await _firestore
          .collection("favorites")
          .doc(user!.email)
          .get()
          .then((value) {
        List.from(value.data()!['list']).forEach((element) {
          final beforeNonLeadingCapitalLetter = RegExp(r"(?=(?!^)[A-Z])");
          List<String> splitPascalCase(String input) =>
              input.split(beforeNonLeadingCapitalLetter);
          List<String> split = splitPascalCase(element.toString());
          WordPair pair =
              new WordPair(split[0].toLowerCase(), split[1].toLowerCase());
          _wordpairList.add(pair);
        });
      });
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future signOut() async {
    updateFav();
    _auth.signOut();
    _status = Status.Unauthenticated;
    _wordpairList = <WordPair>[];
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future updatePhoto(String path) async{
    _photo=path;
    await user!.updateProfile(photoURL: _photo);
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _photo = _user!.photoURL;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _snapController = SnappingSheetController();
  final bottom_snap = SnappingPosition.factor(
    positionFactor: 0.0,
    snappingCurve: Curves.easeOutExpo,
    snappingDuration: Duration(seconds: 0),
    grabbingContentOffset: GrabbingContentOffset.top,
  );
  final mid_snap = SnappingPosition.pixels(
    positionPixels: 300,
    snappingCurve: Curves.elasticOut,
  );
  final top_snap = SnappingPosition.factor(
    positionFactor: 0.9,
    snappingCurve: Curves.bounceOut,
    grabbingContentOffset: GrabbingContentOffset.top,
  );

  Widget _buildProfile(AuthRepository auth) {

    return Container(
        height: 200,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.all(0),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
                constraints: BoxConstraints(maxWidth: 50, maxHeight: 100),
                width: 50,
                height: 100,
                child: Image.file(File(auth.photo!))),
            Container(
                width: 200,
                height: 200,
                child: ListView(
                  children: [
                    Text(auth.user!.email!, style: biggerFont),
                    ElevatedButton(
                        onPressed: () async {
                          PickedFile? result = await ImagePicker()
                              .getImage(source: ImageSource.gallery);
                          if (result != null) {
                            await auth.updatePhoto(result.path);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('No image selected')));
                          }
                        },
                        child: Text('Change avatar', style: biggerFont)),
                  ],
                ))
          ],
        ));
  }

  bool finished_snapping = false;
  final no_blur = BackdropFilter(filter: ui.ImageFilter.blur());
  final blur = BackdropFilter(
    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    child: Container(color: Colors.black.withOpacity(0)),
  );


  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(builder: (context, auth, _) {
      return auth.isAuthenticated
          ? Scaffold(
              body: SnappingSheet(
              controller: _snapController,
              grabbingHeight: 50,
              child: Stack(fit: StackFit.expand, children: [
                RandomWords(),
               // _snapController.currentlySnapping ? blur : no_blur,
              ]),
              lockOverflowDrag: true,
              grabbing: Container(
                  color: Colors.grey,
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _snapController.currentlySnapping
                              ? null
                              : _snapController.snapToPosition(bottom_snap);
                        });
                      },
                      child: Row(
                        children: [
                          Text('Welcome back, ${auth.user!.email}',
                              style: biggerFont),
                          Icon(Icons.keyboard_arrow_up),
                        ],
                      ))),
              sheetBelow: SnappingSheetContent(
                  draggable: true, child: _buildProfile(auth)),
              snappingPositions: [
                bottom_snap,
                mid_snap,
                top_snap,
              ],
            ))
          : RandomWords();
    });
  }
}
