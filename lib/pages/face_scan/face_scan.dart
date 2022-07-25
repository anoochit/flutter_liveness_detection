import 'package:flutter/material.dart';
import 'package:flutter_facescan/pages/face_scan/face_scan_widget.dart';

class FaceScanPage extends StatelessWidget {
  const FaceScanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FaceScanWidget(),
      ),
    );
  }
}
