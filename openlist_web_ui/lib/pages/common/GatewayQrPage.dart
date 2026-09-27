import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:openiothub_api/openiothub_api.dart';
import 'package:openiothub_grpc_api/proto/manager/publicApi.pb.dart';
import 'package:openlist_api/openlist_api.dart';
import 'package:openlist_config/config/config.dart';
import 'package:openlist_utils/toast.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../l10n/generated/openlist_web_ui_localizations.dart';

final String Gateway_Jwt_KEY = "GATEWAY_JWT_KEY";
final String QR_Code_For_Mobile_Add_KEY = "QR_Code_For_Mobile_Add";

class GatewayQrPage extends StatefulWidget {
  const GatewayQrPage({super.key});

  @override
  State<GatewayQrPage> createState() => _GatewayQrPageState();
}

class _GatewayQrPageState extends State<GatewayQrPage> {
  String qRCodeForMobileAdd = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("gateway-go"), actions: <Widget>[]),
      body: Container(
        padding: const EdgeInsets.fromLTRB(0, 50, 0, 0),
        child: ListView(
          children: [
            Center(
              child:
                  qRCodeForMobileAdd.isNotEmpty
                      ? QrImageView(
                        data: qRCodeForMobileAdd,
                        version: QrVersions.auto,
                        size: 320,
                        backgroundColor: Colors.white,
                        // backgroundColor: Colors.orangeAccent,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.deepOrangeAccent,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      )
                      : TDButton(
                        icon: Icons.start,
                        text: OpenListWebUiLocalizations.of(context).start_service,
                        size: TDButtonSize.small,
                        type: TDButtonType.outline,
                        shape: TDButtonShape.rectangle,
                        theme: TDButtonTheme.danger,
                        onTap: () {
                          _generateJwtQRCodePair(false);
                        },
                      ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 40, 0, 0),
                child: Text(OpenListWebUiLocalizations.of(context).please_scan),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: TextButton(
                  child: Text(OpenListWebUiLocalizations.of(context).change_gateway_id),
                  onPressed: () {
                    if (qRCodeForMobileAdd.isNotEmpty){
                      _generateJwtQRCodePair(true);
                    }else{
                      show_info("Please start service first", context);
                    }
                  },
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                child: TDButton(
                  icon: TDIcons.install,
                  text: OpenListWebUiLocalizations.of(context).install_openiothub,
                  size: TDButtonSize.small,
                  type: TDButtonType.outline,
                  shape: TDButtonShape.rectangle,
                  theme: TDButtonTheme.primary,
                  onTap: () {
                    print(OpenListWebUiLocalizations.of(context).localeName);
                    if (OpenListWebUiLocalizations.of(context).localeName.contains("zh")){
                      _showUrlQr("https://m.malink.cn/s/RNzqia");
                    }else{
                      _showUrlQr("https://play.google.com/store/apps/details?id=com.iotserv.openiothub");
                    }
                  },
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                child: TDButton(
                  icon: TDIcons.logo_github,
                  text: OpenListWebUiLocalizations.of(context).install_openiothub_from_github,
                  size: TDButtonSize.small,
                  type: TDButtonType.outline,
                  shape: TDButtonShape.rectangle,
                  theme: TDButtonTheme.primary,
                  onTap: () {
                    _showUrlQr("https://github.com/OpenIoTHub/OpenIoTHub/releases");
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUrlQr(String url) async {
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
            title: Text("install_openiothub"),
            scrollable: true,
            content: SizedBox(
                height: 500,
                child: ListView(
                  children: <Widget>[
                    QrImageView(
                      data: url,
                      version: QrVersions.auto,
                      size: 320,
                      backgroundColor: Colors.white,
                      // backgroundColor: Colors.orangeAccent,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.deepOrangeAccent,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    )
                  ],
                )),
            actions: <Widget>[
              TextButton(
                child: Text(
                    OpenListWebUiLocalizations.of(context).open_url,
                    style: TextStyle(color: Colors.grey)),
                onPressed: () async {
                  Navigator.of(context).pop();
                  launchUrlString(url);
                },
              ),
              TextButton(
                child: Text(
                    OpenListWebUiLocalizations.of(context).ok,
                    style: TextStyle(color: Colors.grey)),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              )
            ]));
  }

  Future<void> _generateJwtQRCodePair(bool is_change_gateway_uuid) async {
    // TODO 先检查本地存储有没有保存的网关配置，如果有则使用旧的启动
    // 检查服务是否已经启动，没有启动则启动
    await waitGatewayGoService();
    await Future.delayed(Duration(milliseconds: 400));

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(Gateway_Jwt_KEY) &&
        prefs.containsKey(QR_Code_For_Mobile_Add_KEY) &&
        !is_change_gateway_uuid) {
      var gatewayJwt = prefs.getString(Gateway_Jwt_KEY)!;
      setState(() {
        qRCodeForMobileAdd = prefs.getString(QR_Code_For_Mobile_Add_KEY)!;
      });
      await GatewayLoginManager.LoginServerByToken(
        gatewayJwt,
        "127.0.0.1",
        55443,
      );
    } else {
      JwtQRCodePair? jwtQRCodePair = await PublicApi.GenerateJwtQRCodePair();
      setState(() {
        qRCodeForMobileAdd = jwtQRCodePair.qRCodeForMobileAdd;
      });
      // TODO 保存网关(网格ID)到本地存储，当前刷新二维码的时候清楚前面的存储保存最新的网关配置
      prefs.setString(Gateway_Jwt_KEY, jwtQRCodePair.gatewayJwt);
      prefs.setString(
        QR_Code_For_Mobile_Add_KEY,
        jwtQRCodePair.qRCodeForMobileAdd,
      );
      await GatewayLoginManager.LoginServerByToken(
        jwtQRCodePair.gatewayJwt,
        "127.0.0.1",
        55443,
      );
    }
  }

  Future<void> waitGatewayGoService() async {
    final dio = Dio(BaseOptions(baseUrl: "http://localhost:34323"));
    String reqUri = "/";
    var backgrounService = BackgrounService(AListWebAPIBaseUrl);
      try {
        final response = await dio.getUri(
          Uri.parse(reqUri),
          options: Options(
            sendTimeout: Duration(milliseconds: 100),
            receiveTimeout: Duration(milliseconds: 100),
          ),
        );
        if (response.statusCode == 200) {
          return;
        } else {
          backgrounService.startGatewayGo();
          return;
        }
      } catch (e) {
        backgrounService.startGatewayGo();
        return;
      }
    }
}
