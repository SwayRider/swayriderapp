import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mocktail/mocktail.dart';

/// Fake [HttpHeaders] that records added headers and the content type,
/// and allows reading them back for assertions.
class FakeHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, List<String>> _headers = {};
  ContentType? _contentType;

  @override
  ContentType? get contentType => _contentType;

  @override
  set contentType(ContentType? value) => _contentType = value;

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  String? value(String name) {
    final values = _headers[name.toLowerCase()];
    if (values == null || values.isEmpty) return null;
    return values.join(',');
  }
}

/// Fake [HttpClientResponse] backed by an in-memory UTF-8 body.
class FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  FakeHttpClientResponse(this.statusCode, [String body = ''])
      : _stream = Stream.fromIterable([utf8.encode(body)]);

  @override
  final int statusCode;

  final Stream<List<int>> _stream;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  HttpHeaders get headers => FakeHttpHeaders();

  @override
  List<Cookie> get cookies => [];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  int get contentLength => -1;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => '';

  @override
  List<RedirectInfo> get redirects => [];

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => throw UnimplementedError();

  @override
  Future<Socket> detachSocket() => throw UnimplementedError();
}

/// Fake [HttpClientRequest] that records the written body and exposes the
/// configured [FakeHttpClientResponse] from [close].
class FakeHttpClientRequest extends Fake implements HttpClientRequest {
  FakeHttpClientRequest({
    required this.method,
    required this.uri,
    required this.response,
  });

  @override
  final String method;

  @override
  final Uri uri;

  final FakeHttpClientResponse response;
  final FakeHttpHeaders _headers = FakeHttpHeaders();
  final StringBuffer _body = StringBuffer();

  @override
  HttpHeaders get headers => _headers;

  /// The raw text written via [write].
  String get bodyText => _body.toString();

  /// The body decoded as JSON.
  dynamic get bodyJson => jsonDecode(bodyText);

  @override
  void write(Object? object) {
    _body.write(object);
  }

  @override
  Future<HttpClientResponse> close() async => response;
}

/// Fake [HttpClient] that returns a single configured [FakeHttpClientResponse]
/// for every request, and records the last [FakeHttpClientRequest] issued.
class FakeHttpClient extends Fake implements HttpClient {
  FakeHttpClient(this._response);

  final FakeHttpClientResponse _response;

  FakeHttpClientRequest? lastRequest;
  bool closed = false;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    final request = FakeHttpClientRequest(
      method: 'POST',
      uri: url,
      response: _response,
    );
    lastRequest = request;
    return request;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final request = FakeHttpClientRequest(
      method: 'GET',
      uri: url,
      response: _response,
    );
    lastRequest = request;
    return request;
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }
}

/// Fake [HttpClient] that throws [exception] as soon as a request is opened,
/// used to exercise the `on Exception catch (e)` paths in [AuthApiClient].
class FakeThrowingHttpClient extends Fake implements HttpClient {
  FakeThrowingHttpClient(this.exception);

  final Exception exception;
  bool closed = false;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async => throw exception;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => throw exception;

  @override
  void close({bool force = false}) {
    closed = true;
  }
}
