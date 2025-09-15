import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../thme/notifier.dart';
import 'theme_notifier.dart';

class Setting extends StatefulWidget {
  final Function(bool) onPrivacyChanged;
  final bool isPrivacyEnabled;

  const Setting({
    super.key,
    required this.onPrivacyChanged,
    required this.isPrivacyEnabled,
  });

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  late bool _isPrivacyEnabled;

  @override
  void initState() {
    super.initState();
    _isPrivacyEnabled = widget.isPrivacyEnabled;
  }

  Future<void> _updatePrivacySetting(bool value) async {
    setState(() {
      _isPrivacyEnabled = value;
    });
    widget.onPrivacyChanged(value);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('profile')
            .doc(user.uid)
            .set(
          {'settings': {'isPrivacyEnabled': value}},
          SetOptions(merge: true),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Privacy enabled' : 'Privacy disabled',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving privacy setting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6),
            title: const Text("Dark/Light Theme"),
            value: themeNotifier.isDarkTheme,
            onChanged: (bool value) {
              themeNotifier.toggleTheme(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.privacy_tip),
            title: const Text("Privacy Settings"),
            value: _isPrivacyEnabled,
            onChanged: _updatePrivacySetting,
          ),
        ],
      ),
    );
  }
}