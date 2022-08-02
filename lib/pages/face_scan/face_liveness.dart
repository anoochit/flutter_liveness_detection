import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_facescan/pages/face_scan/face_liveness_widget.dart';

class FaceScanPage extends StatelessWidget {
  const FaceScanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FaceScanLivenessWidget(
          onChange: (value) {
            log('face scan result : ${value}');
          },
        ),
      ),
    );
  }
}
