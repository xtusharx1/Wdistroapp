import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants.dart';
import '../models/shop_permit.dart';
import '../state/app_state.dart';
import 'api_client.dart';

class PermitService {
  static final PermitService instance = PermitService._();
  PermitService._();

  Map<String, String> get _baseHeaders => {
        ...kNgrokHeaders,
        if (AppState.instance.shop != null)
          'x-shop-id': AppState.instance.shop!.id.toString(),
      };

  Future<List<ShopPermit>> getShopPermits(int shopId) async {
    final res = await ApiClient.instance.get('/permits/shop/$shopId');
    final list = res['data']['permits'] as List<dynamic>;
    return list.map((e) => ShopPermit.fromJson(e as Map<String, dynamic>)).toList();
  }

  // permitTypeSlug: 'seller_permit' or 'tobacco_license'
  Future<ShopPermit> uploadPermit({
    required int shopId,
    required String permitTypeSlug,
    required String filePath,
    required String fileName,
  }) async {
    final uri = Uri.parse('$kBaseUrl/permits/upload?permit_type=$permitTypeSlug');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_baseHeaders);

    final ext = fileName.split('.').last.toLowerCase();
    MediaType contentType;
    if (ext == 'pdf') {
      contentType = MediaType('application', 'pdf');
    } else if (ext == 'png') {
      contentType = MediaType('image', 'png');
    } else if (ext == 'jpg' || ext == 'jpeg') {
      contentType = MediaType('image', 'jpeg');
    } else {
      contentType = MediaType('application', 'octet-stream');
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'document',
        filePath,
        filename: fileName,
        contentType: contentType,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ShopPermit.fromJson(decoded['data']['permit'] as Map<String, dynamic>);
    }
    throw ApiException(
      decoded['message'] as String? ?? 'Upload failed',
      statusCode: response.statusCode,
    );
  }
}
