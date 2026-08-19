import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../theme/app_theme.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _controller;
  String _activeUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _activeUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(String url) async {
    await ApiConfig.setBaseUrl(url);
    if (!mounted) return;
    setState(() => _activeUrl = ApiConfig.baseUrl);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adresse serveur mise à jour : ${ApiConfig.baseUrl}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, color: AppColors.navy),
          SizedBox(width: 10),
          Text('Configuration Backend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionnez ou saisissez l\'adresse IP de votre ordinateur (backend Spring Boot).',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            const Text('Presets disponibles :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy)),
            const SizedBox(height: 8),

            // Candidates list
            ...ApiConfig.candidateUrls.map(
              (candidate) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  candidate == _activeUrl ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: candidate == _activeUrl ? AppColors.primary : Colors.grey,
                  size: 20,
                ),
                title: Text(candidate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  candidate.contains('172.20.14.187')
                      ? 'IP Wi-Fi PC (Utilisateurs physiques)'
                      : (candidate.contains('localhost') ? 'ADB USB Reverse' : 'Émulateur Android'),
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () => _save(candidate),
              ),
            ),

            const Divider(height: 24),
            const Text('Adresse IP / URL personnalisée :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navy)),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ex: http://192.168.1.50:8080',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) _save(text);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
          child: const Text('Appliquer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
