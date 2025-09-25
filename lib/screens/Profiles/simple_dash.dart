import 'package:flutter/material.dart';

class SimpleDash extends StatefulWidget {
  const SimpleDash({super.key});

  @override
  State<SimpleDash> createState() => _SimpleDashState();
}

class _SimpleDashState extends State<SimpleDash> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      
    );
  }
}