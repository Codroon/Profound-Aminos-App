import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/routes_name.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
            'Support Phone number/Username login',
            style: TextStyle(color: AppColors.surfaceLight, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Username/Phone Field
          CustomTextField(
            controller: _usernameController,
            hintText: 'Please enter Phone number/Username',
            prefixIcon: Icons.person_outline,
            validator: Validators.validateUsernameOrPhone,
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
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                showForgetPasswordDialog(context);
                // Navigator.pushNamed(context, RouteNames.forgotPassword);
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: AppColors.surfaceLight, fontSize: 12),
              ),
            ),
          ),

          // Remember Password & Forgot Password
          Row(
            children: [
              Checkbox(
                value: _rememberPassword,
                onChanged: (value) {
                  setState(() {
                    _rememberPassword = value ?? false;
                  });
                },
                activeColor: AppColors.success,
                checkColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
              ),
              const Text(
                'Remember account Password',
                style: TextStyle(color: AppColors.surfaceLight, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Login Button
          CustomButton(
            text: 'Login',
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.bottomNav);
            },
            // onPressed:
            // !authProvider.isLoading
            //     ? () => _handleLogin(authProvider)
            //     : null,
            // isLoading: authProvider.isLoading,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void showForgetPasswordDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ForgotPassword',
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Transform.scale(
            scale: anim1.value,
            child: Opacity(
              opacity: anim1.value,
              child: Stack(
                children: [
                  // Blur background
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),
                  // Centered Dialog
                  Center(
                    child: Dialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Forget Password?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Step 1
                                  Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primary,
                                        child: const Text(
                                          '1',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Identity Verification',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 40),

                                  // Step 2
                                  Column(
                                    children: [
                                      const CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Color(0xFFD9D9D9),
                                        child: Text(
                                          '2',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Change Password',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFB3B3B3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                hintText: 'Please enter Phone number/Email',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFB3B3B3),
                                  fontSize: 10,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  size: 20,
                                  color: AppColors.iconColor,
                                ),
                                filled: true,
                                fillColor: Color(0xFFF5F5F5),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF36363E),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF36363E),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.resetPassword,
                                  );
                                },
                                text: 'Change Password',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  // void _handleLogin(AuthProvider authProvider) {
  //   if (_formKey.currentState!.validate()) {
  //     authProvider.login(
  //       username: _usernameController.text.trim(),
  //       password: _passwordController.text,
  //       rememberMe: _rememberPassword,
  //     );
  //   }
  // }
}

/*
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
                'Support Phone number/Username login',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Username/Phone Field
              CustomTextField(
                controller: _usernameController,
                hintText: 'Please enter Phone number/Username',
                prefixIcon: Icons.person_outline,
                validator: Validators.validateUsernameOrPhone,
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

              // Remember Password & Forgot Password
              Row(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberPassword,
                        onChanged: (value) {
                          setState(() {
                            _rememberPassword = value ?? false;
                          });
                        },
                        activeColor: AppColors.success,
                        checkColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      const Text(
                        'Remember account Password',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.forgotPassword);
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Login Button
              CustomButton(
                text: 'Login',
                onPressed:
                    !authProvider.isLoading
                        ? () => _handleLogin(authProvider)
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

  void _handleLogin(AuthProvider authProvider) {
    if (_formKey.currentState!.validate()) {
      authProvider.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberPassword,
      );
    }
  }
}
 */
