import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs310socialmedia/postCard.dart';
import 'package:cs310socialmedia/utils/progress.dart';
import 'package:flutter/material.dart';
import 'package:cs310socialmedia/login.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';
import 'package:cs310socialmedia/model/user.dart';

//final DateTime timestamp2 = DateTime.now();
class PostReshare extends StatefulWidget {
  final User2 currentUser;
  final String postId;
  final String ownerId;
  const PostReshare({this.postId,this.ownerId,this.currentUser});

  @override
  _PostReshare createState() => _PostReshare();
}

class _PostReshare extends State<PostReshare> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  TextEditingController locationController=TextEditingController();
  TextEditingController captionController=TextEditingController();
  bool isLoading = false;
  PostCard post;
  bool _descriptionValid=true;
  String postId=Uuid().v4();
  bool isUploading=false;
  get googleSignIn => null;

  @override
  void initState() {
    super.initState();
    getPost();
  }

  getPost() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await postsRef.doc(widget.ownerId)
        .collection('userPosts')
        .doc(widget.postId).get();
    post = PostCard.fromDocument(doc);
    urlController.text=post.mediaUrl;
    setState(() {
      isLoading = false;
    });
  }
  createPostInFirestore({String mediaUrl, String location, String description}){
    print("firestore");
    print(currentUser.userName);
    print("hellooooo post reshare");
    print(timestamp);
    postsRef
        .doc(currentUser.id)
        .collection("userPosts")
        .doc(postId)
        .set({
      "postId":postId,
      "ownerId":currentUser.id,
      "username":currentUser.userName,
      "mediaUrl":mediaUrl,
      "description":description,
      "location":location,
      "timestamp":timestamp,
      "likes":{},
      "dislikes":{},
    });
  }
  handleSubmit()async{
    print(isUploading);
    setState(() {
      isUploading=true;
    });

    createPostInFirestore(
      mediaUrl: post.mediaUrl,
      location: locationController.text,
      description: descriptionController.text,
    );

    print(isUploading);
    locationController.clear();
    descriptionController.clear();
    setState(() {
      isUploading=false;
      postId=Uuid().v4();
    });
  }

  Column buildDescriptionField() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Post of" "@"+post.username ,
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            hintText: " Say something!",
            errorText: _descriptionValid ? null : "Display Name too short",
          ),
        )
      ],
    );
  }
  Column buildLocationField() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Add Location" ,
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: locationController,
          decoration: InputDecoration(
            hintText: "Where are you while you are sharing this photo?",
          ),
        )
      ],
    );
  }
/*
  updatePostData() {
    setState(() {
      descriptionController.text.isEmpty
          ? _descriptionValid = false
          : _descriptionValid = true;
    });

    if (_descriptionValid) {
      postsRef.doc(widget.ownerId)
          .collection('userPosts').doc(widget.postId).update({
        "description": descriptionController.text,
      });}
    SnackBar snackbar = SnackBar(content: Text("Post updated!"));
    _scaffoldKey.currentState.showSnackBar(snackbar);
  }
*/
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Reshare Post",
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
          Center(
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
                          child: Image(
                            width: 100.0,
                            height:100.0,
                            image:CachedNetworkImageProvider(post.mediaUrl),
                          ),
                        ),
                      ),
                    ]),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      buildDescriptionField(),
                    ],
                  ),
                ),Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      buildLocationField(),
                    ],
                  ),
                ),

                RaisedButton(
                  onPressed:  isUploading ? null : () =>handleSubmit(),
                  child: Text(
                    "Reshare Post",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
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