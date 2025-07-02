import 'dart:convert';
import 'package:archive/archive.dart';

dynamic decompressCarData() {
  try {
    // Base64 encoded string
    String base64Data =
        '7ZQxa8MwEIX/y8120J100sl75haaoU3pEEoGU5KUxJ2C/3ttYiVWIVcKHQXCIPDH0z09vTM8Hk5t1x720LyeYdXutqdus/uEBsgQ18bXJCvkZlgcFj5yFOE1VLDcd8d2e4LmDDh+nrpN9zVs4WG/Om7eP4ZfnqFBF2IFL9DU0ZkK1tAEi9RX4BSGjLkwaNBNkAkDxJqQJCErcyF/n6lZeBJy0SYhHCA0mhJTGikkJTtCpEHkJ4hdBilGhGSDxVxImQnR+mSexbkRKIoT7ip1m2mESJmJ4uQDEmeWk1WUxCcp9rlUUKgomKiYaVntpjhpRTJzA62S2NqJS6HwPlFjKJw2FplE2YjzzDot6Twa9+OA41SsJL2WKMmLkDnolQPefR+ivV4c03AJE+WUdlnuGkHH9kb1ffV7w0jg6JFKw5SGKQ1TGubfG0YWZmgYa6Q0TGmY0jClYf7aMG/9Nw==';

    // Decode the base64 string to get the compressed bytes
    List<int> decodedBytes = base64Decode(base64Data);

    // Decompress the bytes using Gzip or Zip (depending on the compression method)
    Archive archive = GZipDecoder().decodeBytes(decodedBytes) as Archive;

    // If the decompressed data is text, we can convert it to a string.
    String decompressedString = utf8.decode(archive[0].content);

    print('Decompressed String: $decompressedString');
    return decompressedString;
  } catch (e) {
    print('Decompression error: $e');
    return null;
  }
}
