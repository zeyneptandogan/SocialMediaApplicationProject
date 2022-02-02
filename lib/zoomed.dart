import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
class Zoomed extends StatelessWidget {
  final String url;
  const Zoomed({Key key,this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      child: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(this.url),
        radius: 100.0,
      ),
    );
  }
}
