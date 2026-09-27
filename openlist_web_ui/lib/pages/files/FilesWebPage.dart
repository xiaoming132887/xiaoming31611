import 'dart:developer';

import 'package:openlist_config/config/global.dart';
import 'package:openlist_web_ui/pages/common/appInfo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:openlist_config/config/config.dart';
import 'package:openlist_web_ui/l10n/generated/openlist_web_ui_localizations.dart';

import '../web/web.dart';

GlobalKey<FilesWebPageState> webGlobalKey = GlobalKey();

class FilesWebPage extends StatefulWidget {
  const FilesWebPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FilesWebPageState();
  }
}

class FilesWebPageState extends State<FilesWebPage> {
  @override
  Widget build(BuildContext context) {
    return WebScreen(startUrl: AListAPIBaseUrl);
  }
}
