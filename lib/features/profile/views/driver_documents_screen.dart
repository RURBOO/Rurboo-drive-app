import 'dart:convert';
import 'package:flutter/material.dart';

class DriverDocumentsScreen extends StatelessWidget {
  final String? licenseBase64;
  final String? rcBase64;

  const DriverDocumentsScreen({
    super.key,
    required this.licenseBase64,
    required this.rcBase64,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Documents")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDocSection("Driving License", licenseBase64),
            const SizedBox(height: 30),
            _buildDocSection("Vehicle Registration (RC)", rcBase64),
          ],
        ),
      ),
    );
  }

  Widget _buildDocSection(String title, String? base64String) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: (base64String != null && base64String.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(base64String),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Text("Error loading image")),
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "No document found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
