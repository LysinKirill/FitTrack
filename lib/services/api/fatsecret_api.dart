import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class FoodItem {
  final String id;
  final String name;
  final int calories;
  final double proteins;
  final double fats;
  final double carbs;

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });
}

class FatSecretAPI {
  static const String _baseUrl = 'https://platform.fatsecret.com/rest/server.api';
  final String _consumerKey;
  final String _consumerSecret;
  static const int defaultMaxResults = 5;
  FatSecretAPI(this._consumerKey, this._consumerSecret);

  String _generateNonce() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(32, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  String _percentEncode(String s) {
    return Uri.encodeComponent(s)
        .replaceAll('+', '%20')
        .replaceAll('*', '%2A')
        .replaceAll('%7E', '~');
  }

  String _generateSignature({
    required String httpMethod,
    required String baseUrl,
    required Map<String, String> params,
    required String consumerSecret,
  }) {
    final sortedParams = params.keys.toList()..sort();

    final paramString = sortedParams
        .map((k) => '${_percentEncode(k)}=${_percentEncode(params[k]!)}')
        .join('&');

    final baseString = [
      httpMethod.toUpperCase(),
      _percentEncode(baseUrl),
      _percentEncode(paramString),
    ].join('&');


    final signingKey = '${_percentEncode(consumerSecret)}&';

    final hmac = Hmac(sha1, utf8.encode(signingKey));
    final digest = hmac.convert(utf8.encode(baseString));
    return base64Encode(digest.bytes);
  }

  Future<Map<String, dynamic>> _makeRequest({
    required String method,
    Map<String, String>? additionalParams,
  }) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final nonce = _generateNonce();

    final oauthParams = {
      'oauth_consumer_key': _consumerKey,
      'oauth_signature_method': 'HMAC-SHA1',
      'oauth_timestamp': timestamp,
      'oauth_nonce': nonce,
      'oauth_version': '1.0',
    };

    final allParams = {
      ...?additionalParams,
      ...oauthParams,
      'method': method,
      'format': 'json',
    };

    final signature = _generateSignature(
      httpMethod: 'GET',
      baseUrl: _baseUrl,
      params: allParams,
      consumerSecret: _consumerSecret,
    );


    oauthParams['oauth_signature'] = signature;

    final oauthHeader = 'OAuth ${oauthParams.entries
            .map((e) => '${_percentEncode(e.key)}="${_percentEncode(e.value)}"')
            .join(',')}';

    final queryParams = {
      ...?additionalParams,
      'method': method,
      'format': 'json',
    };
    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': oauthHeader},
    );

    if (response.statusCode != 200) {
      throw Exception('Request failed: ${response.statusCode} - ${response.body}');
    }

    final result = json.decode(response.body);
    if (result.containsKey('error')) {
      throw Exception('API error: ${result['error']['message']}');
    }

    return result;
  }

  Future<Map<String, dynamic>> searchFoods(String query, {String language = 'en'}) async {
    return await _makeRequest(
      method: 'foods.search',
      additionalParams: {
        'search_expression': query,
        'language': language,
        'max_results': defaultMaxResults.toString()
      },
    );
  }

  Future<Map<String, dynamic>> getFood(int foodId, {String language = 'en'}) async {
    return await _makeRequest(
      method: 'food.get',
      additionalParams: {
        'food_id': foodId.toString(),
        'language': language,
      },
    );
  }
}