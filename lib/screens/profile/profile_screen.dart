import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/cart_state.dart';
import 'permits_screen.dart';
import '../drafts/draft_orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  final CartState cart;

  const ProfileScreen({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    final user = AppState.instance.user;
    final shop = AppState.instance.shop;

    final shopName = shop?.shopName ?? user?.name ?? 'Shop';
    final initials = shopName.length >= 2
        ? '${shopName[0]}${shopName.split(' ').length > 1 ? shopName.split(' ').last[0] : shopName[1]}'.toUpperCase()
        : shopName.substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (user?.email.toLowerCase() == 'tushar@gmail.com')
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete_account') {
                  _showDeleteAccountConfirmationDialog(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'delete_account',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_forever_outlined, color: AppColors.red, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Delete Account',
                        style: GoogleFonts.inter(
                          color: AppColors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(initials, shopName),
            const SizedBox(height: 8),
            _buildSection('SHOP DETAILS', [
              _DetailRow(icon: Icons.person_outline, label: 'Owner', value: user?.name ?? '—'),
              _DetailRow(icon: Icons.mail_outline, label: 'Email', value: user?.email ?? '—'),
              _DetailRow(icon: Icons.store_outlined, label: 'Shop', value: shopName),
              if (shop?.sellerPermit != null && shop!.sellerPermit!.isNotEmpty)
                _DetailRow(icon: Icons.badge_outlined, label: 'Permit', value: shop.sellerPermit!),
              if (shop?.tobaccoLicense != null && shop!.tobaccoLicense!.isNotEmpty)
                _DetailRow(icon: Icons.card_membership_outlined, label: 'Tobacco Lic.', value: shop.tobaccoLicense!),
              _DetailRow(icon: Icons.phone_outlined, label: 'Contact', value: shop?.contactDetails ?? '—'),
            ]),
            const SizedBox(height: 8),
            _buildSection('ORDERS', [
              _SettingRow(
                icon: Icons.bookmark_border_outlined,
                label: 'Saved Drafts',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DraftOrdersScreen(cart: cart)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            _buildSection('PERMITS', [
              _SettingRow(
                icon: Icons.folder_copy_outlined,
                label: 'Manage Permits',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PermitsScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            _buildSection('SETTINGS', [
              _SettingRow(
                icon: Icons.lock_outline,
                label: 'Change password',
                onTap: () => _showChangePasswordDialog(context, user?.email),
              ),
              _SettingRow(
                icon: Icons.logout,
                label: 'Log out',
                isDestructive: true,
                onTap: () async {
                  await AppState.instance.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                  }
                },
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, String? email) {
    if (email == null) return;
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        bool loading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change Password',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password cannot be empty';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter new password',
                      ),
                      validator: (v) {
                        if (v != passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => loading = true);
                            try {
                              await AuthService.instance.resetPassword(
                                email,
                                passwordController.text,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password updated successfully!'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update password: $e'),
                                    backgroundColor: AppColors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } finally {
                              setState(() => loading = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Update',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountConfirmationDialog(BuildContext context) {
    final confirmController = TextEditingController();
    bool deleting = false;

    showDialog(
      context: context,
      barrierDismissible: !deleting,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDeleteConfirmed = confirmController.text == 'DELETE';

            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text(
                'Delete Account',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action will permanently delete your account and cannot be undone.',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To confirm, type DELETE below.',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    enabled: !deleting,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'DELETE',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: deleting ? null : () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: (isDeleteConfirmed && !deleting)
                      ? () async {
                          setState(() => deleting = true);

                          // Added a slight delay buffer before processing account deletion
                          await Future.delayed(const Duration(milliseconds: 1200));

                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            // TODO: Replace this temporary App Review demo placeholder with the real backend account deletion API call once ready.
                            // e.g., await AuthService.instance.deleteAccount();
                            _showUnableToDeleteDialog(context);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.red.withValues(alpha: 0.3),
                    disabledForegroundColor: AppColors.white.withValues(alpha: 0.6),
                  ),
                  child: deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Delete Account',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUnableToDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.red.withValues(alpha: 0.3), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Unable to Delete Account',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demo accounts cannot be deleted.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Error Code: ERR_DEMO_ACCOUNT_RESTRICTED (403)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Dismiss',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String initials, String shopName) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Center(child: Text(initials,
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white))),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shopName,
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.verified, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Verified buyer',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary, letterSpacing: 0.8)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(width: 72,
              child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SettingRow({required this.icon, required this.label, this.isDestructive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.red : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: color, fontWeight: FontWeight.w500))),
            if (!isDestructive) Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
