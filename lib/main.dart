import 'package:flutter/material.dart';
import 'login_page.dart';
import 'packages_page.dart';

void main() => runApp(PaquexpressApp());

class PaquexpressApp extends StatelessWidget {
  const PaquexpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Paquexpress',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/packages': (context) => PackagesPage(),
      },
    );
  }
}