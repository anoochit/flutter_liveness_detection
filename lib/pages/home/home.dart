import 'package:flutter/material.dart';
import 'package:flutter_facescan/pages/face_scan/face_liveness.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text("Start Face Scan"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FaceScanPage(),
              ),
            );
          },
        ),
      ),
    );
  }
}
