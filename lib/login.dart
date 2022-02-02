import 'package:cs310socialmedia/feedPage.dart';
import 'package:cs310socialmedia/services/auth.dart';
import 'package:cs310socialmedia/utils/colors.dart';
import 'package:cs310socialmedia/utils/styles.dart';
import 'package:cs310socialmedia/welcome.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cs310socialmedia/services/Authentication.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs310socialmedia/services/Analytics.dart';
import 'package:cs310socialmedia/model/user.dart';
import 'package:cs310socialmedia/feedView.dart';
import 'package:cs310socialmedia/initialsearch.dart';
import 'package:cs310socialmedia/notification.dart';
import 'package:cs310socialmedia/profile.dart';
import 'package:cs310socialmedia/Upload.dart';
import 'package:cs310socialmedia/comments.dart';

final Reference storageRef= FirebaseStorage.instance.ref();
final commentsRef = FirebaseFirestore.instance.collection('comments');
final usersRef = FirebaseFirestore.instance.collection('Person');
final postsRef = FirebaseFirestore.instance.collection('Posts');
final activityFeedRef = FirebaseFirestore.instance.collection('Feed');
final followingRef=FirebaseFirestore.instance.collection('following');
final followersRef = FirebaseFirestore.instance.collection('followers');
final timelineRef = FirebaseFirestore.instance.collection('timeline');

final DateTime timestamp = DateTime.now();
User2 currentUser;

