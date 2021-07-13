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
  Status _status = Status.Uninitialized;
  List<WordPair> _wordpairList = <WordPair>[];
  String? _photo;
  bool _fav_init=false;

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
     _auth.authStateChanges().listen(_onAuthStateChanged);
    _onAuthStateChanged(_auth.currentUser);
  }

  String? get photo=> _photo;

  Status get status => _status;

  User? get user => _auth.currentUser;

  bool get isAuthenticated => status == Status.Authenticated;

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      UserCredential user_res = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      FirebaseFirestore _firestore = FirebaseFirestore.instance;
      await _firestore
          .collection("favorites")
          .doc(user!.email)
          .set({"list": []});
      notifyListeners();
      return user_res;
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      throw(e);
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await getFav();
      _photo=_auth.currentUser!.photoURL;
      notifyListeners();
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
      _status = Status.Unauthenticated;
    } else {
      _photo = _auth.currentUser!.photoURL;
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
  SnappingSheetController snapController = SnappingSheetController();
  final bottom_snap = SnappingPosition.factor(
    positionFactor: 0.0,
    snappingCurve: Curves.easeOutExpo,
    snappingDuration: Duration(seconds: 0),
    grabbingContentOffset: GrabbingContentOffset.top,
  );
  final mid_snap = SnappingPosition.pixels(
    positionPixels: 200,
    snappingCurve: Curves.elasticOut,
    grabbingContentOffset: GrabbingContentOffset.bottom,
  );
  final top_snap = SnappingPosition.factor(
    positionFactor: 0.9,
    snappingCurve: Curves.bounceOut,
    grabbingContentOffset: GrabbingContentOffset.top,
  );

  Widget _buildProfile(AuthRepository auth) {
    Widget img = auth.photo==null? Icon(Icons.no_photography_outlined) : Image.file(File(auth.photo!));
    return Container(
        alignment: Alignment.center,
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
           Flexible( fit:FlexFit.loose,
               child: Container(
                child:img)),
                Flexible(fit:FlexFit.loose,flex:2,
                    child: Container(
                child: ListView(shrinkWrap: true,
                  children: [
                    Text(auth.user!.email! ,textAlign: TextAlign.center,style: biggerFont),
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
                )))
          ],
        ));
  }

  bool finished_snapping = false;
  final no_blur = BackdropFilter(filter: ui.ImageFilter.blur());
  final blur = BackdropFilter(
    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    child: Container(color: Colors.black.withOpacity(0)),
  );

  _ProfilePageState():snapController=SnappingSheetController(){}

  @override
  void initState() {
    snapController = SnappingSheetController();
    to_blur=false;
  }
  bool to_blur=false;

  @override
  Widget build(BuildContext context) {
    var bottomHeight = MediaQuery.of(context).viewInsets.bottom;
    return Consumer<AuthRepository>(builder: (context, auth, _) {
      return auth.isAuthenticated
          ? Scaffold(
              body: SnappingSheet(
                onSheetMoved:(num){
                  setState(() {
                    to_blur= num<=25 ? false : true;
                  });
              },
              controller: snapController,
              grabbingHeight: 50,
              child: SnappingSheetBody(),
              lockOverflowDrag: true,
              grabbing: Container(
                  color: Colors.grey,
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          snapController.currentlySnapping
                              ? null
                              : snapController.snapToPosition(bottom_snap);
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
                onSnapCompleted: (double d,SnappingPosition snap){
                  print(d);
                  if(d>200){
                    snapController.snapToPosition(mid_snap);
                  }
                },
            ))
          : RandomWords();
    });
  }

  Widget SnappingSheetBody(){
  //  print(snapController.currentPosition);
    //print(mid_snap.grabbingContentOffset);
    return Stack(fit: StackFit.expand, children: [
      RandomWords(),
      snapController.isAttached?  to_blur ? blur : no_blur:no_blur,
    ]);
  }
}
