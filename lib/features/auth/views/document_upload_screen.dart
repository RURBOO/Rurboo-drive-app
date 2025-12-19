import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/registration_viewmodel.dart';

class DocumentUploadScreen extends StatelessWidget {
  const DocumentUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistrationViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Documents (3/3)")),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  "Required Documents",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _buildUploadTile(
                  title: 'Driving License',
                  fileName: vm.licenseFile?.path,
                  onTap: () => vm.pickImage('license'),
                ),

                _buildUploadTile(
                  title: 'Vehicle Registration (RC)',
                  fileName: vm.registrationFile?.path,
                  onTap: () => vm.pickImage('registration'),
                ),

                _buildUploadTile(
                  title: 'Profile Photo',
                  fileName: vm.profileFile?.path,
                  onTap: () => vm.pickImage('profile'),
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    vm.submitApplication(context);
                  },
                  child: const Text("Submit Application"),
                ),
              ],
            ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    String? fileName,
    required VoidCallback onTap,
  }) {
    final bool isUploaded = fileName != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: isUploaded
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(fileName),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.upload_file, color: Colors.grey),
              ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          isUploaded ? "Tap to change" : "Required",
          style: TextStyle(color: isUploaded ? Colors.green : Colors.red),
        ),
        trailing: Icon(
          isUploaded ? Icons.check_circle : Icons.add_a_photo_outlined,
          color: isUploaded ? Colors.green : Colors.black54,
        ),
        onTap: onTap,
      ),
    );
  }
}
