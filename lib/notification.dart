import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cs310socialmedia/login.dart';
import 'package:cs310socialmedia/post_screen.dart';
import 'package:cs310socialmedia/profile.dart';

import 'package:cs310socialmedia/utils/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class activityFeed extends StatefulWidget {
  @override
  _activityFeedState createState() => _activityFeedState();
}

class _activityFeedState extends State<activityFeed> {

  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
        .doc(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .get();

    List<ActivityFeedItem> feedItems = [];
    snapshot.docs.forEach((doc) {
      Map _docdata = doc.data();
      feedItems.add(ActivityFeedItem.fromDocument2(doc,_docdata));
      // print('Activity Feed Item: ${doc.data}');
    });
    return feedItems;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Activity Feed",
          style: TextStyle(
            fontFamily: 'BrandonText',
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0.0,
      ),
      body: Container(
          child: FutureBuilder(
            future: getActivityFeed(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return circularProgress();
              }
              return ListView(
                children: snapshot.data,
              );
            },
          )),
    );
  }
}


Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String ownerId;
  final String type; // 'like', 'follow', 'comment','followReq'
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  acceptRequest(String otherId,String curId,String img) async{
    print(curId);
    print(otherId);
    followersRef
        .doc(curId)
        .collection('userFollowers')
        .doc(otherId)
        .set({});

    followingRef
        .doc(otherId)
        .collection('userFollowing')
        .doc(curId)
        .set({});

    activityFeedRef
        .doc(curId)
        .collection('feedItems')
        .doc(otherId)
        .update({
      "type": "follow",
      "ownerId": otherId,
      "username": username,
      "userId": curId,
      "userProfileImg": img,
      "timestamp": timestamp,
    });
  }
  rejectRequest(String otherId,String curId) async{
    print(curId);
    print(otherId);

    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(curId)
        .collection("feedItems")
        .where('userId', isEqualTo: otherId)
        .where('type',isEqualTo: "followReq")
        .get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

  }

  Future<void> showAlertDialog(String user,context,String curId,String otherId, String img) async {
    return showDialog<void>  (
        context: context,
        barrierDismissible: false, //User must tap button
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(user+" requested to follow you"),
            children: <Widget>[
              SimpleDialogOption(
                  child: Text("Accept"), onPressed: (){
                print("deneme");
                acceptRequest(curId,otherId,img);
                print("deneme2");
                Navigator.of(context).pop();
              }),
              SimpleDialogOption(
                  child: Text("Reject"),
                  onPressed: (){
                    rejectRequest(curId,otherId);
                    Navigator.of(context).pop();

                  }),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
    );
  }
  ActivityFeedItem({
    this.username,
    this.userId,
    this.type,
    this.mediaUrl,
    this.postId,
    this.userProfileImg,
    this.commentData,
    this.timestamp,
    this.ownerId,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
      mediaUrl: doc['mediaUrl'],
      ownerId: doc['ownerId'],
    );
  }
  factory ActivityFeedItem.fromDocument2(DocumentSnapshot doc,Map _docdata) {
    return ActivityFeedItem(
      username: _docdata['username'],
      userId: _docdata['userId'],
      type: _docdata['type'],
      postId: _docdata['postId'],
      userProfileImg: _docdata['userProfileImg'],
      commentData: _docdata['commentData'],
      timestamp: _docdata['timestamp'],
      mediaUrl: _docdata['mediaUrl'],
      ownerId: _docdata['ownerId'],
    );
  }
  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userId: userId,
        ),
      ),
    );
  }

  configureMediaPreview(context) {
    if (type == "like" || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: CachedNetworkImageProvider(mediaUrl),
                  ),
                ),
              )),
        ),
      );
    } else if(type=='followReq') {
      mediaPreview = GestureDetector(
        onTap: () => {showAlertDialog(username,context,userId,ownerId,userProfileImg)},
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              child: Icon(Icons.add_moderator),
            ),
          ),
        ),
      );
    }
    else {
      mediaPreview = Text('');
    }

    if (type == 'like') {
      activityItemText = "liked your post";
    } else if (type == 'follow') {
      activityItemText = "is following you";
    } else if (type == 'comment') {
      activityItemText = 'replied: $commentData';
    } else if(type=='followReq'){
      activityItemText = "is requested to follow you";
    }
    else {
      activityItemText = "Error: Unknown type '$type'";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: username,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' $activityItemText',
                    ),
                  ]),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

showProfile(BuildContext context, {String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProfileView(
        profileId: profileId,
      ),
    ),
  );
}