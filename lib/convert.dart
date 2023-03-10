import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;
import 'package:image/image.dart';

const shift = (0xFF << 24);
convertYUV420toImageColor(CameraImage image, {bool rotate = false}) {
  try {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;

    // imgLib -> Image package from https://pub.dartlang.org/packages/image
    var img = imglib.Image(width, height); // Create Image buffer

    // Fill image buffer with plane[0] from YUV420_888
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        // Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        img.data[index] = shift | (b << 16) | (g << 8) | r;
      }
    }

    // img = imglib.copyRotate(img, rotate ? -90 : 90);

    // ///trim rect
    // if (!rotate) {
    //   // List<int> trimRect;
    //   // var img1 = imglib.Image(400, 200);
    //   // trimRect = findTrim(img1, mode: TrimMode.transparent, sides: Trim.all);
    //   img = imglib.copyCrop(img, 20, 180, 400, 320);
    // }
    // img = imglib.copyCrop(img, 20, 500, 500, 320);
    imglib.PngEncoder pngEncoder = new imglib.PngEncoder(level: 0, filter: 0);

    List<int> png = pngEncoder.encodeImage(img);
    // muteYUVProcessing = false;
    return (png);
  } catch (e) {
    // print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  // return null;
}
