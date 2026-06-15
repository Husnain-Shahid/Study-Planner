import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Loading...';

  bool _studyReminders = true;
  bool _taskDeadlines = true;
  bool _weeklyReport = false;
  bool _aiTips = true;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'feedback@studymate.app',
      queryParameters: {'subject': 'StudyMate Feedback'},
    );

    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF37474F),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.tune_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Control your app appearance and notifications.',
                    style: TextStyle(color: Color(0xFFD1D5DB)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: themeProvider.isDarkMode,
              onChanged: themeProvider.setDarkMode,
              title: const Text('Dark mode'),
              subtitle: const Text('Switch between light and dark appearance'),
              secondary: const Icon(Icons.dark_mode_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _studyReminders,
                  onChanged: (v) => setState(() => _studyReminders = v),
                  title: const Text('Study reminders'),
                  secondary: const Icon(Icons.notifications_active_rounded),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _taskDeadlines,
                  onChanged: (v) => setState(() => _taskDeadlines = v),
                  title: const Text('Task deadline alerts'),
                  secondary: const Icon(Icons.alarm_rounded),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _weeklyReport,
                  onChanged: (v) => setState(() => _weeklyReport = v),
                  title: const Text('Weekly report notifications'),
                  secondary: const Icon(Icons.insights_rounded),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: _aiTips,
                  onChanged: (v) => setState(() => _aiTips = v),
                  title: const Text('AI tips and suggestions'),
                  secondary: const Icon(Icons.smart_toy_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.feedback_rounded),
                  title: const Text('Send feedback'),
                  onTap: _sendFeedback,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('App version'),
                  subtitle: Text(_appVersion),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


