import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/utils/motion_toast.dart';
import 'package:woo_management_app/widgets/custom_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/shared_appbar.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../../home/presentation/pages/bottom_nav_page.dart';
import '../../../../core/services/firestore_credentials_service.dart';
import '../../../../core/services/crediential_storage_service.dart';
import '../../../../core/services/push_notification_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final creds = <String, String>{};
  bool _credentialsTested = false;
  final FirestoreCredentialsService _firestoreService =
      FirestoreCredentialsService();

  void _onTestAndSave(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _credentialsTested = false;
      context.read<AuthBloc>().add(TestCredentials(Map.from(creds)));
    }
  }

  Widget _buildField(String label, String keyName, {bool obscure = false}) {
    return TextFormField(
      initialValue: creds[keyName],
      onTapOutside: (_) {
        FocusScope.of(context).unfocus();
      },

      decoration: InputDecoration(
        labelText: label,
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),

        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        errorStyle: TextStyle(color: AppColors.error, fontSize: 12),
      ),
      obscureText: obscure,
      onSaved: (val) => creds[keyName] = val ?? '',
      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),

      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            if (!_credentialsTested) {
              // After test, now save credentials
              _credentialsTested = true;
              context.read<AuthBloc>().add(SubmitCredentials(Map.from(creds)));
            } else {
              // Sync push notification token and preferences
              PushNotificationService.instance.syncPreferences().catchError((e) {
                debugPrint('[SetupScreen] Failed to sync push preferences: $e');
              });
              // After save, show snackbar and navigate
              ToastUtils.showSuccessToast(
                context,
                title: 'Authentication',
                description: 'Credentials saved successfully!',
              );

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BottomNavScreen()),
                (route) => false,
              );
            }
          } else if (state is AuthFailure) {
            ToastUtils.showErrorToast(
              context,
              title: 'Failure',
              description: state.message,
            );
          }
        },
        child: Scaffold(
          appBar: SharedAppbar(title: 'Setup Credentials'),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField('WooCommerce Key', 'wooKey'),
                        _buildField('WooCommerce Secret', 'wooSecret'),
                        _buildField('WooCommerce URL', 'wooUrl'),
                        _buildField('WordPress Username', 'wpUser'),
                        _buildField('WordPress App Password', 'wpPass'),
                        _buildField('Gorgias API Token', 'gorgiasToken'),
                        _buildField(
                          'Gorgias Subdomain (e.g. yourbrand)',
                          'gorgiasSub',
                        ),
                        _buildField('Gorgias Username', 'gorgiasUserName'),

                        // ReachShip Fields
                        SizedBox(height: 20),
                        Text(
                          'ReachShip Credentials',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildField('ReachShip Client ID', 'reachProClientId'),
                        _buildField(
                          'ReachShip Client Secret',
                          'reachProSecret',
                          obscure: true,
                        ),
                        _buildField(
                          'ReachShip Client ID (Sand)',
                          'reachClientIdSand',
                        ),
                        _buildField(
                          'ReachShip Secret (Sand)',
                          'reachSecretSand',
                          obscure: true,
                        ),
                        _buildField('ReachShip Environment', 'reachShipEnv'),

                        SizedBox(height: 30),

                        // Firestore Options
                        Text(
                          'Cloud Backup Options',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () => _downloadFromFirestore(context),
                                icon: Icon(
                                  Iconsax.cloud_drizzle_bold,
                                  size: 18,
                                ),
                                label: Text('Load from Cloud'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () => _uploadToFirestore(context),
                                icon: Icon(Iconsax.cloud_add_bold, size: 18),
                                label: Text('Save to Cloud'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        CustomButton(
                          text: isLoading ? 'Loading...' : 'Test & Save',
                          onPressed:
                              isLoading ? null : () => _onTestAndSave(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFromFirestore(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Loading credentials from cloud...');

      await _firestoreService.downloadCredentialsFromFirestore();

      Navigator.of(context).pop(); // Close loading dialog

      // Reload the form with downloaded credentials
      final storage = CredentialStorageService();
      final downloadedCreds = await storage.getCredentials();

      setState(() {
        creds.clear();
        downloadedCreds.forEach((key, value) {
          if (value != null) creds[key] = value;
        });
      });

      // Sync push notification preferences
      PushNotificationService.instance.syncPreferences().catchError((e) {
        debugPrint('[SetupScreen] Failed to sync push preferences: $e');
      });

      ToastUtils.showSuccessToast(
        context,
        title: 'Success',
        description: 'Credentials loaded from cloud successfully!',
      );

      // Rebuild form with new values
      _formKey.currentState?.reset();
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ToastUtils.showErrorToast(
        context,
        title: 'Download Failed',
        description: 'Failed to load credentials from cloud: ${e.toString()}',
      );
    }
  }

  Future<void> _uploadToFirestore(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      ToastUtils.showErrorToast(
        context,
        title: 'Validation Error',
        description: 'Please fill in all required fields before uploading.',
      );
      return;
    }

    _formKey.currentState!.save();

    try {
      _showLoadingDialog(context, 'Saving credentials to cloud...');

      // Save locally first
      final storage = CredentialStorageService();
      await storage.saveCredentials(creds);

      // Then upload to Firestore
      await _firestoreService.uploadCredentialsToFirestore();

      Navigator.of(context).pop(); // Close loading dialog

      // Sync push notification preferences
      PushNotificationService.instance.syncPreferences().catchError((e) {
        debugPrint('[SetupScreen] Failed to sync push preferences: $e');
      });

      ToastUtils.showSuccessToast(
        context,
        title: 'Success',
        description: 'Credentials saved to cloud successfully!',
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ToastUtils.showErrorToast(
        context,
        title: 'Upload Failed',
        description: 'Failed to save credentials to cloud: ${e.toString()}',
      );
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
