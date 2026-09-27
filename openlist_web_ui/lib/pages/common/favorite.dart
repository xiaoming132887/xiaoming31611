import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:openlist_config/config/config.dart';
import 'package:openlist_config/keys/keys.dart';
import 'package:openlist_web_ui/l10n/generated/openlist_web_ui_localizations.dart';
import 'package:openlist_web_ui/pages/web/web.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../web/fullScreenWeb.dart';

class FavoritePage extends StatefulWidget {
  FavoritePage({ Key? key}) : super(key: key);

  @override
  _FavoritePageState createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Map<String,dynamic>> favorites = [];
  @override
  void initState() {
    super.initState();
    _getFavorites();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = favorites.map(
      (pair) {
        return ListTile(
          title: Text(
            pair["title"].split("|").first,
          ),
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (ctx) {
              return WebScreen(key: UniqueKey(),startUrl: pair["url"],);
            }));
          },
        );
      },
    );
    List<ListTile> tilesList = tiles.toList();
    final divided = ListTile.divideTiles(
      context: context,
      tiles: tilesList,
    ).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Favorites"), actions: <Widget>[
      ]),
      body: ListView(children: divided),
    );
  }

  _getFavorites() async {
    List<Map<String, dynamic>> _favorites = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(FAVORITE_KEY)) {
      return;
    }else{
      List<String> favoritesStr = prefs.getStringList(FAVORITE_KEY)!;
      for (var favoriteStr in favoritesStr) {
        _favorites.add(jsonDecode(favoriteStr));
      }
      setState(() {
        favorites = _favorites;
      });
    }
  }
}
