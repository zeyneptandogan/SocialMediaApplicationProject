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

class Followers extends StatefulWidget {
  final String currentUserId;
  const Followers({this.currentUserId,Key key, this.analytics, this.observer}) : super(key: key);
  // const search({Key key, this.analytics, this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  @override
  _FollowersState createState() => _FollowersState();
}
List<User2> searchResultsu2= [];
List<String> ids2=[];
class _FollowersState extends State<Followers> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;
  final String currentUserId = currentUser?.id;

  @override
  void initState() {
    super.initState();
    searchResultsu2.clear();
    getFollowers();
    setCurrentScreen(widget.analytics, widget.observer, 'Followers Page', 'FollowersState');
  }

  makeFollowers(String id) async{
    DocumentSnapshot doc = await usersRef.doc(id).get();
    //doc.id;
    Map _docdata = doc.data();
    User2 us = User2.fromDocument2(doc,_docdata);
    print("mert");
    print(us.displayName);
    setState(() {
      searchResultsu2.add(us);
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .doc(widget.currentUserId)
        .collection('userFollowers')
        .get();
    snapshot.docs.forEach((doc) {
      ids2.add(doc.id);
      makeFollowers(doc.id);
    });


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
        title: Padding(padding: EdgeInsets.fromLTRB(75.0, 0.0, 80.0, 0.0),child: new Text('Followers')),
        elevation: 0.0,
        backgroundColor: AppColors.primary,
      ),
      body:
      new Column(
        children: <Widget>[
          //onSearchTextChanged
          new Expanded(
            child: searchResultsu2 == null
                ? buildNoContent()
                : new ListView.builder(
              itemCount: searchResultsu2.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => showProfile(context, profileId: searchResultsu2[index].id),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey,
                      backgroundImage: CachedNetworkImageProvider(searchResultsu2[index].photoUrl),
                    ),
                    title: Text(
                      searchResultsu2[index].displayName,
                      style:
                      TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      searchResultsu2[index].userName,
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
  onSearchTextChanged(String text) async {
    searchResultsu2.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }


    setState(() {});
  }

}