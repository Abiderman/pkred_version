import 'package:flutter/material.dart';

class ConexaoScreen extends StatelessWidget {
  const ConexaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0559C3), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Conexão',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: const SizedBox.shrink(),
    );
  }
}
