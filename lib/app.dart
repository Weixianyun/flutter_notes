import 'package:flutter/material.dart';

class FlutterNotesApp extends StatelessWidget {
  const FlutterNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Flutter Notes - 环境就绪'),
        ),
      ),
    );
  }
}
