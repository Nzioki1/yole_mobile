import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/api_providers.dart';
import '../widgets/gradient_button.dart';
import '../models/api/auth_response.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickProfileImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Select Image Source',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        final storage = ref.read(storageServiceProvider);
        await storage.saveProfileOverrides({'avatarPath': pickedFile.path});
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final storage = ref.watch(storageServiceProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom Header Section
            _ProfileHeader(
              onPickImage: _pickProfileImage,
              storage: storage,
              authState: authState,
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),

                // Personal Information Section
                _PersonalInformationCard(
                  storage: storage,
                  authState: authState,
                  onEdit: () => _showEditModal(context, storage, authState),
                ),
                const SizedBox(height: 24),

                // Settings Section
                _SectionHeader(title: 'Settings', theme: theme),
                _ProfileTile(
                  icon: Icons.shield_outlined,
                  title: l10n.darkMode,
                  trailing: Switch(
                    value: ref.watch(themeProvider).isDarkMode,
                    onChanged: (value) =>
                        ref.read(themeProvider.notifier).setThemeMode(value),
                    activeColor: theme.colorScheme.primary,
                  ),
                  theme: theme,
                ),

                // Support Section
                _SectionHeader(title: l10n.support, theme: theme),
                _ProfileTile(
                  icon: Icons.help_outline_rounded,
                  title: l10n.helpCenter,
                  theme: theme,
                ),
                _ProfileTile(
                  icon: Icons.description_outlined,
                  title: l10n.termsConditions,
                  theme: theme,
                ),
                _ProfileTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacyPolicy,
                  theme: theme,
                ),

                // Sign Out Button
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GradientButton(
                      onPressed: () => _showLogoutConfirmation(context, ref),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53E3E), Color(0xFFC53030)],
                    ),
                    child: Text(l10n.logOut),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, dynamic storage, AuthState authState) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final user = authState.user;
    
    // Get existing overrides
    final overridesFuture = storage.getProfileOverrides();

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: overridesFuture,
        builder: (context, snapshot) {
          final overrides = snapshot.data ?? {};
          
          return _EditPersonalInfoDialog(
            theme: theme,
            l10n: l10n,
            user: user,
            initialOverrides: overrides,
            onSave: (newOverrides) async {
              await storage.saveProfileOverrides(newOverrides);
              if (mounted) {
                  Navigator.pop(context);
                setState(() {});
              }
            },
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.logOut,
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          l10n.areYouSureLogOut,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends ConsumerStatefulWidget {
  final VoidCallback onPickImage;
  final dynamic storage;
  final AuthState authState;

  const _ProfileHeader({
    required this.onPickImage,
    required this.storage,
    required this.authState,
  });

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.authState.user;
    final isVerified = user?.isEmailVerified == true || user?.isPhoneVerified == true;

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle glass morphism effect without blur (to avoid blurring scrolling content)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              child: FutureBuilder<Map<String, dynamic>>(
                future: widget.storage.getProfileOverrides(),
                builder: (context, snapshot) {
                  final overrides = snapshot.data ?? {};
                  final name = (overrides['name'] as String?)?.trim().isNotEmpty == true
                      ? overrides['name'] as String
                      : (user?.name ?? '');
                  final surname = (overrides['surname'] as String?)?.trim().isNotEmpty == true
                      ? overrides['surname'] as String
                      : (user?.surname ?? '');
                  final avatarPath = overrides['avatarPath'] as String?;

                  final fullName = (name.isNotEmpty || surname.isNotEmpty)
                      ? '$name $surname'.trim()
                      : '—';
                  final initials = _computeInitials(name, surname);

                  return Column(
                    children: [
                      // Profile Picture with Camera Overlay
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: avatarPath == null
                                  ? LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                    )
                                  : null,
                              image: avatarPath != null
                                  ? DecorationImage(
                                      image: FileImage(File(avatarPath)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: avatarPath == null
                                ? Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 32,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          // Camera overlay button
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: widget.onPickImage,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          // Verified badge
                          if (isVerified)
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Full Name
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Verified Badge
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _computeInitials(String name, String surname) {
    final first = name.isNotEmpty ? name.trim().characters.first : '';
    final last = surname.isNotEmpty ? surname.trim().characters.first : '';
    final combined = (first + last).toUpperCase();
    return combined.isNotEmpty ? combined : '—';
  }
}

class _PersonalInformationCard extends StatelessWidget {
  final dynamic storage;
  final AuthState authState;
  final VoidCallback onEdit;

  const _PersonalInformationCard({
    required this.storage,
    required this.authState,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2B2F58)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: storage.getProfileOverrides(),
        builder: (context, snapshot) {
          final overrides = snapshot.data ?? {};
          final user = authState.user;

          final name = (overrides['name'] as String?)?.trim().isNotEmpty == true
              ? overrides['name'] as String
              : (user?.name ?? '');
          final surname = (overrides['surname'] as String?)?.trim().isNotEmpty == true
              ? overrides['surname'] as String
              : (user?.surname ?? '');
          final email = (overrides['email'] as String?)?.trim().isNotEmpty == true
              ? overrides['email'] as String
              : (user?.email ?? '');
          final phone = (overrides['phone'] as String?)?.trim().isNotEmpty == true
              ? overrides['phone'] as String
              : (user?.phone ?? '');
          final dateOfBirthStr = overrides['dateOfBirth'] as String?;
          final address = overrides['address'] as String? ?? '';

          DateTime? dateOfBirth;
          if (dateOfBirthStr != null && dateOfBirthStr.isNotEmpty) {
            try {
              dateOfBirth = DateTime.parse(dateOfBirthStr);
            } catch (_) {}
          }

          final fullName = (name.isNotEmpty || surname.isNotEmpty)
              ? '$name $surname'.trim()
              : '—';

          return Column(
            children: [
              // Section Header with Edit Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Text(
                      l10n.personalInformation,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Full Name Field
              _InfoField(
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                value: fullName,
                theme: theme,
              ),
              const Divider(height: 1, indent: 72),
              // Email Field
              _InfoField(
                icon: Icons.email_outlined,
                label: l10n.emailAddress,
                value: email.isNotEmpty ? email : '—',
                theme: theme,
              ),
              const Divider(height: 1, indent: 72),
              // Phone Field
              _InfoField(
                icon: Icons.phone_rounded,
                label: l10n.phoneNumber,
                value: phone.isNotEmpty ? phone : '—',
                theme: theme,
              ),
              const Divider(height: 1, indent: 72),
              // Date of Birth Field
              _InfoField(
                icon: Icons.calendar_today_outlined,
                label: 'Date of Birth',
                value: dateOfBirth != null
                    ? '${dateOfBirth.day}/${dateOfBirth.month}/${dateOfBirth.year}'
                    : '—',
                theme: theme,
              ),
              const Divider(height: 1, indent: 72),
              // Address Field
              _InfoField(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: address.isNotEmpty ? address : '—',
                theme: theme,
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPersonalInfoDialog extends StatefulWidget {
  final ThemeData theme;
  final AppLocalizations l10n;
  final UserProfile? user;
  final Map<String, dynamic> initialOverrides;
  final Function(Map<String, dynamic>) onSave;

  const _EditPersonalInfoDialog({
    required this.theme,
    required this.l10n,
    required this.user,
    required this.initialOverrides,
    required this.onSave,
  });

  @override
  State<_EditPersonalInfoDialog> createState() => _EditPersonalInfoDialogState();
}

class _EditPersonalInfoDialogState extends State<_EditPersonalInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    final name = (widget.initialOverrides['name'] as String?)?.trim() ?? widget.user?.name ?? '';
    final surname = (widget.initialOverrides['surname'] as String?)?.trim() ?? widget.user?.surname ?? '';
    final email = (widget.initialOverrides['email'] as String?)?.trim() ?? widget.user?.email ?? '';
    final phone = (widget.initialOverrides['phone'] as String?)?.trim() ?? widget.user?.phone ?? '';
    final address = widget.initialOverrides['address'] as String? ?? '';
    final dateOfBirthStr = widget.initialOverrides['dateOfBirth'] as String?;
    
    _firstNameController = TextEditingController(text: name);
    _lastNameController = TextEditingController(text: surname);
    _emailController = TextEditingController(text: email);
    _phoneController = TextEditingController(text: phone);
    _addressController = TextEditingController(text: address);
    
    if (dateOfBirthStr != null && dateOfBirthStr.isNotEmpty) {
      try {
        _dateOfBirth = DateTime.parse(dateOfBirthStr);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final overrides = <String, dynamic>{
        'name': _firstNameController.text.trim(),
        'surname': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        if (_dateOfBirth != null) 'dateOfBirth': _dateOfBirth!.toIso8601String(),
      };
      widget.onSave(overrides);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Edit Personal Information',
        style: widget.theme.textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: widget.l10n.emailAddress,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: widget.l10n.phoneNumber,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Date of Birth
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Select date',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Address
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            widget.l10n.cancel,
            style: widget.theme.textTheme.bodyMedium,
          ),
        ),
        GradientButton(
          onPressed: _save,
          height: 40,
          borderRadius: 12,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final ThemeData theme;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.theme,
    this.onTap,
  }) : assert(onTap != null || trailing != null || true);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2B2F58)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.textTheme.bodySmall?.color,
            ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
