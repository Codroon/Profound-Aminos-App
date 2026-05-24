import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:woo_management_app/core/services/crediential_storage_service.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/core/theme/app_text_style.dart';
import 'package:woo_management_app/core/utils/motion_toast.dart';
import 'package:woo_management_app/features/home/presentation/pages/bottom_nav_page.dart';
import 'package:woo_management_app/widgets/custom_button.dart';
import 'package:woo_management_app/widgets/custom_loading_widget.dart';
import 'package:woo_management_app/widgets/custom_text_field.dart';
import 'package:woo_management_app/core/services/push_notification_service.dart';

import '../../../../core/services/credential_initialization_service.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final _storage = CredentialStorageService();
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
  );

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    log('[AdminLogin] Login process started', name: 'AdminLogin');
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      log('[AdminLogin] Firebase login successful', name: 'AdminLogin');
      // Fetch credentials from Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('credentials')
              .doc('c4GnCMfHHkJioZ7fcLBQ')
              .get();
      if (!doc.exists) throw Exception('Credentials not found!');
      final data = doc.data()!;
      log(
        '[AdminLogin] Fetched Firestore credentials: $data',
        name: 'AdminLogin',
      );
      // Map Firestore fields to your expected keys
      // inside _login(), after mapping WooCommerce/WordPress/Gorgias credentials
      final creds = {
        'wooKey': (data['wooKey'] ?? '').toString(),
        'wooSecret': (data['wooSecret'] ?? '').toString(),
        'wooUrl': (data['wooUrl'] ?? '').toString(),
        'wpUser': (data['wordPressUserName'] ?? '').toString(),
        'wpPass': (data['wpAppPassword'] ?? '').toString(),
        'gorgiasToken': (data['gorgiasToken'] ?? '').toString(),
        'gorgiasSub': _extractGorgiasSubdomain(
          (data['gorgiasUrl'] ?? '').toString(),
        ),
        'gorgiasUserName': (data['gorgiasUserName'] ?? '').toString(),
        'wordPressUserName': (data['wordPressUserName'] ?? '').toString(),
        // ReachShip credentials - map from Firestore field names
        'reachShipClientId': (data['reachClientIdSand'] ?? '').toString(),
        'reachShipClientSecret': (data['reachSecretSand'] ?? '').toString(),
        'reachShipEnv': 'sandbox',
        // Production credentials (for future use)
        'reachShipProClientId': (data['reachProClientId'] ?? '').toString(),
        'reachShipProSecret': (data['reachProSecret'] ?? '').toString(),
      };

      log(
        '[AdminLogin] Mapped credentials for storage: $creds',
        name: 'AdminLogin',
      );
      // Store in secure storage
      await _storage.saveCredentials(creds);
      log(
        '[AdminLogin] Credentials saved to secure storage',
        name: 'AdminLogin',
      );

      // Log ReachShip credentials for verification
      log(
        '[AdminLogin] ReachShip ClientId: ${creds['reachShipClientId']}',
        name: 'AdminLogin',
      );
      log(
        '[AdminLogin] ReachShip Environment: ${creds['reachShipEnv']}',
        name: 'AdminLogin',
      );

      // Initialize credentials in ApiService
      try {
        await CredentialInitializationService().initializeCredentials();
        log(
          '[AdminLogin] Credentials initialized in ApiService',
          name: 'AdminLogin',
        );
        // Sync push notification token and preferences with the new credentials
        PushNotificationService.instance.syncPreferences().catchError((e) {
          log('[AdminLogin] Failed to sync push preferences: $e', name: 'AdminLogin');
        });
      } catch (e) {
        log(
          '[AdminLogin] Failed to initialize credentials in ApiService: $e',
          name: 'AdminLogin',
          error: e,
        );
      }
      // Store remember me flag
      if (_rememberMe) {
        await _secureStorage.write(key: 'remember_me', value: 'true');
      } else {
        await _secureStorage.delete(key: 'remember_me');
      }
      ToastUtils.showSuccessToast(
        context,
        title: 'Login Successful',
        description: 'Welcome, Admin!',
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomNavScreen()),
      );
    } on FirebaseAuthException catch (e) {
      log(
        '[AdminLogin] FirebaseAuthException: ${e.message ?? e.toString()}',
        name: 'AdminLogin',
        error: e,
      );
      ToastUtils.showErrorToast(
        context,
        title: 'Login Failed',
        description: e.message ?? 'Invalid credentials',
      );
    } catch (e) {
      log('[AdminLogin] Error: $e', name: 'AdminLogin', error: e);
      ToastUtils.showErrorToast(
        context,
        title: 'Credential Error',
        description: e.toString(),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _extractGorgiasSubdomain(String url) {
    // Example: https://profoundaminos.gorgias.com/api/tickets
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    final host = uri.host; // profoundaminos.gorgias.com
    if (host.endsWith('.gorgias.com')) {
      return host.split('.gorgias.com')[0];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Logo
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Center(
                          child: Image.asset(
                            'assets/images/profound_icon.png',
                            height: 72,
                          ),
                        ),
                      ),
                      Text(
                        'Admin Login',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                      CustomTextField(
                        controller: _emailController,
                        // label: 'Email',
                        hintText: 'admin@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Email required'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        // label: 'Password',
                        hintText: 'Enter password',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Password required'
                                    : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            value: _rememberMe,
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                          ),
                          Text('Remember Me', style: AppTextStyles.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: _isLoading ? 'Logging in...' : 'Login',
                        onPressed: _isLoading ? null : _login,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CustomLoadingWidget(text: 'Logging in... Please wait'),
              ),
            ),
        ],
      ),
    );
  }
}
