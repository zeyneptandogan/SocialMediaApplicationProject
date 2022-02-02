import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User2 {

   String id;
   String userName;
   String photoUrl;
   String email;
   String bio;
   String password;
   String type;
   String displayName;
   DateTime deactivateUntil;
  User2({this.id, this.userName, this.password,this.photoUrl, this.email, this.bio,this.type,this.displayName,this.deactivateUntil});
  //
  factory User2.fromDocument(DocumentSnapshot doc) {
      return User2(
         id: doc['id'],
         email: doc['email'],
         password:doc['password'],
         type:doc['type'],
         userName: doc['userName'],
         photoUrl: doc['photoUrl'],
         bio: doc['bio'],
         displayName: doc['displayName'],
         deactivateUntil: doc['deactivateUntil'].toDate(),

      );
   }
   factory User2.fromDocument2(DocumentSnapshot doc,Map docdata
       ) {
     return User2(
         id: docdata['id'],
         email: docdata['email'],
         userName: docdata['userName'],
         photoUrl: docdata['photoUrl'],
         bio: docdata['bio'],
         type:docdata['type'],
         password:docdata['password'],
       displayName: docdata['displayName'],
       deactivateUntil: docdata['deactivateUntil'].toDate(),

     );

   }
}
