import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs310socialmedia/model/user.dart';
import 'package:cs310socialmedia/utils/colors.dart';
import 'package:cs310socialmedia/utils/progress.dart';
import 'package:cs310socialmedia/utils/styles.dart';
import 'package:cs310socialmedia/welcome.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:cs310socialmedia/login.dart';
import 'package:image_picker/image_picker.dart';
import 'model/post.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cs310socialmedia/services/Analytics.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';

final DateTime deactivateUntil = DateTime.now().add(const Duration(days: 30));

class ProfileEdit extends StatefulWidget {
  final String currentUserId;
  const ProfileEdit({this.currentUserId,Key key, this.analytics, this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  @override
  _ProfileEdit createState() => _ProfileEdit();
}

class _ProfileEdit extends State<ProfileEdit> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController idController = TextEditingController();
  TextEditingController pass_valController = TextEditingController();
  bool isLoading = false;
  User2 user;
  bool _displayNameValid = true;
  bool _bioValid = true;
  bool _passValid = true;
  final _picker = ImagePicker();
  File file;
  PickedFile pickedFile;
  bool isUploading=false;

  get googleSignIn => null;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  uploadImage(imageFile) async {
    String id =user.id;
    UploadTask uploadTask=storageRef.child("post_$id.jpg").putFile(imageFile);
    var downloadUrl = await (await uploadTask).ref.getDownloadURL();
    urlController.text = downloadUrl;
    print("mert");
    print(downloadUrl);
    print(urlController.text);
  }
  handleTakePhoto() async {
    print("entered!!");
    Navigator.pop(context);
    PickedFile pickedFile = await _picker.getImage( source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,);
    file = File(pickedFile.path);
    setState(() {
      this.file = file;
    });
    uploadImage(this.file);
  }
  handleChooseFromGallery() async {
    print("entered!!");
    Navigator.pop(context);
    PickedFile pickedFile = await _picker.getImage(source: ImageSource.gallery,);
    file = File(pickedFile.path);
    setState(() {
      this.file = file;
    });
    uploadImage(this.file);
  }
  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Edit Profile Picture"),
          children: <Widget>[
            SimpleDialogOption(
                child: Text("Photo with Camera"), onPressed: handleTakePhoto),
            SimpleDialogOption(
                child: Text("Image from Gallery"),
                onPressed: handleChooseFromGallery),
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.doc(widget.currentUserId).get();
    user = User2.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    typeController.text=user.type;
    urlController.text=user.photoUrl;
    idController.text = user.id;
    pass_valController.text=user.password;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Display Name",
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "Update Display Name",
            errorText: _displayNameValid ? null : "Display Name too short",
          ),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update Bio",
            errorText: _bioValid ? null : null,
          ),
        )
      ],
    );
  }
  Column buildPasswordField() {
    if(pass_valController.text!=""){
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Password",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextField(
            controller: passController,
            decoration: InputDecoration(
              hintText: "Update Password",
              errorText: _passValid ? null : null,
            ),
          )
        ],
      );
    }
    return Column(
      children:[
        Text(""),
      ]
    );
  }
  updateProfileData() {
    setState(() {
      displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioController.text.isEmpty
          ? _bioValid = false
          : _bioValid = true;
      passController.text.isEmpty
          ? _passValid = false
          : _passValid = true;

    });

    usersRef.doc(widget.currentUserId).update({
      "photoUrl": urlController.text,
    });

    if (_displayNameValid && _bioValid && _passValid) {
      usersRef.doc(widget.currentUserId).update({
        "displayName": displayNameController.text,
        "bio": bioController.text,
        "password":passController.text,
        "photoUrl": urlController.text,
        "type":typeController.text,
      });

      var user = FirebaseAuth.instance.currentUser;
      user.updatePassword(passController.text);
    }
    if (_displayNameValid &&  _bioValid && !_passValid) {
      usersRef.doc(widget.currentUserId).update({
        "displayName": displayNameController.text,
        "bio": bioController.text,
        "photoUrl": urlController.text,
        "type":typeController.text,
      });}
    if (_displayNameValid && !_bioValid && !_passValid) {
      usersRef.doc(widget.currentUserId).update({
        "displayName": displayNameController.text,
        "photoUrl": urlController.text,
        "type":typeController.text,
      });}
    if (!_displayNameValid && _bioValid && !_passValid) {
      usersRef.doc(widget.currentUserId).update({
        "bio": bioController.text,
        "photoUrl": urlController.text,
        "type":typeController.text,
      });}
    else if(_passValid){
      usersRef.doc(widget.currentUserId).update({
        "password":passController.text,
      });
      var user = FirebaseAuth.instance.currentUser;
      user.updatePassword(passController.text);
    }
    SnackBar snackbar = SnackBar(content: Text("Profile updated!"));
    _scaffoldKey.currentState.showSnackBar(snackbar);

  }
  changeStatus(){
    if(typeController.text=="public"){
      typeController.text="private";
    }
    else if(typeController.text=="private"){
      typeController.text="public";
    }
  }
  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 150.0,
          height: 33.0,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue,
            border: Border.all(
              color: Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }
  logout() async {
    GoogleSignIn _googleSignIn = GoogleSignIn();
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    // await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Welcome()));
  }
  deactivateAccount() async{
    await usersRef
        .doc(idController.text)
        .update({
      "deactivateUntil":deactivateUntil,
    });
    logout();
  }
  deleteAccount() async{
    FirebaseAuth.instance.currentUser.delete();
    //await FirebaseAuth.instance.signOut();
    usersRef.doc(widget.currentUserId).delete();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Welcome()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.done,
              size: 30.0,
              color: Colors.green,
            ),
          ),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Row(
                    mainAxisAlignment:MainAxisAlignment.center,
                    children:<Widget>[

                      Padding(
                        padding: EdgeInsets.only(
                          top: 16.0,
                          bottom: 8.0,
                        ),
                        child: GestureDetector(
                          onTap: (){
                            selectImage(context);
                            print("mert123");
                            uploadImage(this.file);
                          },
                          child: CircleAvatar(
                            radius: 50.0,
                            backgroundImage:
                            CachedNetworkImageProvider(user.photoUrl),
                          ),
                        ),

                      ),
                      SizedBox(width:10),
                      SizedBox.fromSize(
                        size: Size(40, 40), // button width and height
                        child: ClipOval(
                          child: Material(
                            color: Colors.grey[400], // button color
                            child: InkWell(
                              splashColor: Colors.blue, // splash color
                              onTap: () {Navigator.pushNamed(context, '/edit');}, // button pressed
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  if(typeController.text=="public")
                                    Icon(Icons.public),
                                  if (typeController.text=="private")
                                    Icon(Icons.public_off),
                                  // icon
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      buildDisplayNameField(),
                      buildBioField(),
                      buildPasswordField(),
                      RaisedButton(
                        onPressed: changeStatus,
                        color:Colors.blue,
                        child: Text(
                          "Change Status",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                RaisedButton(
                  onPressed: updateProfileData,
                  child: Text(
                    "Update Profile",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(0.0),
                  child: FlatButton.icon(
                    onPressed: logout,
                    icon: Icon(Icons.cancel, color: Colors.red),
                    label: Text(
                      "Logout",
                      style: TextStyle(color: Colors.red, fontSize: 20.0),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(0.0),
                  child: FlatButton.icon(
                    onPressed: deleteAccount,
                    icon: Icon(Icons.restore_from_trash, color: Colors.red),
                    label: Text(
                      "Delete Account",
                      style: TextStyle(color: Colors.red, fontSize: 20.0),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(0.0),
                  child: FlatButton.icon(
                    onPressed: deactivateAccount,
                    icon: Icon(Icons.restore_from_trash, color: Colors.red),
                    label: Text(
                      "Deactivate Account",
                      style: TextStyle(color: Colors.red, fontSize: 20.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}