import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'utils/progress.dart';
import 'package:timeago/timeago.dart' as timeago;


class Comments extends StatefulWidget {
  final String userName;
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({
    this.userName,
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  @override
  CommentsState createState() => CommentsState(
    userName: this.userName,
    postId: this.postId,
    postOwnerId: this.postOwnerId,
    postMediaUrl: this.postMediaUrl,
  );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String userName;
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  CommentsState({
    this.userName,
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  buildComments() {
    return StreamBuilder(
        stream: commentsRef
            .doc(postId)
            .collection('comments')
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<Comment> comments = [];
          snapshot.data.docs.forEach((doc) {
            comments.add(Comment.fromDocument(doc));
          });
          return ListView(
            children: comments,
          );
        });
  }

  addComment() {
    commentsRef.doc(postId).collection("comments").add({
      "userName": currentUser.userName,
      "comment": commentController.text,
      "timestamp": timestamp,
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id,
    });
    bool isNotPostOwner = postOwnerId != currentUser.id;
    //if (!isNotPostOwner) {  //Degistir!!
    activityFeedRef.doc(postOwnerId)
        .collection('feedItems').add({
      "type": "comment",
      "commentData": commentController.text,
      "username": currentUser.userName,
      "userId": currentUser.id,
      "userProfileImg": currentUser.photoUrl,
      "postId": postId,
      "mediaUrl": postMediaUrl,
      "timestamp": timestamp,
    });
  //}
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "Comments",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: "Write a comment..."),
            ),
            trailing: OutlineButton(
              onPressed: addComment,
              borderSide: BorderSide.none,
              child: Text("Post"),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String userName;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    this.userName,
    this.userId,
    this.avatarUrl,
    this.comment,
    this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      userName: doc['userName'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(userName + ":   " +comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(),
      ],
    );
  }
}
