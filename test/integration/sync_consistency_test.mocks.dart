// 手动创建的Mock类,用于测试
// 这个文件应该由build_runner自动生成,但由于其他测试文件有语法错误,我们手动创建

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

/// MockClient类 - 模拟HTTP客户端
class MockClient extends Mock implements http.Client {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return super.noSuchMethod(
      Invocation.method(#get, [url], {#headers: headers}),
      returnValue: Future.value(http.Response('', 404)),
      returnValueForMissingStub: Future.value(http.Response('', 404)),
    );
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #post,
        [url],
        {#headers: headers, #body: body, #encoding: encoding},
      ),
      returnValue: Future.value(http.Response('', 404)),
      returnValueForMissingStub: Future.value(http.Response('', 404)),
    );
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #put,
        [url],
        {#headers: headers, #body: body, #encoding: encoding},
      ),
      returnValue: Future.value(http.Response('', 404)),
      returnValueForMissingStub: Future.value(http.Response('', 404)),
    );
  }

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #delete,
        [url],
        {#headers: headers, #body: body, #encoding: encoding},
      ),
      returnValue: Future.value(http.Response('', 404)),
      returnValueForMissingStub: Future.value(http.Response('', 404)),
    );
  }

  @override
  void close() {
    super.noSuchMethod(
      Invocation.method(#close, []),
      returnValueForMissingStub: null,
    );
  }
}

