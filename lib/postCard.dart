import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs310socialmedia/model/user.dart';
import 'package:cs310socialmedia/utils/colors.dart';
import 'package:cs310socialmedia/utils/progress.dart';
import 'package:flutter/material.dart';
import 'package:cs310socialmedia/login.dart';
import 'package:cs310socialmedia/PostEdit.dart';
import 'package:cs310socialmedia/model/post.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cs310socialmedia/utils/image_loading.dart';
import 'package:cs310socialmedia/comments.dart';
import 'package:cs310socialmedia/PostReshare.dart';

import 'package:cs310socialmedia/notification.dart';

class PostCard extends StatefulWidget {

  //final Post post;
  //final Function delete;
  //PostCard({ this.post, this.delete });
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic dislikes;
  final dynamic likes;

  PostCard({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.dislikes,

  });

  factory PostCard.fromDocument(DocumentSnapshot doc) {
    return PostCard(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
      dislikes: doc['dislikes'],
    );
  }

  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostCardState createState() => _PostCardState(
    postId: this.postId,
    ownerId: this.ownerId,
    username: this.username,
    location: this.location,
    description: this.description,
    mediaUrl: this.mediaUrl,
    likes: this.likes,
    likeCount: getLikeCount(this.likes),

  );
}

class _PostCardState extends State<PostCard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked;


  _PostCardState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });
  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User2 user = User2.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: ownerId),
            child: Text(
              user.userName,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
            onPressed: () => handleDeletePost(context),
            icon: Icon(Icons.more_vert),
          ) : Text(''),
        );
      },
    );
  }
  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this post?"),
            children: <Widget>[
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    deletePost();
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  )),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
            ],
          );
        });
  }
  deletePost() async {
    // delete post itself
    postsRef
        .doc(ownerId)
        .collection('userPosts')
        .doc(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete uploaded image for the post
    storageRef.child("post_$postId.jpg").delete();
    // then delete all activity feed notifications  //"!!!!!!!!

    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(ownerId)
        .collection("feedItems")
        .where('postId', isEqualTo: postId)
        .get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // then delete all comments
    QuerySnapshot commentsSnapshot = await commentsRef
        .doc(postId)
        .collection('comments')
        .get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
      });
    }
  }


  addLikeToActivityFeed() {
    // add a notification to the postOwner's activity feed only if comment made by OTHER user (to avoid getting notification for our own like)
    bool isNotPostOwner = currentUserId != ownerId;
    //if (!isNotPostOwner) {
      activityFeedRef
          .doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .set({
        "type": "like",
        "username": currentUser.userName,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timestamp": timestamp,
      });
   // }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }
  buildPostImage() {
    return GestureDetector(
      //onDoubleTap: () => print('liking post'),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),

        ],
      ),
    );
  }

  editPost() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PostEdit(postId: postId,ownerId:ownerId,)));
  }
  resharePost() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PostReshare(postId: postId,ownerId:ownerId,)));
  }

  buildPostFooter() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("Posts").doc(widget.ownerId).collection("userPosts").doc(widget.postId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        PostCard post = PostCard.fromDocument(snapshot.data);
        bool isNotPostOwner = currentUserId != ownerId;
        return Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
                GestureDetector(
                  onTap: handleLikePost,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 28.0,
                    color: Colors.pink,
                  ),
                ),
                Padding(padding: EdgeInsets.only(right: 20.0)),
                GestureDetector(
                  onTap: () => showComments(
                    context,
                    postId: post.postId,
                    ownerId: post.ownerId,
                    mediaUrl: post.mediaUrl,
                  ),
                  child: Icon(
                    Icons.chat,
                    size: 28.0,
                    color: Colors.blue[900],
                  ),
                ),

                isNotPostOwner ?
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(' Post Reported')));
                  },
                  child:
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Icon(
                      Icons.more_vert,
                      size: 28.0,
                      color: Colors.green[900],
                    ),
                  ),
                ): Text(''),

               // Padding(padding: EdgeInsets.only(right: 20.0)),
                !isNotPostOwner ?
                GestureDetector(
                  onTap: editPost,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Icon(
                      Icons.settings,
                      size: 28.0,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                ): Text(''),

                Padding(padding: EdgeInsets.only(right: 20.0)),
                GestureDetector(
                  onTap: resharePost,
                  child: Icon(
                    Icons.share,
                    size: 28.0,
                    color: Colors.green[900],
                  ),
                ),

              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 20.0),
                  child: Text(
                    "$likeCount likes",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 20.0),
                  child: Text(
                    post.username,
                    //"$username ",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Text(post.description))
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Card(
      //margin: EdgeInsets.symmetric(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Padding(
          padding: EdgeInsets.all(12.0),
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              buildPostHeader(),
              buildPostImage(),
              buildPostFooter()
      ],
    )
      )
    );
  }

}

showComments(BuildContext context,
    {String postId, String ownerId, String mediaUrl,String username}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      userName:username,
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl,
    );
  }));
}
