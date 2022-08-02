import 'package:flutter/material.dart';
import 'package:flutter_facescan/pages/face_scan/face_scan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liveness',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FaceScanPage(),
    );
  }
}
