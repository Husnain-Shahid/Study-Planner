import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  String _name = 'Husnain Shahid';
  String _bio = 'Focused on consistent learning and smart study routines.';
  String _grade = 'Computer Science Student';

  int _totalHours = 126;
  int _badges = 8;
  int _level = 5;

  File? _avatarFile;

  Future<void> _pickAvatar(ImageSource source) async {
    final file = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _avatarFile = File(file.path);
    });
  }

  void _openAvatarOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Upload from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editProfileDetails() async {
    final nameController = TextEditingController(text: _name);
    final bioController = TextEditingController(text: _bio);
    final gradeController = TextEditingController(text: _grade);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bioController,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: gradeController,
                    decoration: const InputDecoration(labelText: 'Grade / Program'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _name = nameController.text.trim().isEmpty ? _name : nameController.text.trim();
                          _bio = bioController.text.trim().isEmpty ? _bio : bioController.text.trim();
                          _grade = gradeController.text.trim().isEmpty ? _grade : gradeController.text.trim();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportProfileAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('StudyMate Profile Export',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 18),
              pw.Text('Name: $_name'),
              pw.Text('Bio: $_bio'),
              pw.Text('Grade: $_grade'),
              pw.SizedBox(height: 12),
              pw.Text('Stats', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Total hours: $_totalHours'),
              pw.Text('Badges: $_badges'),
              pw.Text('Level: $_level'),
              pw.Spacer(),
              pw.Text('Exported from StudyMate', style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/study_profile_export.pdf');
    await file.writeAsBytes(await pdf.save());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF exported: ${file.path}')),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: const Text('This action is permanent. Do you want to continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion request submitted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            name: _name,
            grade: _grade,
            bio: _bio,
            avatarFile: _avatarFile,
            onAvatarTap: _openAvatarOptions,
            onEditTap: _editProfileDetails,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Total Hours', value: '$_totalHours h', icon: Icons.timer_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(title: 'Badges', value: '$_badges', icon: Icons.emoji_events_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(title: 'Level', value: '$_level', icon: Icons.rocket_launch_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_rounded),
                  title: const Text('Settings'),
                  subtitle: const Text('Theme, reminders, and app preferences'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Export profile as PDF'),
              onTap: _exportProfileAsPdf,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
                  title: const Text('Logout'),
                  onTap: _confirmLogout,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFD32F2F)),
                  title: const Text('Delete account'),
                  onTap: _confirmDeleteAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String grade;
  final String bio;
  final File? avatarFile;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditTap;

  const _ProfileHeader({
    required this.name,
    required this.grade,
    required this.bio,
    required this.avatarFile,
    required this.onAvatarTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFFE0E7FF),
                  backgroundImage: avatarFile != null ? FileImage(avatarFile!) : null,
                  child: avatarFile == null
                      ? const Icon(Icons.person_rounded, size: 40, color: Color(0xFF6366F1))
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Color(0xFF37474F), shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(grade, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(
            bio,
            style: const TextStyle(color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onEditTap,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit profile'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF37474F)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }
}