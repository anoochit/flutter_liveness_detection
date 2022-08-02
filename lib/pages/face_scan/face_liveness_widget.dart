import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceScanLivenessWidget extends StatefulWidget {
  const FaceScanLivenessWidget({Key? key, required this.onStateChange}) : super(key: key);

  final ValueChanged<int> onStateChange;

  @override
  State<FaceScanLivenessWidget> createState() => _FaceScanLivenessWidgetState();
}

class _FaceScanLivenessWidgetState extends State<FaceScanLivenessWidget> {
  late CameraController? cameraController;
  late CameraValue cameraValue;
  late CameraDescription frontCamera;
  late Timer captureTimer;
  late bool isCameraInitialize = false;

  int stepIndex = 0;
  double faceHeightOffset = 500;
  double headZAnagleOffset = 1.0;
  double blinkOffset = 0.15;
  double headZAnagleBase = 0.0;
  int bottomMouthBase = 0;
  int bottomMouthBaseOffset = 50;

  static List<String> listState = [
    "Put your face on frame",
    "Blink your eyes",
    "Turn head left",
    "Turn head right",
    "Open your mouth",
    "OK",
  ];

  static List<Color> listColors = [
    Colors.grey.shade200,
    Colors.green.shade50,
    Colors.green.shade100,
    Colors.green.shade200,
    Colors.green.shade400,
    Colors.green.shade500,
  ];

  @override
  void initState() {
    super.initState();
    // check camera is available
    isCameraAvailable();
  }

  isCameraAvailable() {
    // check available camera
    availableCameras().then((listCameraDescription) {
      log('camera found = ${listCameraDescription.length}');

      // process only front camera
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
            Future.delayed(const Duration(seconds: 3)).then((value) {
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
      // step 1 ask user for face detection
      final Rect boundingBox = faces.first.boundingBox;

      final noseBase = faces.first.landmarks[FaceLandmarkType.noseBase];

      final bottomMouth = faces.first.landmarks[FaceLandmarkType.bottomMouth];

      final leftEyeOpen = faces.first.leftEyeOpenProbability;
      final rightEyeOpen = faces.first.rightEyeOpenProbability;

      final headEulerAngleZ = faces.first.headEulerAngleZ;

      log('face distance : ${boundingBox.height}');
      log('face center : ${boundingBox.center.distance}');

      log('nose postion : x=${noseBase!.position.x}, y=${noseBase.position.y}');

      log('left eye open : $leftEyeOpen');
      log('right eye open : $rightEyeOpen');

      log('bottom month : ${bottomMouth!.position.y}');

      log('head angle z : ${headEulerAngleZ}');

      log('detection step : ${stepIndex}');

      // check when face in frame
      if ((boundingBox.height > faceHeightOffset)) {
        // if already check found and in frame
        if (stepIndex < 1) {
          changeStateDection(1);
        }
      } else {
        changeStateDection(0);
      }

      // if face is already in frame
      if (stepIndex > 0) {
        switch (stepIndex) {
          case 1:
            {
              log('step blink detection');
              if ((leftEyeOpen! < blinkOffset) && (rightEyeOpen! < blinkOffset)) {
                log('step blink detection : yes');
                headZAnagleBase = headEulerAngleZ!;
                bottomMouthBase = bottomMouth.position.y;
                changeStateDection(2);
              }
            }
            break;

          case 2:
            {
              log('head base ${headZAnagleBase}');
              log('step turn head left detection : ${(headEulerAngleZ)} ');
              if (headEulerAngleZ! < (headZAnagleBase - headZAnagleOffset)) {
                log('step turn head left detection : yes');
                changeStateDection(3);
              }
            }
            break;

          case 3:
            {
              log('step face turn right detection : ${(headEulerAngleZ)}');
              if (headEulerAngleZ! > (headZAnagleBase + headZAnagleOffset)) {
                log('step turn head righ : yes');
                changeStateDection(4);
              }
            }
            break;

          case 4:
            {
              log('step open mouth : ${bottomMouthBase}');
              log('step open mouth detection : ${bottomMouth.position.y}');
              if ((bottomMouth.position.y) > (bottomMouthBase + bottomMouthBaseOffset)) {
                log('step open mouth detection : yes');
                changeStateDection(5);
              }
            }
            break;
        }
      }
    }
  }

  changeStateDection(int state) {
    widget.onStateChange(state);
    setState(() {
      stepIndex = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isCameraInitialize) {
      // show camera preview
      return LayoutBuilder(builder: (contaxt, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: constraints.maxWidth,
              height: constraints.maxWidth,
              decoration: BoxDecoration(
                border: Border.all(width: 8, color: listColors[stepIndex]),
                borderRadius: BorderRadius.circular(constraints.maxWidth / 2),
              ),
              child: ClipOval(
                  child: SizedBox(
                      width: constraints.maxWidth - 8,
                      height: constraints.maxWidth - 8,
                      child: Center(
                        child: LayoutBuilder(builder: (context, constraints) {
                          var scale = (constraints.maxWidth / constraints.maxHeight) * cameraValue.aspectRatio;
                          if (scale < 1) scale = 1 / scale;
                          return Transform.scale(
                            scale: scale,
                            child: CameraPreview(cameraController!),
                          );
                        }),
                      ))),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                listState[stepIndex],
                style: Theme.of(context).textTheme.headline5,
              ),
            )
          ],
        );
      });
    } else {
      return Container();
    }
  }
}
