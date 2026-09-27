import 'package:flutter/material.dart';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WiFiIPPage extends StatefulWidget {
  WiFiIPPage({Key? key}) : super(key: key);

  @override
  _WiFiIPPageState createState() => _WiFiIPPageState();
}

class _WiFiIPPageState extends State<WiFiIPPage> {
  String? wifiIP;

  @override
  void initState() {
    super.initState();
    _getWiFiIPs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("WiFi IP"), actions: <Widget>[]),
      body: Center(
        child:
            wifiIP == null
                ? Text("No WiFi IP Found!", style: TextStyle(color: Colors.grey))
                : Column(
                  children: [
                    QrImageView(
                      data: "http://${wifiIP!}:5244",
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
                    ),
                    Text(
                      "http://${wifiIP!}:5244",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      "Scan the above QR code on the same LAN to access this software",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      "在同一个局域网扫描上述二维码访问本软件",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _getWiFiIPs() async {
    final info = NetworkInfo();
    wifiIP = await info.getWifiIP();
    setState(() {});
  }
}
