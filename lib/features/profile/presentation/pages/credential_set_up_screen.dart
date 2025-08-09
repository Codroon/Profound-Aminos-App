import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/core/utils/motion_toast.dart';
import 'package:woo_management_app/widgets/custom_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/shared_appbar.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../../home/presentation/pages/bottom_nav_page.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final creds = <String, String>{};
  bool _credentialsTested = false;

  void _onTestAndSave(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _credentialsTested = false;
      context.read<AuthBloc>().add(TestCredentials(Map.from(creds)));
    }
  }

  Widget _buildField(String label, String keyName, {bool obscure = false}) {
    return TextFormField(
      onTapOutside: (_) {
        FocusScope.of(context).unfocus();
      },

      decoration: InputDecoration(
        labelText: label,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),

        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
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
                    physics: const BouncingScrollPhysics(),
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
}
