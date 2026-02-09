import 'package:flutter/material.dart';
import 'package:flutter_metro_app/home_metro.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeMetro(),
    );
  }
}
