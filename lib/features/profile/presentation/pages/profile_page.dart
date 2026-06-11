import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/core/utils/motion_toast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../widgets/custom_dialog_box.dart';
import '../../../../widgets/shared_appbar.dart';
import '../../../auth/presentation/pages/admin_login_screen.dart';
import '../../../../core/services/credential_initialization_service.dart';
import '../../../../core/services/firestore_credentials_service.dart';
import '../../../analytics/bloc/analytics_bloc.dart';
import '../../../analytics/bloc/analytics_event.dart';
import '../../../analytics/bloc/analytics_state.dart';
import 'credential_set_up_screen.dart';
import 'notification_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Fetch analytics data when the profile page loads
    context.read<AnalyticsBloc>().add(FetchAnalytics(0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: SharedAppbar(
        title: 'Profile',
        backgroundColor: AppColors.backgroundDark,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 30),

            // Account Section
            _buildSectionTitle('Account'),
            const SizedBox(height: 15),

            _buildProfileOption(
              icon: Icons.security_outlined,
              title: 'Security',
              subtitle: 'Manage your credentials.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return SetupScreen();
                    },
                  ),
                );
              },
            ),
             _buildProfileOption(
              icon: Icons.notification_important_outlined,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsPage(),
                  ),
                );
              },
            ),

            // const SizedBox(height: 25),
            //
            // _buildProfileOption(
            //   icon: Iconsax.message_outline,
            //   title: 'Debug Gorgias Credentials',
            //   subtitle: 'Test and debug Gorgias authentication',
            //   onTap: () => _debugGorgiasCredentials(context),
            // ),
            // _buildProfileOption(
            //   icon: Iconsax.refresh_outline,
            //   title: 'Refresh Gorgias Credentials',
            //   subtitle: 'Reload Gorgias credentials from storage',
            //   onTap: () => _refreshGorgiasCredentials(context),
            // ),
            const SizedBox(height: 25),

            // Credentials Management Section
            _buildSectionTitle('Credentials Management'),
            const SizedBox(height: 15),
            _buildProfileOption(
              icon: Icons.cloud_upload_outlined,
              title: 'Upload Credentials to Cloud',
              subtitle: 'Backup your credentials to Firestore',
              onTap: () => _uploadCredentialsToFirestore(context),
            ),
            _buildProfileOption(
              icon: Icons.cloud_download_outlined,
              title: 'Download Credentials from Cloud',
              subtitle: 'Restore your credentials from Firestore',
              onTap: () => _downloadCredentialsFromFirestore(context),
            ),
            _buildProfileOption(
              icon: Icons.cloud_outlined,
              title: 'View Cloud Credentials Info',
              subtitle: 'Check your Firestore credentials status',
              onTap: () => _viewCredentialsInfo(context),
            ),

            const SizedBox(height: 25),

            // App Section
            _buildSectionTitle('App'),
            const SizedBox(height: 15),
            _buildProfileOption(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App version and information',
              onTap: () => _showAboutDialog(context),
            ),
            _buildThemeToggleOption(),

            const SizedBox(height: 30),

            // Logout Button
            _buildLogoutButton(context),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    FirebaseAuth auth = FirebaseAuth.instance;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: CircleAvatar(
              backgroundImage: AssetImage(
                'assets/images/profound_icon.png',
              ),
              radius: 40,
              child: Text(
                auth.currentUser?.email?.substring(0, 1) ?? 'P',
                style: AppTextStyles.h2.copyWith(color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 15),

          // User Name
          Text('Profound Aminos', style: AppTextStyles.h3),
          SizedBox(height: 5),

          // User Email
          Text(
            auth.currentUser?.email ?? 'example@gmail.com',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 15),

          // Stats Row
          BlocBuilder<AnalyticsBloc, AnalyticsState>(
            builder: (context, state) {
              String orderCount = '-';
              String revenue = '-';
              String productCount = '-';

              if (state is AnalyticsLoaded) {
                orderCount = state.totalOrderCount.toString();
                // Format revenue properly
                if (state.revenue >= 1000000) {
                  revenue = '\$${(state.revenue / 1000000).toStringAsFixed(2)}M';
                } else if (state.revenue >= 1000) {
                  revenue = '\$${(state.revenue / 1000).toStringAsFixed(1)}K';
                } else {
                  revenue = '\$${state.revenue.toStringAsFixed(0)}';
                }
                productCount = state.totalProductCount.toString();
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Orders', orderCount),
                  _buildVerticalDivider(),
                  _buildStatItem('Revenue', revenue),
                  _buildVerticalDivider(),
                  _buildStatItem('Products', productCount),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: AppColors.border);
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.h4.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondary,
          size: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildThemeToggleOption() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDarkMode = themeMode == ThemeMode.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            onTap: () {
              ThemeManager.toggleTheme();
            },
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            title: Text(
              isDarkMode ? 'Dark Mode' : 'Light Mode',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isDarkMode ? 'Dark theme is enabled' : 'Light theme is enabled',
              style: AppTextStyles.caption,
            ),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                ThemeManager.toggleTheme();
              },
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.3),
              inactiveThumbColor: AppColors.textSecondary,
              inactiveTrackColor: AppColors.textSecondary.withOpacity(0.3),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: TextButton(
        onPressed: () => _showLogoutDialog(context),
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_outlined,
              color: AppColors.error,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: 'Logout Confirmation',
          message:
              'Are you sure you want to logout? You will need to sign in again to access your account.',
          onNegativePressed: () {
            Navigator.of(context).pop();
          },
          onPositivePressed: () {
            FirebaseAuth.instance
                .signOut()
                .then((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminLoginPage(),
                    ),
                  );
                  ToastUtils.showSuccessToast(
                    context,
                    title: 'Logout',
                    description: 'Logged out successfully',
                  );
                })
                .catchError((error) {
                  ToastUtils.showSuccessToast(
                    context,
                    title: 'Logout Failed',
                    description: 'Logout failed: $error',
                  );
                });
          },
        );
      },
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: 10),
              Text('Coming Soon', style: AppTextStyles.h4),
            ],
          ),
          content: Text(
            '$feature feature is coming soon! Stay tuned for updates.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }




  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: 10),
              Text('About App', style: AppTextStyles.h4),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WooCommerce Management App',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text('Version: 1.0.0', style: AppTextStyles.caption),
              SizedBox(height: 8),
              Text(
                'A comprehensive solution for managing your WooCommerce store, analytics, and customer support.',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Firestore Credentials Management Methods
  Future<void> _uploadCredentialsToFirestore(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Uploading credentials to cloud...');

      final firestoreService = FirestoreCredentialsService();
      await firestoreService.uploadCredentialsToFirestore();

      Navigator.of(context).pop(); // Close loading dialog

      _showSuccessDialog(
        context,
        'Success',
        'Credentials have been successfully uploaded to Firestore.',
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(
        context,
        'Upload Failed',
        'Failed to upload credentials to Firestore: ${e.toString()}',
      );
    }
  }

  Future<void> _downloadCredentialsFromFirestore(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Downloading credentials from cloud...');

      final firestoreService = FirestoreCredentialsService();
      await firestoreService.downloadCredentialsFromFirestore();

      // Reinitialize credentials after download
      await CredentialInitializationService().initializeCredentials();

      Navigator.of(context).pop(); // Close loading dialog

      _showSuccessDialog(
        context,
        'Success',
        'Credentials have been successfully downloaded from Firestore and applied.',
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(
        context,
        'Download Failed',
        'Failed to download credentials from Firestore: ${e.toString()}',
      );
    }
  }

  Future<void> _viewCredentialsInfo(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Checking cloud credentials...');

      final firestoreService = FirestoreCredentialsService();
      final info = await firestoreService.getCredentialsInfo();

      Navigator.of(context).pop(); // Close loading dialog

      if (info == null) {
        _showInfoDialog(
          context,
          'No Cloud Credentials',
          'No credentials found in Firestore for your account.',
        );
        return;
      }

      final hasCredentials = info['hasCredentials'] ?? false;
      final lastUpdated = info['lastUpdated'];
      final credentialKeys = List<String>.from(info['credentialKeys'] ?? []);

      String message =
          hasCredentials
              ? 'You have credentials stored in Firestore.\n\n'
              : 'No credentials found in Firestore.\n\n';

      if (lastUpdated != null) {
        message += 'Last updated: ${lastUpdated.toDate()}\n\n';
      }

      if (credentialKeys.isNotEmpty) {
        message += 'Available credentials:\n${credentialKeys.join(', ')}';
      }

      _showInfoDialog(context, 'Cloud Credentials Info', message);
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(
        context,
        'Info Failed',
        'Failed to get credentials info from Firestore: ${e.toString()}',
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
              const SizedBox(width: 20),
              Expanded(child: Text(message, style: AppTextStyles.bodyMedium)),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_outlined, color: Colors.green, size: 24),
              SizedBox(width: 10),
              Text(title, style: AppTextStyles.h4),
            ],
          ),
          content: Text(message, style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(title, style: AppTextStyles.h4),
            ],
          ),
          content: Text(message, style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
              SizedBox(width: 10),
              Text(title, style: AppTextStyles.h4),
            ],
          ),
          content: Text(message, style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
