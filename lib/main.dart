import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liveliness/custom_paint.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: CustomCirclePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  var cameraInitialized = false;
  var prediction;
  var pred;
  var cameraController;
  var running = false;
  var path;
  var processTime;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadmodel();
  }

  loadmodel() async {
    await Tflite.loadModel(
        model: "assets/2/model_unquant.tflite", labels: "assets/2/labels.txt");
    loadCamera();
  }

  loadCamera() async {
    var cameras = await availableCameras();
    cameraController = CameraController(cameras[1], ResolutionPreset.max);
    await cameraController.initialize();
    cameraInitialized = true;
    setState(() {});
    cameraController.startImageStream(runModel);
  }

  // switchCamera() async {
  //   cameraController.dispose();
  //   cameraController = null;
  //   var cameras = await availableCameras();
  //   cameraController = CameraController(cameras[1], ResolutionPreset.medium);
  //   await cameraController.initialize();
  //   cameraInitialized = true;
  //   setState(() {});
  //   cameraController.startImageStream(runModel);
  // }

  runModel(CameraImage image) async {
    if (running) {
    } else {
      running = true;
      var now = DateTime.now().millisecondsSinceEpoch;
      var predictions = await Tflite.runModelOnFrame(
          bytesList: image.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: image.height,
          imageWidth: image.width,
          imageMean: 127.5, // defaults to 127.5
          imageStd: 127.5, // defaults to 127.5
          rotation: 90,
          threshold: .1,
          asynch: true);
      processTime = DateTime.now().millisecondsSinceEpoch - now;
      print(predictions);
      prediction = predictions;
      setState(() {});
      running = false;
    }
  }

//   Uint8List imageToByteListFloat32(
//     img.Image image, int inputSize, double mean, double std) {
//   var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
//   var buffer = Float32List.view(convertedBytes.buffer);
//   int pixelIndex = 0;
//   for (var i = 0; i < inputSize; i++) {
//     for (var j = 0; j < inputSize; j++) {
//       var pixel = image.getPixel(j, i);
//       buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
//       buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
//       buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
//     }
//   }
//   return convertedBytes.buffer.asUint8List();
// }
  void _incrementCounter() async {
    var image = await ImagePicker().pickImage(source: ImageSource.camera);
    var predictions = await Tflite.runModelOnImage(
      path: image!.path,
    );
    path = (image.path);
    print(predictions);
    pred = predictions;
    loadCamera();
    setState(() {});
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Stack(
          children: <Widget>[
            if (cameraInitialized) CameraPreview(cameraController),
            Center(
                child: Text(
              prediction.toString(),
              style: TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.red, offset: Offset(1, 1))]),
            )),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                pred.toString(),
                style: TextStyle(
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.red, offset: Offset(1, 1))]),
              ),
            ),
            Text(
              processTime.toString(),
              style: TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.red, offset: Offset(1, 1))]),
            ),
            Positioned(
              bottom: 20,
              left: 10,
              right: 10,
              child: Text(
                path.toString(),
                // style: Theme.of(context).textTheme.headline4,
              ),
            ),
            // FloatingActionButton(
            //   onPressed: switchCamera,
            //   tooltip: 'Increment',
            //   child: const Icon(Icons.switch_camera),
            // ), // T
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
