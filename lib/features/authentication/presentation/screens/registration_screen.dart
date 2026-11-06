import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/constants/app_spacing.dart';
import '../auth_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    required this.onBackToLogin,
    super.key,
  });

  final VoidCallback onBackToLogin;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.mediumLarge,
              AppSpacing.small,
              AppSpacing.mediumLarge,
              AppSpacing.large,
            ),
            children: [
              Text('Join AquaQueue', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Create your customer profile to get started.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.large),
              AppTextField(
                label: 'Full name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: _requiredValidator,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.smallMedium),
              AppTextField(
                label: 'Email address',
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.smallMedium),
              AppTextField(
                label: 'Phone number',
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _requiredValidator,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.smallMedium),
              AppTextField(
                label: 'Delivery address',
                controller: _addressController,
                prefixIcon: Icons.location_on_outlined,
                validator: _requiredValidator,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.smallMedium),
              AppTextField(
                label: 'Password',
                controller: _passwordController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Create a password.';
                  }
                  if (value.length < 6) return 'Use at least 6 characters.';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.smallMedium),
              AppTextField(
                label: 'Confirm password',
                controller: _confirmController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm your password.';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.large),
              AppButton(
                label: 'Complete Registration',
                isLoading: auth.isSubmitting,
                onPressed: _completeRegistration,
              ),
              if (auth.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  auth.errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.smallMedium),
              TextButton(
                onPressed: widget.onBackToLogin,
                child: const Text('Already have an account? Log in'),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'Your password is handled securely by Firebase Authentication.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  Future<void> _completeRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final registered = await context.read<AuthProvider>().register(
      fullName: _nameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
      password: _passwordController.text,
    );
    if (registered && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
