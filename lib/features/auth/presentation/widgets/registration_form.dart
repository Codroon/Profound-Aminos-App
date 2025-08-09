import 'package:flutter/material.dart';
import 'package:woo_management_app/features/auth/presentation/widgets/phone_number_input_field.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _agreeToTerms = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Only support Username Register',
            style: TextStyle(color: AppColors.surfaceLight, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Username Field
          CustomTextField(
            controller: _usernameController,
            hintText: 'Please enter Username',
            prefixIcon: Icons.person_outline,
            validator: Validators.validateUsername,
          ),
          const SizedBox(height: 16),

          // Password Field
          CustomTextField(
            controller: _passwordController,
            hintText: 'Please enter password',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            obscureText: !_isPasswordVisible,
            validator: Validators.validatePassword,
          ),
          const SizedBox(height: 16),

          // Strength Indicator
          _buildPasswordStrength(),
          const SizedBox(height: 16),

          // Phone Number Field
          PhoneNumberInputField(
            controller: _phoneController,
            onChanged: (val) {},
          ),
          const SizedBox(height: 16),

          // Referral Code Field
          CustomTextField(
            controller: _referralController,
            hintText: 'Please enter your referral code',
            prefixIcon: Icons.card_giftcard_outlined,
          ),
          const SizedBox(height: 24),

          // Terms Agreement
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
                activeColor: AppColors.success,
                checkColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      text:
                          'I am over 18 years old and have read and agreed to the ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: '<<User Agreement',
                          style: TextStyle(
                            color: AppColors.surfaceLight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Register Button
          CustomButton(
            text: 'Register',
            // onPressed:
            // _agreeToTerms && !authProvider.isLoading
            //     ? () => _handleRegister(authProvider)
            //     : null,
            // isLoading: authProvider.isLoading,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        const Text(
          'Strength',
          style: TextStyle(color: AppColors.surfaceLight, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Row(
          children: List.generate(4, (index) {
            Color color = AppColors.border;
            if (strength > index) {
              if (strength <= 1) {
                color = AppColors.error;
              } else if (strength <= 2)
                color = AppColors.warning;
              else if (strength <= 3)
                color = AppColors.info;
              else
                color = AppColors.success;
            }

            return SizedBox(
              width: 44,
              child: Container(
                height: 2,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  int _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }
}

/*
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _agreeToTerms = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Only support Username Register',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Username Field
              CustomTextField(
                controller: _usernameController,
                hintText: 'Please enter Username',
                prefixIcon: Icons.person_outline,
                validator: Validators.validateUsername,
              ),
              const SizedBox(height: 16),

              // Password Field
              CustomTextField(
                controller: _passwordController,
                hintText: 'Please enter password',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                obscureText: !_isPasswordVisible,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),

              // Strength Indicator
              _buildPasswordStrength(),
              const SizedBox(height: 16),

              // Phone Number Field
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.green,
                          ),
                          child: const Center(
                            child: Text('🇧🇷', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '+55',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _phoneController,
                      hintText: 'Please enter phone number',
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Referral Code Field
              CustomTextField(
                controller: _referralController,
                hintText: 'Please enter your referral code',
                prefixIcon: Icons.card_giftcard_outlined,
              ),
              const SizedBox(height: 24),

              // Terms Agreement
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                    activeColor: AppColors.success,
                    checkColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'I am over 18 years old and have read and agreed to the User Agreement',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Register Button
              CustomButton(
                text: 'Register',
                onPressed:
                    _agreeToTerms && !authProvider.isLoading
                        ? () => _handleRegister(authProvider)
                        : null,
                isLoading: authProvider.isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Strength',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            Color color = AppColors.border;
            if (strength > index) {
              if (strength <= 1)
                color = AppColors.error;
              else if (strength <= 2)
                color = AppColors.warning;
              else if (strength <= 3)
                color = AppColors.info;
              else
                color = AppColors.success;
            }

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  int _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  void _handleRegister(AuthProvider authProvider) {
    if (_formKey.currentState!.validate()) {
      authProvider.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        referralCode: _referralController.text.trim(),
      );
    }
  }
}
 */
