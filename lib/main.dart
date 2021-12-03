import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'scanner_utils.dart';

List<CameraDescription> cameras;
String plaka = "";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraView(cameras)),
    ).then((plaka) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Plaka Sorgu"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                plaka,
                style: const TextStyle(color: Colors.black, fontSize: 60),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: openCamera,
          child: const Icon(Icons.camera_alt),
        ));
  }
}

class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraView(this.cameras, {Key key}) : super(key: key);
  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> {
  bool flash = false;
  CameraController _camera;
  final TextRecognizer _recognizer = FirebaseVision.instance.textRecognizer();
  final description = cameras.firstWhere((CameraDescription camera) =>
      camera.lensDirection == CameraLensDirection.back);
  bool _isDetecting = false;
  VisionText _scanResults;
  RegExp plakaPattern1 =
      RegExp(r'\b\d{2}.{0,1}[^\d\W]{0,1}.{0,1}\b[^\d\W]{0,1}.{0,1}\b\d{3,4}\b');
  RegExp plakaPattern2 =
      RegExp(r'\b\d{2}.{0,1}[^\d\W]{0,1}.{0,1}\b[^\d\W]{0,1}.{0,1}\b\d{3,4}\b');
  RegExp plakaPattern3 = RegExp(
      r'\b\d{2}.{0,1}[^\d\W]{0,1}.{0,1}\b[^\d\W]{0,1}.{0,1}\w{0,1}.{0,1}\b\d{2,3}\b');
  Future<void> imageStream() async {
    await _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _isDetecting = true;
      ScannerUtils.detect(
        image: image,
        detectInImage: _recognizer.processImage,
        imageRotation: description.sensorOrientation,
      ).then(
        (dynamic results) {
          if (!mounted) return;
          setState(() {
            _scanResults = results;

            if ((plakaPattern1.hasMatch(_scanResults.text))) {
              plaka = plakaPattern1.stringMatch(_scanResults.text);
              Navigator.pop(context);
              _camera.stopImageStream();
            } else if ((plakaPattern2.hasMatch(_scanResults.text))) {
              plaka = plakaPattern2.stringMatch(_scanResults.text);
              Navigator.pop(context);
              _camera.stopImageStream();
            } else if ((plakaPattern3.hasMatch(_scanResults.text))) {
              plaka = plakaPattern3.stringMatch(_scanResults.text);
              Navigator.pop(context);
              _camera.stopImageStream();
            }
          });
        },
      ).whenComplete(() => _isDetecting = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _camera = CameraController(description, ResolutionPreset.max,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
    _camera.initialize().then((_) {
      if (!mounted) {
        return;
      }
      imageStream();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_camera),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                      color: Color.fromRGBO(00, 00, 00, 0.7), width: 320),
                  vertical: BorderSide(
                      color: Color.fromRGBO(00, 00, 00, 0.7), width: 30),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                        elevation: 0.0,
                        child: Icon(
                          flash ? Icons.flash_off : Icons.flash_on,
                          color: Colors.white,
                          size: 28,
                        ),
                        backgroundColor: const Color(0xFFE57373),
                        onPressed: () {
                          setState(() {
                            flash = !flash;
                          });
                          flash
                              ? _camera.setFlashMode(FlashMode.torch)
                              : _camera.setFlashMode(FlashMode.off);
                        })
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _camera.dispose().then((_) {
      _recognizer.close();
    });

    super.dispose();
  }
}
