
import 'package:flutter/material.dart';

 import 'home_page.dart';
// import 'login_page.dart';
import 'sign_up.dart';
 


void main() => runApp(const MyApp());


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        // '/': (context) => const LoginPage(),
        '/': (context) =>  SignUpScreen(),
        '/home': (context) =>  HomePage(),
      },
    );
  }
}