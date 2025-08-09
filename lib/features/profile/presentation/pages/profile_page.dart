import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/utils/motion_toast.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../widgets/custom_dialog_box.dart';
import '../../../../widgets/shared_appbar.dart';
import '../../../auth/presentation/pages/admin_login_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const SharedAppbar(
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
            // _buildProfileOption(
            //   icon: Iconsax.user_edit_outline,
            //   title: 'Edit Profile',
            //   subtitle: 'Update your personal information',
            //   onTap: () => _showComingSoonDialog(context, 'Edit Profile'),
            // ),
            _buildProfileOption(
              icon: Iconsax.security_safe_outline,
              title: 'Security',
              subtitle: 'Password and authentication',
              onTap: () => _showComingSoonDialog(context, 'Security Settings'),
            ),
            _buildProfileOption(
              icon: Iconsax.notification_outline,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap:
                  () => _showComingSoonDialog(context, 'Notification Settings'),
            ),

            // const SizedBox(height: 25),
            // // Business Section
            // _buildSectionTitle('Business'),
            // const SizedBox(height: 15),
            // _buildProfileOption(
            //   icon: Iconsax.shop_outline,
            //   title: 'Store Settings',
            //   subtitle: 'Manage your WooCommerce store',
            //   onTap: () => _showComingSoonDialog(context, 'Store Settings'),
            // ),
            // _buildProfileOption(
            //   icon: Iconsax.chart_outline,
            //   title: 'Analytics Preferences',
            //   subtitle: 'Customize your dashboard analytics',
            //   onTap:
            //       () => _showComingSoonDialog(context, 'Analytics Preferences'),
            // ),
            // _buildProfileOption(
            //   icon: Iconsax.card_outline,
            //   title: 'Payment Methods',
            //   subtitle: 'Manage payment and billing',
            //   onTap: () => _showComingSoonDialog(context, 'Payment Methods'),
            // ),
            const SizedBox(height: 25),

            // Support Section
            _buildSectionTitle('Support'),
            const SizedBox(height: 15),
            // _buildProfileOption(
            //   icon: Iconsax.message_question_outline,
            //   title: 'Help Center',
            //   subtitle: 'Get help and support',
            //   onTap: () => _showComingSoonDialog(context, 'Help Center'),
            // ),
            _buildProfileOption(
              icon: Iconsax.call_outline,
              title: 'Contact Support',
              subtitle: 'Reach out to our support team',
              onTap: () => _showComingSoonDialog(context, 'Contact Support'),
            ),

            // _buildProfileOption(
            //   icon: Iconsax.document_text_outline,
            //   title: 'Terms & Privacy',
            //   subtitle: 'Read our terms and privacy policy',
            //   onTap: () => _showComingSoonDialog(context, 'Terms & Privacy'),
            // ),
            const SizedBox(height: 25),

            // App Section
            _buildSectionTitle('App'),
            const SizedBox(height: 15),
            // _buildProfileOption(
            //   icon: Iconsax.setting_2_outline,
            //   title: 'App Settings',
            //   subtitle: 'Theme, language, and preferences',
            //   onTap: () => _showComingSoonDialog(context, 'App Settings'),
            // ),
            _buildProfileOption(
              icon: Iconsax.info_circle_outline,
              title: 'About',
              subtitle: 'App version and information',
              onTap: () => _showAboutDialog(context),
            ),

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
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: CircleAvatar(
              backgroundImage: const AssetImage(
                'assets/images/profound_icon.png',
              ),
              radius: 40,
              child: Text(
                auth.currentUser?.email?.substring(0, 1) ?? 'P',
                style: AppTextStyles.h2.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // User Name
          const Text('Profound Aminos', style: AppTextStyles.h3),
          const SizedBox(height: 5),

          // User Email
          Text(
            auth.currentUser?.email ?? 'example@gmail.com',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 15),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Orders', '156'),
              _buildVerticalDivider(),
              _buildStatItem('Revenue', '\$12.5K'),
              _buildVerticalDivider(),
              _buildStatItem('Products', '89'),
            ],
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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondary,
          size: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
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
            const Icon(
              Iconsax.logout_outline,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
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
                Iconsax.info_circle_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
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
                Iconsax.info_circle_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
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
              const SizedBox(height: 8),
              Text('Version: 1.0.0', style: AppTextStyles.caption),
              const SizedBox(height: 8),
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
}
