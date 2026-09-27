import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:openlist_config/config/config.dart';
import 'package:openlist_web_ui/l10n/generated/openlist_web_ui_localizations.dart';
import 'package:openlist_utils/toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoPage extends StatefulWidget {
  AppInfoPage({required Key key}) : super(key: key);

  @override
  _AppInfoPageState createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  //APP名称
  String appName = "";

  //包名
  String packageName = "";

  //版本名
  String version = "";
  String aListVersion = "";

  //版本号
  String buildNumber = "";

  //App数据位置
  String appDataDir = "";

  @override
  void initState() {
    super.initState();
    _getAppInfo();
    _getAppDataDir();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List _result = [];
    _result.add("${OpenListWebUiLocalizations.of(context).app_name}$appName");
    _result.add(
      "${OpenListWebUiLocalizations.of(context).package_name}$packageName",
    );
    _result.add("${OpenListWebUiLocalizations.of(context).version}$version");
    _result.add(
      "OpenList ${OpenListWebUiLocalizations.of(context).version}$aListVersion",
    );
    _result.add(
      "${OpenListWebUiLocalizations.of(context).version_sn}$buildNumber",
    );
    // _result.add("APP Data Dir：$appDataDir");
    // _result.add("${OpenListWebUiLocalizations.of(context).icp_number}皖ICP备");

    final tiles = _result.map((pair) {
      if ((pair as String).contains("APP Data Dir")) {
        return ListTile(
          title: Text(pair),
          onTap: () {
            launchUrl(Uri.directory(pair));
          },
        );
      }
      return ListTile(title: Text(pair));
    });
    List<ListTile> tilesList = tiles.toList();
    tilesList.add(
      ListTile(
        title: Text("APP Data Dir：$appDataDir"),
        onTap: () async {
          ClipboardData data = new ClipboardData(text:appDataDir);
          Clipboard.setData(data);
          show_info("Path copied to clipboard", context);
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            launchUrl(Uri.directory(appDataDir));
          }
        },
      ),
    );
    final divided =
        ListTile.divideTiles(context: context, tiles: tilesList).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(OpenListWebUiLocalizations.of(context).app_info),
        actions: <Widget>[],
      ),
      body: ListView(children: divided),
    );
  }

  _getAppDataDir() async {
    // TODO 目前使用这个,以后用户设置
    Directory appDir = await getApplicationDocumentsDirectory();
    setState(() {
      appDataDir = appDir.path.toString();
    });
  }

  _getAppInfo() async {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        appName = packageInfo.appName;
        packageName = packageInfo.packageName;
        version = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    });

    final dio = Dio(BaseOptions(baseUrl: AListAPIBaseUrl));
    String reqUri = "/api/public/settings";
    // String reqUri = "/api/auth/login/hash";
    try {
      final response = await dio.getUri(Uri.parse(reqUri));
      if (response.statusCode == 200 && response.data["code"] == 200) {
        //  登录成功
        Map<String, dynamic> data = response.data;
        print(data["data"]["token"]);
        setState(() {
          aListVersion = data["data"]["version"];
        });
        return;
      } else {
        //  登录失败
        show_failed("Login failed", context);
      }
    } catch (e) {
      //  登录失败
      show_failed("Login failed:${e.toString()}", context);
      print(e.toString());
      return;
    }
  }
}
