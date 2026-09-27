
import 'package:openlist_config/config/global.dart';
import 'package:dio/dio.dart';

import 'package:openlist_config/config/config.dart';

Dio getDIO(){
  final dio = Dio(BaseOptions(baseUrl: AListAPIBaseUrl, headers: {
    "Authorization": token
  }));
  return dio;
}

Dio getAListWebPublicApiDIO(){
  final dio = Dio(BaseOptions(baseUrl: AListWebAPIBaseUrl));
  return dio;
}
