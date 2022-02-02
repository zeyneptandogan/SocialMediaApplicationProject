import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs310socialmedia/followers.dart';
import 'package:cs310socialmedia/utils/progress.dart';
import 'package:cs310socialmedia/zoomed.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:cs310socialmedia/postCard.dart';
import 'package:cs310socialmedia/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cs310socialmedia/model/post.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cs310socialmedia/services/Analytics.dart';
import 'package:cs310socialmedia/profileEdit.dart';
import 'package:cs310socialmedia/model/user.dart';
import 'package:cs310socialmedia/login.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';

import 'package:cs310socialmedia/notification.dart';

import 'package:cs310socialmedia/following.dart';

class ProfileView extends StatefulWidget {
  final String profileId;

  ProfileView({this.profileId});

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  bool isWaiting = false;
  bool firstlook=true;
  int postCount = 0;
  List<PostCard> posts = [];
  bool isFollowing = false;
  int followerCount = 0;
  int followingCount = 0;
  bool myprofile=true;
  TextEditingController typeController = TextEditingController();
  @override
  void initState() {
    super.initState();
    print(currentUserId);
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
    checkIfWaiting(); //burayı ekledim
    getUser();
    //setCurrentScreen(widget.analytics, widget.observer, 'Profile Page', 'ProfileState');
  }


  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => PostCard.fromDocument(doc)).toList();
    });
  }
  getUser() async {
    DocumentSnapshot doc = await usersRef.doc(widget.profileId).get();
    User2 user = User2.fromDocument(doc);
    typeController.text=user.type;
  }
  Column buildCountColumn(String label, int count,) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: (){
            if(label=="followers"){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Followers(
                    currentUserId: widget.profileId,
                  ),
                ),
              );
            }
            else if(label=="following"){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Following(
                    currentUserId: widget.profileId,
                  ),
                ),
              );
            }
          },

          child: Container(
            margin: EdgeInsets.only(top: 4.0),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15.0,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProfileEdit(currentUserId: currentUserId)));
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 250.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              //color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.blue,
            //color: Colors.blue,
            border: Border.all(
              color: isFollowing ? Colors.grey : Colors.blue,
              //color: Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }
  Container buildButton2({String text, Function function}) {
    return Container(
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 250.0,
          height: 27.0,
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
  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
    print("isfollowing ne?");
    print(isFollowing);
  }

 checkIfWaiting() async {
    DocumentSnapshot doc = await activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .get();
    Map _docdata = doc.data();
    ActivityFeedItem not =ActivityFeedItem.fromDocument2(doc,_docdata);
    print("hellooo");
    print(not.type);
    setState(() {
      if(doc.exists&&not.type=="followReq"){
        isWaiting=true;
      }
      else{
        isWaiting=false;
      }
    });
    print("isWaiting ne?");
    print(isWaiting);
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .get();
    setState(() {
      followerCount = snapshot.docs.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(widget.profileId)
        .collection('userFollowing')
        .get();
    setState(() {
      followingCount = snapshot.docs.length;
    });
  }
  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });

    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete activity feed item for them
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
        setState(() {
          isWaiting=false;
        });
      }
    });
   //print("zeyneeeep");
   //print(isWaiting);
  }

  handleFollowUser() {
    print("first look ne1?");
    print(firstlook);
    setState(() {
      isFollowing = true;
    });

    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(currentUserId)
        .set({});

    followingRef
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .set({});

    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .set({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser.userName,
      "userId": currentUserId,
      "userProfileImg": currentUser.photoUrl,
      "timestamp": timestamp,
    });
    setState(() {
      firstlook = false;
    });
    print("first look ne2?");
    print(firstlook);
  }
  handleFollowReq() {
    setState(() {
      isWaiting = true;
    });
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .set({
      "type": "followReq",
      "ownerId": widget.profileId,
      "username": currentUser.userName,
      "userId": currentUserId,
      "userProfileImg": currentUser.photoUrl,
      "timestamp": timestamp,
    });
  }
  handleUnSentReq() async{
    setState(() {
      isWaiting = false;
    });
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(widget.profileId)
        .collection("feedItems")
        .where('userId', isEqualTo: currentUserId)
        .get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }
  buildProfileButton() {
    // viewing your own profile - should show edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    }
    else if (isFollowing) {
      return buildButton(
        text: "Unfollow",
        function: handleUnfollowUser,
      );
    }
    else if(typeController.text == "private") {
      if(isWaiting){
        return buildButton(
          text: "Request Sent",
          function: handleUnSentReq,
        );
      }
      return buildButton(
        text: "Follow Request",
        function: handleFollowReq,
      );
    }

    else if (!isFollowing) {
      return buildButton(
        text: "Follow",
        function: handleFollowUser,
      );
    }
  }
  buildProfileHeader() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("Person").doc(widget.profileId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User2 user = User2.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: (){
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  Zoomed(url:user.photoUrl,)));
                    },
                    child: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                      radius: 44.0,
                    ),
                  ),

                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followerCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                            //buildPublicButton(),
                            SizedBox(width:10),


                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        SizedBox.fromSize(
                          size: Size(40, 40), // button width and height
                          child: ClipOval(
                            child: Material(
                              color: Colors.grey[400], // button color
                              child: InkWell(
                                splashColor: Colors.blue, // splash color
                                onTap: () {}, // button pressed
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    if(user.type=="public")
                                      Icon(Icons.public),
                                    if (user.type=="private")
                                      Icon(Icons.public_off),
                                    // icon
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),

              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    print(typeController.text);
    if (isLoading) {
      return circularProgress();
    }
    else if(posts.isEmpty){
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset('assets/noposts.svg', height: 260.0),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child:Text(
                "No posts",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if(isFollowing){
      return Column(
        children: posts,
      );
    }

    else{
      if(typeController.text=="public") {
        return Column(
          children: posts,
        );
      }
      else if(typeController.text=="private" && isWaiting==false) {
        bool isOwner = currentUserId == widget.profileId;
        if (!isOwner) {
          return Column(
              children: [
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      //SvgPicture.asset('assets/noposts.svg', height: 260.0),
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Text(
                          "Private Account, please send follow request to see posts!",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 40.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ]
          );
        }
        else{
          return Column(
            children: posts,
          );
        }
      }
      else if(typeController.text=="private" && firstlook==true) {
        bool isOwner = currentUserId == widget.profileId;
        if (!isOwner) {
          return Column(
              children: [
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      //SvgPicture.asset('assets/noposts.svg', height: 260.0),
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Text(
                          "Private Account, please send follow request to see posts!",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 40.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ]
          );
        }
      }
      else{
        return Column(
          children: posts,
        );
      }
    }

  }


  @override
  Widget build(BuildContext context) {
    if(currentUserId==widget.profileId){
      setState(() {
        myprofile=false;
      });
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: myprofile,
        title: Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'BrandonText',
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0.0,
        actions:[
          myprofile ?
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // handle the press
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(' User Reported')));
            },
          ) : Text(""),
        ]
      ),

      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}