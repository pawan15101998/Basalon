// ignore_for_file: constant_identifier_names, avoid_print, prefer_typing_uninitialized_variables

import 'package:basalon/services/connection.dart';
import 'package:dio/dio.dart';

import '..//api_provider/..//constant.dart' as constant;

enum Status {
  Success,
  Loading,
  NetworkError,
  Error,
}

class ApiProvider {
  // for all get request
  static Future get(String url, {Map<String, dynamic>? queryParam}) async {
    var dio = Dio();
    var _response;

    print("Url:");
    print(url);
    print(constant.api);
    if (!await Connection.isConnected()) {
      return {'status': 'No Connection', 'body': 'No Internet Connection'};
    }

    if (queryParam == null) {
      try {
        _response = await dio.get(
          '${constant.url}$url',
          options: Options(
            followRedirects: false,
            validateStatus: (status) {
              return status! < 500;
            },
            headers: {
              "Auth-Key": constant.auth_key,
              "Client-Service": constant.client_service,
            },
          ),
        );
      } on DioError catch (e) {
        return {'status': e.response!.statusCode, 'body': e.response!.data};
      }
    } else {
      queryParam['Auth-Key'] = constant.auth_key;
      // 'BdyRCBgXrI5PqGJc5oIWdUxd0zmjSEFQ9Ftv14rcplfWsdBU38hdjA3WaIDjBMlWtO1g6setNT4p1edBHNTRRoSg6Jl1vZJeTJSa';
      print(constant.api);
      try {
        _response =
            await dio.get('${constant.url}$url', queryParameters: queryParam);

        print("printing _response");
        print(_response);
      } on DioError catch (e) {
        return {'status': e.response!.statusCode, 'body': e.response!.data};
      }
    }

    print('api: ${constant.auth_key}');
    return {'status': _response.statusCode, 'body': _response.data};
  }

  // for all post request
  static Future post(
      {String? url, Map<String, dynamic> body = const {}}) async {
    var dio = Dio();
    FormData formData = FormData.fromMap(body);
    print('qwerty');
    print(url);
    print(body);
    if (!await Connection.isConnected()) {
      return {'status': 'No Connection', 'body': 'No Internet Connection'};
    }

    var _response = await dio.post(
      '${constant.url}$url',
      data: formData,
      options: Options(
        followRedirects: false,
        validateStatus: (status) {
          return status! < 500;
        },
        headers: {
          "Auth-Key": constant.auth_key,
          "Client-Service": constant.client_service,
        },
      ),
    );
    return {'status': _response.statusCode, 'body': _response.data};
  }
}
