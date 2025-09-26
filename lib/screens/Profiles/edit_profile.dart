import 'dart:io';
import 'package:event_manager_local/widgets/full_width_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:event_manager_local/models/profile.dart';
import 'package:event_manager_local/services/profile_service.dart';
import 'package:event_manager_local/utils/image_utils.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _pickedImage;
  bool _loading = false;

  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile();
    if (profile != null) {
      setState(() {
        _profile = profile;
        _usernameController.text = profile.username;
        _emailController.text = profile.email ?? '';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String? imageUrl = _profile?.profileUrl;

      // Upload new image if picked
      if (_pickedImage != null) {
        final fileName = '${_profile!.id}.jpg';
        await Supabase.instance.client.storage
            .from('avatars')
            .upload(
              fileName,
              _pickedImage!,
              fileOptions: const FileOptions(upsert: true),
            );

        imageUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(fileName);
      }

      // Update profile table
      await Supabase.instance.client
          .from('profiles')
          .update({
            'username': _usernameController.text,
            'email': _emailController.text,
            'profile_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _profile!.id);

      // Update password if provided
      if (_passwordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      radius: 70,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (_profile!.profileUrl.isNotEmpty
                                    ? ImageUtils.cachedNetworkImageProvider(
                                        _profile!.profileUrl,
                                      )
                                    : const AssetImage(
                                        'assets/default_avatar.png',
                                      ))
                                as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                        child: IconButton(
                          color: Colors.white,
                          icon: const Icon(Icons.camera_alt),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (val) => val == null || !val.contains('@')
                    ? "Enter valid email"
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "New Password"),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Confirm New Password",
                ),
                obscureText: true,
                validator: (val) {
                  if (_passwordController.text.isNotEmpty &&
                      val != _passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FullWidthButton(
                      onTap: _saveProfile,
                      buttonText: "Save Changes",
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
