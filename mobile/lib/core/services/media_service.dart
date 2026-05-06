import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();
  final DioClient _dioClient;

  MediaService(this._dioClient);

  Future<XFile?> pickAndCompressImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final targetPath = '${image.path}_compressed.jpg';

    // Compress while keeping EXIF data as per backend requirements
    final compressedImage = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      quality: 80,
      keepExif: true, // EXIF MUST BE PRESERVED
    );

    return compressedImage;
  }

  Future<String?> uploadToCloudinary(String imagePath) async {
    try {
      // 1. Get Signature from Go Backend
      final sigResponse = await _dioClient.instance.get('/api/storage/signature');
      final sigData = sigResponse.data;
      
      final cloudName = sigData['cloud_name'];
      final apiKey = sigData['api_key'];
      final timestamp = sigData['timestamp'].toString();
      final signature = sigData['signature'];
      final folder = sigData['folder'];

      // 2. Upload directly to Cloudinary
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath),
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
        'folder': folder,
      });

      final uploadResponse = await dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        data: formData,
      );

      return uploadResponse.data['secure_url'];
    } catch (e) {
      print('Cloudinary upload failed: $e');
      return null;
    }
  }
}
