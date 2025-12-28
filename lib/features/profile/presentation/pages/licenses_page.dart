import 'package:flutter/material.dart';

class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // List your main high-level packages here
    final List<Map<String, String>> libraries = [
      {'name': 'Flutter SDK', 'version': '3.x.x', 'license': 'BSD-3-Clause'},
      {'name': 'Riverpod', 'version': '2.5.x', 'license': 'MIT'},
      {'name': 'GoRouter', 'version': '13.x.x', 'license': 'MIT'},
      {'name': 'Font Awesome', 'version': '10.x.x', 'license': 'SIL OFL 1.1'},
      {'name': 'Firebase SDK', 'version': 'Latest', 'license': 'Apache 2.0'},
      {'name': 'Flutter Secure Storage', 'version': '9.x.x', 'license': 'BSD-3-Clause'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Source Licenses'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: libraries.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lib = libraries[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(
                lib['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Version ${lib['version']} • ${lib['license']}'),
              ),
              trailing: const Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
            ),
          );
        },
      ),
    );
  }
}