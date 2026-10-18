import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:localsend_app/model/cross_file.dart';
import 'package:crypto/crypto.dart';

// take a file and chunk into frames of chunkSize, encode as base64 and put into
// json with metadata
class AirGapGenerator {
  static const int chunkSize = 1000;

  static Future<List<String>> encodeFile(CrossFile file) async {
    final List<int> bytes;


    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      throw UnsupportedError('Cannot read selected file');
    }

    final digest = sha256.convert(bytes); // get hash of original file

    final transferId =
    DateTime.now().microsecondsSinceEpoch.toString();

    final totalFrames = max(
      1,
      (bytes.length + chunkSize - 1) ~/ chunkSize, // ceiling div
    );

    // gernerate totalFrame of size chunk size,
    return List.generate(totalFrames, (index) {
      final start = index * chunkSize;
      final end = min(start + chunkSize, bytes.length);

      final chunk = bytes.sublist(start, end);

      return jsonEncode({
        'id': transferId,
        'name': file.name,
        'index': index,
        'total': totalFrames,
        'data': base64Encode(chunk),
        'sha256': digest.toString(),
        // 'sha256': 'invalid-hash' // test to make sure integrity check works
      });
    });
  }
}