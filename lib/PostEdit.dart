import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs310socialmedia/postCard.dart';
import 'package:cs310socialmedia/utils/progress.dart';
import 'package:flutter/material.dart';
import 'package:cs310socialmedia/login.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostEdit extends StatefulWidget {
  final String postId;
  final String ownerId;
  const PostEdit({this.postId,this.ownerId});

  @override
  _PostEdit createState() => _PostEdit();
}

class _PostEdit extends State<PostEdit> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  bool isLoading = false;
  PostCard post;
  bool _descriptionValid=true;

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

  Column buildDescriptionField() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Description",
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            hintText: "Update Description",
            errorText: _descriptionValid ? null : "Display Name too short",
          ),
        )
      ],
    );
  }

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
          "Edit Post",
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
                ),
                RaisedButton(
                  onPressed: updatePostData,
                  child: Text(
                    "Update Post",
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
