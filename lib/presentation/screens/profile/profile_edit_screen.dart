import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jugendkompass_app/data/services/user_preferences_service.dart';
import 'package:jugendkompass_app/domain/providers/profile_provider.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';
import 'package:jugendkompass_app/data/models/profile_model.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _nameController;
  String? _avatarUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final userName = UserPreferencesService.instance.getUserName();
    _nameController = TextEditingController(text: userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Upload image to Supabase Storage
        final user = ref.read(supabaseProvider).auth.currentUser;

        if (user != null) {
          setState(() {
            _isSaving = true;
          });

          try {
            final profileRepo = ref.read(profileRepositoryProvider);
            final imageFile = File(image.path);

            // Delete old avatar if exists
            if (_avatarUrl != null) {
              try {
                await profileRepo.deleteAvatar(_avatarUrl!);
              } catch (_) {
                // Ignore if old avatar doesn't exist
              }
            }

            // Upload new avatar
            final newAvatarUrl = await profileRepo.uploadAvatar(user.id, imageFile);

            setState(() {
              _avatarUrl = newAvatarUrl;
            });

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bild erfolgreich hochgeladen'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler beim Hochladen: $e'),
                backgroundColor: Colors.red,
              ),
            );
          } finally {
            if (mounted) {
              setState(() {
                _isSaving = false;
              });
            }
          }
        } else {
          // User not authenticated - show message
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bitte melde dich an, um ein Profilbild hochzuladen'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Auswählen des Bildes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();

    if (name.isEmpty || name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib einen Namen mit mindestens 2 Zeichen ein'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Save to local storage
      await UserPreferencesService.instance.setUserName(name);

      // Update provider
      ref.read(userNameProvider.notifier).state = name;

      // Save to Supabase if authenticated
      final user = ref.read(supabaseProvider).auth.currentUser;

      if (user != null) {
        try {
          final profileRepo = ref.read(profileRepositoryProvider);

          // Get existing profile or create new one
          ProfileModel? existingProfile;
          try {
            existingProfile = await profileRepo.getProfile(user.id);
          } catch (_) {
            // Profile doesn't exist yet
          }

          // Create or update profile
          final profile = ProfileModel(
            id: existingProfile?.id ?? user.id,
            userId: user.id,
            name: name,
            avatarUrl: _avatarUrl ?? existingProfile?.avatarUrl,
            createdAt: existingProfile?.createdAt ?? DateTime.now(),
          );

          await profileRepo.updateProfile(profile);
        } catch (e) {
          // Log error but don't fail the save
          debugPrint('Failed to save to Supabase: $e');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil gespeichert'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil bearbeiten'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar Picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: _avatarUrl != null
                        ? CachedNetworkImageProvider(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: theme.colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name TextField
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const Spacer(),

            // Save Button
            FilledButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
