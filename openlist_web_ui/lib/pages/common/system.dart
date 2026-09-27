import 'dart:io';

import 'package:flutter/material.dart';

import 'package:openlist_config/config/config.dart';
import 'package:openlist_utils/service/internal_plugin_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final FORGE_ROUND_TASK_ENABLE = "foreg_round_task";
final WAKE_LOCK = "WAKE_LOCK";

class SystemPage extends StatefulWidget {
  SystemPage({ Key? key}) : super(key: key);

  @override
  _SystemPageState createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  bool foreground = false;
  bool wakeLock = false;

  @override
  void initState() {
    super.initState();
    _getForgeServiceStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List _result = [];
    // AList固定信息
    _result.add("AListWebAPIBaseUrl: $AListWebAPIBaseUrl");
    _result.add("AListAPIBaseUrl: $AListAPIBaseUrl");
    _result.add("WebPageBaseUrl: $WebPageBaseUrl");
    _result.add("DDNS-GO Url: http://localhost:9876");
    _result.add("GATEWAY-GO Url: http://localhost:34323");

    final tiles = _result.map(
      (pair) {
        return ListTile(
          title: Text(
            pair,
          ),
        );
      },
    );
    List<ListTile> tilesList = tiles.toList();

    if (Platform.isAndroid) {
      tilesList.add(ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text("Keep Android bacground service alive"),
          ],
        ),
        trailing: Switch(
          onChanged: (bool newValue) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool(FORGE_ROUND_TASK_ENABLE, newValue);
            setState(() {
              foreground = newValue;
            });
            if (newValue) {
              // _requestPlatformPermissions();
              try{
                InternalPluginService.instance.init();
                InternalPluginService.instance.start();
              } catch (e) {
                print(e);
              }
            }else{
              try{
                InternalPluginService.instance.stop();
              } catch (e) {
                print(e);
              }
            }
          },
          value: foreground,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.red,
        ),
      ));
    }

    tilesList.add(ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text("Wake Lock(唤醒锁、防休眠)"),
        ],
      ),
      trailing: Switch(
        onChanged: (bool newValue) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool(WAKE_LOCK, newValue);
          setState(() {
            wakeLock = newValue;
          });
          WakelockPlus.toggle(enable: newValue);
        },
        value: wakeLock,
        activeColor: Colors.green,
        inactiveThumbColor: Colors.red,
      ),
    ));

    final divided = ListTile.divideTiles(
      context: context,
      tiles: tilesList,
    ).toList();

    return Scaffold(
      appBar: AppBar(title: Text("System"), actions: <Widget>[
      ]),
      body: ListView(children: divided),
    );
  }

  Future _getForgeServiceStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? FORGE_ROUND = await prefs.getBool(FORGE_ROUND_TASK_ENABLE);
    if (FORGE_ROUND != null && FORGE_ROUND) {
      setState(() {
        foreground = true;
      });
    }
    bool? WAKE_LOCK_ENABLED = await prefs.getBool(WAKE_LOCK);
    if (WAKE_LOCK_ENABLED != null && WAKE_LOCK_ENABLED) {
      setState(() {
        wakeLock = true;
      });
    }
  }
}
