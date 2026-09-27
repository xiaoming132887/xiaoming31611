//这个模型是用来局域网或者远程操作casaOS的
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:openlist_config/config/config.dart';
import 'package:openlist_config/config/global.dart';
import 'package:openlist_web_ui/l10n/generated/openlist_web_ui_localizations.dart';
import '../l10n/generated/openlist_global_localizations.dart';
import 'package:openlist_utils/toast.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:openlist_utils/init.dart' as init;

import 'package:openlist_web_ui/pages/homePage.dart' as openlist_web_ui;
import 'package:openlist_native_ui/pages/homePage.dart' as openlist_native_ui;

// 登录
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key})
      : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List<Widget> _list = <Widget>[TDLoading(
    size: TDLoadingSize.small,
    icon: TDLoadingIcon.activity,
  ), Text("如果本界面长时间处于加载中请手动重启App,并检查有没有类似软件占用了端口",style: TextStyle(color: Colors.black38),)];

  final TextEditingController _username = TextEditingController(text: "admin");
  final TextEditingController _user_password = TextEditingController(text: "admin");

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (init.inited) {
        timer.cancel();
        _initList();
      }
    });
    // Future.delayed(Duration(milliseconds: 200), (){_initList();});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("OpenList Login"),
        ),
        body: Center(
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: _list,
            ),
          ),
        ));
  }

  Future<void> _initList() async {
    setState(() {
      _list = <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 20.0), // 设置顶部距离
          child: Image.asset(
            'assets/icon/icon.png',
            package: "openlist_web_ui",
            // 确保路径正确且已在pubspec.yaml中声明
            width: 130,
            height: 130,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20.0), // 设置顶部距离
          child: TDInput(
            controller: _username,
            backgroundColor: Colors.white,
            leftLabel: OpenListGlobalLocalizations.of(context).username,
            // hintText: OpenPluginLocalizations.of(context)
            //     .please_input_user_name,
            onChanged: (String v) {},
          ),
        ),
        TDInput(
          controller: _user_password,
          backgroundColor: Colors.white,
          leftLabel: OpenListGlobalLocalizations.of(context).password,
          // hintText:
          //     OpenPluginLocalizations.of(context).please_input_password,
          obscureText: true,
          onChanged: (String v) {},
        ),
      Padding(
      padding: const EdgeInsets.only(top: 20.0), // 设置顶部距离
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20.0), // 设置顶部距离
          child: TDButton(
              icon: TDIcons.user,
              text: OpenListGlobalLocalizations.of(context).skip_login,
              size: TDButtonSize.medium,
              type: TDButtonType.outline,
              shape: TDButtonShape.rectangle,
              theme: TDButtonTheme.defaultTheme,
              onTap: () async {
                _skip_login_goto_dashboard();
              }),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 20.0), // 设置顶部距离
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TDButton(
                  icon: TDIcons.login,
                  text: OpenListGlobalLocalizations.of(context).login,
                  size: TDButtonSize.medium,
                  type: TDButtonType.outline,
                  shape: TDButtonShape.rectangle,
                  theme: TDButtonTheme.primary,
                  onTap: () async {
                    if (_username.text.isEmpty || _user_password.text.isEmpty) {
                      show_failed("username_and_password_cant_be_empty", context);
                      return;
                    }
                    // 登录并跳转
                    login_and_goto_dashboard(
                        _username.text, _user_password.text);
                  })
            ],
          ),
        ),
      ]))];
    });
  }

  Future<void> login_and_goto_dashboard(String username, password) async {
    final dio = Dio(BaseOptions(
        baseUrl: AListAPIBaseUrl));
    String reqUri = "/api/auth/login";
    // String reqUri = "/api/auth/login/hash";
    try {
      final response = await dio.postUri(Uri.parse(reqUri),
          data: {'username': username, 'password': password});
      if (response.statusCode == 200 && response.data["code"] == 200) {
        //  登录成功
        Map<String, dynamic> data = response.data;
        print(data["data"]["token"]);
        // 保存token
        token = data["data"]["token"];
        _skip_login_goto_dashboard();
      } else {
        //  登录失败
        show_failed("Login failed", context);
      }
    } catch (e) {
      //  登录失败
      show_failed("Login failed:${e.toString()}", context);
      print(e.toString());
      // var backgrounService = BackgrounService(AListWebAPIBaseUrl);
      // backgrounService.waitHttpPong().then((ret) async {
      //   if (ret == "restarted") {
      //     await init();
      //   }
      //   setState(() {});
      // });
      return;
    }
  }

  Future<void> _skip_login_goto_dashboard() async {
        Navigator.of(context).pop();
        // 跳转到主页
        Navigator.push(context, MaterialPageRoute(builder: (ctx) {
          // return openlist_native_ui.HomePage();
          if (Platform.isLinux) {
            //  由于插件不支持Linux webview所以使用原生界面或者直接使用系统网页打开
            return openlist_native_ui.HomePage();
          } else {
            return openlist_web_ui.HomePage();
          }
        }));
        return;
  }
}
