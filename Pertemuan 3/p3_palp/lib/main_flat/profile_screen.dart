import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.purple[100],
      ),
      body: Center(
        child: const Text(
          'This is Profile Screen',
          style: TextStyle(fontSize: 24),
        )
      ),
    );
  }
}