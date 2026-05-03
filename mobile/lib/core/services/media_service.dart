import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

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
}