class LoginPage extends StatefulWidget {
  const LoginPage({Key key, this.analytics, this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _formKey = GlobalKey<FormState>();
  String email;
  String password;

  String _message;
  FirebaseAuth auth = FirebaseAuth.instance;
  Authentication authentication=Authentication();
  GoogleSignInAccount _userObj;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  String result;

  void setmessage(String msg) {
    setState(() {
      _message = msg;
      showAlertDialog('WARNING', _message);

    });
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> showAlertDialog(String title, String message) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false, //User must tap button
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(message),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {

                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
    );
  }

  Future<void> deneme(GoogleSignInAccount userCredential) async {
    var snapShot = await _firestore
        .collection("Person")
        .doc(userCredential.id).get();

    if (snapShot == null || !snapShot.exists) {
      await _firestore
          .collection("Person")
          .doc(userCredential.id)
          .set({
        "id":userCredential.id,
        "userName": userCredential.displayName,
        "password":"",
        "type":"public",
        "email": userCredential.email,
        "photoUrl": userCredential.photoUrl,
        "bio": "",
        "timestamp": timestamp,
        "displayName":userCredential.displayName,
        'deactivateUntil':timestamp.subtract(const Duration(days: 30)),
      });
      /*await followersRef
          .doc(userCredential.id)
          .collection('userFollowers')
          .doc(userCredential.id)
          .set({});*/

    }
    print(userCredential);
    print("helloooo");
    print(userCredential.id);
    DocumentSnapshot doc = await usersRef.doc(userCredential.id).get();
    Map _docdata = doc.data();
    currentUser=User2.fromDocument2(doc,_docdata);
    print(currentUser.id);
    if(currentUser.deactivateUntil.isAfter(DateTime.now())){
      showAlertDialog("Alert","This account is deactivated until: "+currentUser.deactivateUntil.toString());
    }
    else{
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  FeedPage(currentUser:currentUser,)));
    }
  }
  Future<void> loginUser() async {
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      DocumentSnapshot doc = await usersRef.doc(userCredential.user.uid).get();
      currentUser=User2.fromDocument(doc);
      //print(userCredential.toString());
      if(currentUser.deactivateUntil.isAfter(DateTime.now())){
        showAlertDialog("Alert","This account is deactivated until: "+currentUser.deactivateUntil.toString());
      }
      else{
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    FeedPage(currentUser:currentUser,)));
      }
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      if(e.code == 'user-not-found') {
        setmessage('You are not a user, please sign up');
      }
      else if (e.code == 'wrong-password') {
        setmessage('Please check your password');
      }
    }
  }
  @override
  void initState() {
    super.initState();
    setCurrentScreen(widget.analytics, widget.observer, 'SignIn Page', 'SignInState');
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[200],
        body: Stack(
          children: <Widget>[
            Container(
              height: 600.0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(100),
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),


            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
                Text('Welcome Back',
                    style: heading),
                SizedBox(height: 20.0,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget> [
                    ClipRRect(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                              height: 450.0,
                              width: 340.0,
                              decoration: BoxDecoration(
                                color:  AppColors.backgroundPage,
                              ),
                              child:Form(
                                key: _formKey,
                                child: ListView(
                                  padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 0.0),
                                  children: <Widget>[

                                    SizedBox(height: 60.0,),
                                    TextFormField(
                                      autocorrect: true,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        hintText: "Type your e-mail",
                                        errorStyle: TextStyle(
                                          fontSize: 13.0,
                                        ),
                                        prefixIcon: Icon(Icons.mail),
                                      ),
                                      validator: (input) {
                                        if (input.isEmpty) {
                                          return "E-mail is required";
                                        } else if (!input.contains('@')) {
                                          return "Please enter valid e-mail";
                                        }
                                        return null;
                                      },
                                      onChanged: (value){
                                        setState(() {
                                          email = value;
                                        });
                                      },
                                    ),
                                    SizedBox(height: 30.0,),
                                    TextFormField(
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        hintText: "Type your password",
                                        errorStyle: TextStyle(
                                          fontSize: 13.0,
                                        ),
                                        prefixIcon: Icon(Icons.lock),
                                      ),
                                      validator: (input) {
                                        if (input.isEmpty) {
                                          return "Password is required";
                                        } else if (input
                                            .trim()
                                            .length < 4) {
                                          return "Password is too short.";
                                        }
                                        return null;
                                      },
                                      onChanged: (value){
                                        setState(() {
                                          password = value;
                                        });
                                      },

                                    ),

                                    SizedBox(height: 30.0,),
                                    Row(children: <Widget>[
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            //FirebaseCrashlytics.instance.crash();
                                            if(!_formKey.currentState.validate()){return;}
                                            else {
                                              loginUser();
                                            }

                                          },
                                          child: Text(
                                              "Login",
                                              style: lsbutton
                                          ),
                                          style: OutlinedButton.styleFrom(
                                              backgroundColor: AppColors.headingColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30.0),
                                              )
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10.0,),
                                    ],
                                    ),
                                    SizedBox(height: 20.0,),
                                    Center(child: Text("or")),
                                    SizedBox(height: 20.0,),
                                    /* Center(child: Text("Continue with Google",
                                  style: TextStyle(
                                    fontSize: 19.0,
                                    fontWeight: FontWeight.bold,
                                    color:  AppColors.grey600,
                                  ),
                                )
                                ),*/
                                    Center(child:
                                    Row(
                                      children: [
                                        Padding(padding: EdgeInsets.only(left: 80.0)) ,
                                        Text("Sign in with ",
                                            style: lswithgoogle
                                        ),

                                        GestureDetector(
                                          onTap: () {
                                            authentication.googleSignIn().then((userData) {
                                              setState(() {

                                                _userObj = userData;//email, name,""

                                                deneme(_userObj);
                                                print(_userObj.displayName);
                                                print(_userObj.id);
                                                // Navigator.pushNamed(context,"/feed");

                                              });
                                            }).catchError((e) {
                                              print(e);
                                            });
                                          },
                                          child: Container(
                                            margin: EdgeInsets.symmetric(horizontal: 10),
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 2,
                                                color: AppColors.grey1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child:  Image(image: AssetImage('assets/google.png'),width: 30, height: 30,),
                                          ),
                                        ),
                                      ],
                                    )
                                    ),
                                  ],
                                ),
                              )
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

          ],
        ),
      ),

    );
  }

}