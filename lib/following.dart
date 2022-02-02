import 'package:cs310socialmedia/TopicCard.dart';
import 'package:cs310socialmedia/login.dart';
import 'package:cs310socialmedia/model/location.dart';
import 'package:cs310socialmedia/model/post.dart';
import 'package:cs310socialmedia/model/topic.dart';
import 'package:cs310socialmedia/model/user.dart';
import 'package:cs310socialmedia/postCard.dart';
import 'package:cs310socialmedia/locationCard.dart';
import 'package:cs310socialmedia/usercard.dart';
import 'package:cs310socialmedia/utils/colors.dart';
import 'package:cs310socialmedia/utils/progress.dart';
import 'package:cs310socialmedia/utils/styles.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'dart:async';
import 'dart:convert';
//import 'package:http/http.dart' as http;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cs310socialmedia/services/Analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';

import 'package:cs310socialmedia/notification.dart';

class Following extends StatefulWidget {
  final String currentUserId;
  const Following({this.currentUserId,Key key, this.analytics, this.observer}) : super(key: key);
  // const search({Key key, this.analytics, this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  @override
  _FollowingState createState() => _FollowingState();
}
List<User2> searchResultsu3= [];
List<String> ids3=[];
class _FollowingState extends State<Following> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;
  final String currentUserId = currentUser?.id;

  @override
  void initState() {
    super.initState();
    searchResultsu3.clear();
    getFollowers();
    setCurrentScreen(widget.analytics, widget.observer, 'Followers Page', 'FollowersState');
  }

  makeFollowers(String id) async{
    DocumentSnapshot doc = await usersRef.doc(id).get();
    //doc.id;
    Map _docdata = doc.data();
    User2 us = User2.fromDocument2(doc,_docdata);

    print(us.displayName);
    setState(() {
      searchResultsu3.add(us);
    });
    //searchResultsu3.add(us);
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followingRef
        .doc(widget.currentUserId)
        .collection('userFollowing')
        .get();
    snapshot.docs.forEach((doc) {
      ids3.add(doc.id);
      makeFollowers(doc.id);
    });
    setState(() {});
  }

  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
          child: new ListView(
            shrinkWrap: true,
            children: [
              Center(child: Icon(Icons.group, color: Colors.grey[200], size: 120.0)),
            ],
          )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: new AppBar(
        title: Padding(padding: EdgeInsets.fromLTRB(75.0, 0.0, 80.0, 0.0),child: new Text('Following')),
        elevation: 0.0,
        backgroundColor: AppColors.primary,
      ),
      body:
      new Column(
        children: <Widget>[
          //onSearchTextChanged
          new Expanded(
            child: new ListView.builder(
              itemCount: searchResultsu3.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => showProfile(context, profileId: searchResultsu3[index].id),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey,
                      backgroundImage: CachedNetworkImageProvider(searchResultsu3[index].photoUrl),
                    ),
                    title: Text(
                      searchResultsu3[index].displayName,
                      style:
                      TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      searchResultsu3[index].userName,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );

              },

              // searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
            ),
          ),
        ],
      ),

    );
  }

}