import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../models/app_user.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.user,
    required this.onUserChanged,
    required this.onViewOrders,
    required this.onLogout,
    super.key,
  });

  final AppUser user;
  final Future<void> Function(AppUser) onUserChanged;
  final VoidCallback onViewOrders;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AppUser _user = widget.user;

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) _user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.large,
        AppSpacing.medium,
        AppSpacing.large,
      ),
      children: [
        Text('My Profile', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.medium),
        Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.lightBlue,
                      child: Icon(
                        Icons.person_rounded,
                        size: 38,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(_user.fullName, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(_user.email, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(_user.phoneNumber, style: theme.textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      _user.address,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        Text('Account', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        _ProfileMenuItem(
          icon: Icons.person_outline,
          title: 'Personal Information',
          onTap: _editPersonalInformation,
        ),
        _ProfileMenuItem(
          icon: Icons.location_on_outlined,
          title: 'Delivery Address',
          onTap: _editAddress,
        ),
        _ProfileMenuItem(
          icon: Icons.receipt_long_outlined,
          title: 'My Orders',
          onTap: widget.onViewOrders,
        ),
        _ProfileMenuItem(
          icon: Icons.info_outline,
          title: 'About AquaQueue',
          onTap: _showAbout,
        ),
        const SizedBox(height: AppSpacing.small),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'Your profile is saved to your AquaQueue account.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _editPersonalInformation() async {
    final name = TextEditingController(text: _user.fullName);
    final phone = TextEditingController(text: _user.phoneNumber);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Information'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                key: const ValueKey('profile-name-input'),
                controller: name,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: AppSpacing.small),
              TextField(
                key: const ValueKey('profile-phone-input'),
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('profile-save-button'),
            onPressed: () async {
              final updated = _user.copyWith(
                fullName: name.text.trim(),
                phoneNumber: phone.text.trim(),
              );
              await _saveProfile(updated);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    phone.dispose();
  }

  Future<void> _editAddress() async {
    final address = TextEditingController(text: _user.address);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Address'),
        content: TextField(
          key: const ValueKey('profile-address-input'),
          controller: address,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Complete address'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (address.text.trim().isNotEmpty) {
                final updated = _user.copyWith(address: address.text.trim());
                await _saveProfile(updated);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    address.dispose();
  }

  Future<void> _saveProfile(AppUser updated) async {
    try {
      await widget.onUserChanged(updated);
      if (!mounted) return;
      setState(() => _user = updated);
      Navigator.of(context, rootNavigator: true).pop();
    } on UserServiceFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'AquaQueue',
      applicationVersion: 'Customer app',
      applicationIcon: const Icon(
        Icons.water_drop_rounded,
        color: AppColors.primary,
      ),
      children: const [Text('Refill. Book. Relax.')],
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Return to the AquaQueue sign-in screen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      try {
        await widget.onLogout();
      } on AuthFailure catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
