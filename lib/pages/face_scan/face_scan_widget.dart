import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceScanCameraWidget extends StatefulWidget {
  const FaceScanCameraWidget({Key? key}) : super(key: key);

  @override
  State<FaceScanCameraWidget> createState() => _FaceScanCameraWidgetState();
}

class _FaceScanCameraWidgetState extends State<FaceScanCameraWidget> {
  late CameraController? cameraController;
  late CameraValue cameraValue;
  late CameraDescription frontCamera;
  late Timer captureTimer;
  late bool isCameraInitialize = false;

  @override
  void initState() {
    super.initState();
    isCameraAvailable();
  }

  isCameraAvailable() {
    availableCameras().then((listCameraDescription) {
      log('camera found = ${listCameraDescription.length}');

      for (var camera in listCameraDescription) {
        if (camera.lensDirection.name == "front") {
          // get contoller
          cameraController = CameraController(camera, ResolutionPreset.high);

          // initialized
          cameraController!.initialize().then((_) {
            if (!mounted) {
              return;
            }

            // set camera value
            cameraValue = cameraController!.value;
            frontCamera = camera;

            // start image stream for image processing
            Future.delayed(Duration(seconds: 3)).then((value) {
              cameraController!.startImageStream((cameraImage) {
                // de face dectection
                faceDectection(image: cameraImage);
              }).catchError((error) {
                log('$error');
              });
            });

            // setstate
            setState(() {
              isCameraInitialize = true;
            });
          }).catchError((Object e) {
            // show error
            if (e is CameraException) {
              switch (e.code) {
                case 'CameraAccessDenied':
                  log('User denied camera access.');
                  break;
                default:
                  log('Handle other errors.');
                  break;
              }
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    cameraController!.stopImageStream();
    cameraController!.dispose();
    super.dispose();
  }

  faceDectection({required CameraImage image}) async {
    // convert camera image to input image
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final imageRotation = InputImageRotationValue.fromRawValue(frontCamera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

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

    final inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    // face detection
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableTracking: true,
      enableClassification: true,
      enableContours: true,
    );
    final faceDetector = FaceDetector(options: options);
    final List<Face> faces = await faceDetector.processImage(inputImage);

    log('found face = ${faces.length}');

    if (faces.isNotEmpty) {
      log('detect landmark');
      final Rect boundingBox = faces.first.boundingBox;
      final noseBase = faces.first.landmarks[FaceLandmarkType.noseBase];
      final bottomMouth = faces.first.landmarks[FaceLandmarkType.bottomMouth];
      final leftEyeOpen = faces.first.leftEyeOpenProbability;
      final rightEyeOpen = faces.first.rightEyeOpenProbability;

      log('face distance : ${boundingBox.height.floor()}');
      log('face center : ${boundingBox.center.distance}');

      log('nose postion : x=${noseBase!.position.x}, y=${noseBase.position.y}');

      log('left eye open : $leftEyeOpen');
      log('right eye open : $rightEyeOpen');
      log('bottom month : ${bottomMouth!.position.y}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCameraInitialize) {
      // show camera preview
      return Center(
        child: LayoutBuilder(builder: (context, constraints) {
          var scale = (constraints.maxWidth / constraints.maxHeight) * cameraValue.aspectRatio;
          if (scale < 1) scale = 1 / scale;
          return Transform.scale(
            scale: scale,
            child: CameraPreview(cameraController!),
          );
        }),
      );
    } else {
      return Container();
    }
  }
}

class FaceScanWidget extends StatefulWidget {
  const FaceScanWidget({Key? key}) : super(key: key);

  @override
  State<FaceScanWidget> createState() => _FaceScanWidgetState();
}

class _FaceScanWidgetState extends State<FaceScanWidget> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (contaxt, constraints) {
      return ClipOval(
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxWidth,
          child: const FaceScanCameraWidget(),
        ),
      );
    });
  }
}
