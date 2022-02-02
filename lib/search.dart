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

class search extends StatefulWidget {
  final User2 currentUser;
  const search({this.currentUser,Key key, this.analytics, this.observer}) : super(key: key);
  // const search({Key key, this.analytics, this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  @override
  _searchState createState() => _searchState();
}
List<User2> searchResultsu= [];
List<User2> _allusers= [];
class _searchState extends State<search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  Future<Null> handleSearch() async{

    usersRef.get().then((snapshot) {
      snapshot.docs.forEach((doc) {
        Map _docd= doc.data();
        User2 user= User2.fromDocument2(doc, _docd);
        print("settttttttttttt1");
        print(user.userName);
        //User2 user = User2.fromDocument(doc);
        //UserResult searchResult = UserResult(user);
        setState(() {
          _allusers.add(user);
          print("settttttttttttt");
          print(user.userName);
        });

      });
    },
    );

  }

  clearSearch() {
    searchController.clear();
    setState(() {
      _allusers.clear();
    });
    onSearchTextChanged("asd<saf");

  }
  @override
  void initState() {
    super.initState();
    _allusers.clear();
    handleSearch();
    setCurrentScreen(widget.analytics, widget.observer, 'Search Page', 'SearchState');
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
        title: Padding(padding: EdgeInsets.fromLTRB(75.0, 0.0, 80.0, 0.0),child: new Text('Find People')),
        elevation: 0.0,
        backgroundColor: AppColors.primary,
      ),
      body:
      new Column(
        children: <Widget>[
          new Card(
            child: new ListTile(
              leading: new Icon(Icons.search),
              title: new TextField(
                controller: searchController,
                decoration: new InputDecoration(
                  hintText: 'Search', border: InputBorder.none,),
                onChanged: onSearchTextChanged,
              ),
              trailing: new IconButton(icon: new Icon(Icons.cancel), onPressed: () {
                /*controller.clear();
                onSearchTextChanged('');*/
                clearSearch();
              },),
            ),
          ),
          new Expanded(
            child: searchResultsu == null
                ? buildNoContent()
                : new ListView.builder(
              itemCount: searchResultsu.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => showProfile(context, profileId: searchResultsu[index].id),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey,
                      backgroundImage: CachedNetworkImageProvider(searchResultsu[index].photoUrl),
                    ),
                    title: Text(
                      searchResultsu[index].displayName,
                      style:
                      TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      searchResultsu[index].userName,
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
    searchResultsu.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    _allusers.forEach((userDetail) {
      if (userDetail.userName.contains(text)||userDetail.userName.toLowerCase().contains(text))
        searchResultsu.add(userDetail);
    });

    setState(() {});
  }

}


List<PostCard> _searchResult=[];
List<PostCard> allposts=[];
class searchpost extends StatefulWidget {
  @override
  _searchpostState createState() => _searchpostState();
}
class _searchpostState extends State<searchpost> {

  TextEditingController controller = new TextEditingController();
  bool isLoading = false;


  Future<Null> getPosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('searchPosts')
        .orderBy('timestamp', descending: true)
        .get();
    snapshot.docs.forEach((doc) {
      // Map docd= doc.data();
      setState(() {
        PostCard post = PostCard.fromDocument(doc);
        print(post.description);


        /* if (!snapshot.hasData()) {
          return circularProgress();
        }*/

        isLoading = false;
        allposts.add(post);
        print(post.description);
        print(post.username);
        //posts = snapshot.docs.map((doc) => PostCard.fromDocument(doc)).toList();
      });
    });

  }


  @override
  void initState() {
    super.initState();
    allposts.clear();
    getPosts();

  }
  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
          child: new ListView(
            shrinkWrap: true,
            children: [
              Center(child: Icon(Icons.image, color: Colors.grey[200], size: 120.0)),
            ],
          )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: new AppBar(
        title: Padding(padding: EdgeInsets.fromLTRB(75.0, 0.0, 80.0, 0.0),child: new Text('Search Posts')),
        elevation: 0.0,
        backgroundColor: AppColors.primary,
      ),
      body: new Column(
        children: <Widget>[
          new Card(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Search ",border: InputBorder.none,
                //filled: true,
                prefixIcon: Icon(
                  Icons.search,
                  size: 28.0,
                ),
                suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {controller.clear();
                    onSearchTextChanged("wefsafdgbs");
                    }
                ),
              ),
              onFieldSubmitted: onSearchTextChanged,
            ),

          ),


          new Expanded(
            child: _searchResult.length != 0 || controller.text.isNotEmpty
                ? new ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _searchResult.length,
              itemBuilder: (context, i) {
                return GestureDetector(
                  child: ListTile(
                    title: _searchResult[i], ),
                  onTap: () => showProfile(context, profileId: searchResultsu[i].id),
                );
              },
            )
                : buildNoContent(),

          ),

        ],
      ),
    );
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    allposts.forEach((userDetail) {
      if (userDetail.description.contains(text)) {
        _searchResult.add(userDetail);
        print(userDetail.username);
      }

    });

    setState(() {});
  }
}