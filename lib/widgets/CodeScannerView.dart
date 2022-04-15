import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

import 'CameraPreviewMask.dart';

enum ScreenMode { liveFeed, gallery }

class CodeScannerView extends StatefulWidget {
  final ValueChanged<String> onScannerResult;
  final List<CameraDescription> cameras;
  final bool allowImagePicker;
  final bool allowCameraSwitch;

  CodeScannerView({
    required this.onScannerResult,
    this.cameras = const <CameraDescription>[],
    this.allowImagePicker = true,
    this.allowCameraSwitch = true,
  });

  @override
  _CodeScannerViewState createState() => _CodeScannerViewState();
}

class _CodeScannerViewState extends State<CodeScannerView> {
  TextDetector textDetector = GoogleMlKit.vision.textDetector();
  ScreenMode _mode = ScreenMode.liveFeed;
  CameraLensDirection initialDirection = CameraLensDirection.back;
  CameraController? _controller;
  File? _image;
  late ImagePicker _imagePicker;
  int _cameraIndex = 0;
  late List<CameraDescription> cameras;
  bool isBusy = false;
  bool codeFound = false;
  String code = "";

  @override
  void initState() {
    super.initState();

    _initScanner();
  }

  void _initScanner() async {
    cameras = widget.cameras;
    if (cameras.length == 0) {
      cameras = await availableCameras();
    }
    if (initialDirection == CameraLensDirection.front) {
      _cameraIndex = 1;
    }
    await _startLiveFeed();
    _imagePicker = ImagePicker();
  }

  @override
  void dispose() async {
    _stopLiveFeed();
    super.dispose();
    await textDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget? _floatingActionButton() {
    if (_mode == ScreenMode.gallery) return null;
    if (cameras.length == 1) return null;
    if (widget.allowCameraSwitch == false) return null;
    return Container(
        height: 70.0,
        width: 70.0,
        child: FloatingActionButton(
          child: Icon(
            Platform.isIOS
                ? Icons.flip_camera_ios_outlined
                : Icons.flip_camera_android_outlined,
            size: 40,
          ),
          onPressed: _switchLiveCamera,
        ));
  }

  Widget _body() {
    Widget body;
    if (_mode == ScreenMode.liveFeed)
      body = _liveFeedBody();
    else
      body = _galleryBody();
    return body;
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }
    return SafeArea(
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (_controller != null) CameraPreview(_controller!),
            CameraPreviewMask(),
            Positioned(
              top: 0.0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 20.0, top: 20),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(Icons.arrow_back),
                      ),
                    ),
                    if (widget.allowImagePicker)
                      Padding(
                        padding: EdgeInsets.only(right: 20.0, top: 20),
                        child: GestureDetector(
                          onTap: _switchScreenMode,
                          child: Icon(
                            _mode == ScreenMode.liveFeed
                                ? Icons.photo_library_outlined
                                : (Platform.isIOS
                                    ? Icons.camera_alt_outlined
                                    : Icons.camera),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _switchScreenMode() async {
    if (_mode == ScreenMode.liveFeed) {
      _mode = ScreenMode.gallery;
      await _stopLiveFeed();
    } else {
      _mode = ScreenMode.liveFeed;
      await _startLiveFeed();
    }
    setState(() {});
  }

  Widget _galleryBody() {
    return ListView(shrinkWrap: true, children: [
      _image != null
          ? Container(
              height: 400,
              width: 400,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.file(_image!),
                ],
              ),
            )
          : Icon(
              Icons.image,
              size: 200,
            ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('From Gallery'),
          onPressed: () => _getImage(ImageSource.gallery),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('Take a picture'),
          onPressed: () => _getImage(ImageSource.camera),
        ),
      ),
    ]);
  }

  Future _getImage(ImageSource source) async {
    final pickedFile = await _imagePicker.getImage(source: source);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    } else {
      print('No image selected.');
    }
    setState(() {});
  }

  Future _processPickedFile(PickedFile pickedFile) async {
    setState(() {
      _image = File(pickedFile.path);
    });
    final inputImage = InputImage.fromFilePath(pickedFile.path);
    processImage(inputImage);
  }

  RegExp regExp = RegExp(
    r"[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}",
    caseSensitive: false,
    multiLine: false,
  );

  // a515-qwwq-asca-4165
  // aaaa-aaaa-aaaa-aaaa
  // 0000-0000-0000-0000
  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;

    final recognisedText = await textDetector.processImage(inputImage);
    for (final textBlock in recognisedText.blocks) {
      if (!regExp.hasMatch(textBlock.text)) {
        continue;
      }

      var possibleCODE = regExp.firstMatch(textBlock.text)!.group(0).toString();
      debugPrint(possibleCODE);

      code = possibleCODE;
      codeFound = true;
      break;
    }

    if (codeFound) {
      widget.onScannerResult(code);
    }

    isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    if (_cameraIndex == 0)
      _cameraIndex = 1;
    else
      _cameraIndex = 0;
    await _stopLiveFeed();
    await _startLiveFeed();
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationMethods.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.Rotation_0deg;

    final inputImageFormat =
        InputImageFormatMethods.fromRawValue(image.format.raw) ??
            InputImageFormat.NV21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    if (mounted) {
      processImage(inputImage);
    }
  }
}