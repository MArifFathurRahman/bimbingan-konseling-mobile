import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_page.dart';
import '../student/student_dashboard_page.dart';
import '../teacher/wali_kelas_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await auth.login(email, password);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.onError, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(auth.error ?? 'Login gagal')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final user = auth.user;
    if (user == null) return;

    Widget destination;
    if (user.isAdmin) {
      destination = const AdminDashboardPage();
    } else if (user.isWaliKelas) {
      destination = const WaliKelasDashboardPage();
    } else {
      destination = const StudentDashboardPage();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTopBar(),
                const SizedBox(height: 32),
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                _buildLoginCard(),
                const SizedBox(height: 48),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.marginMobile,
        vertical: AppSizes.stackMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            'Binusa SafeSpace',
            style: AppTextStyle.headlineMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Text(
          'Selamat Datang',
          style: AppTextStyle.headlineLg.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Silakan masuk ke akun Anda',
          style: AppTextStyle.bodyLg.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.marginMobile),
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      constraints: const BoxConstraints(maxWidth: 448),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Masukkan email',
                hintStyle: AppTextStyle.bodyMd.copyWith(color: AppColors.outlineVariant),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.email_outlined, color: AppColors.outline, size: 20),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email harus diisi';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Masukkan password',
                hintStyle: AppTextStyle.bodyMd.copyWith(color: AppColors.outlineVariant),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.lock_outline, color: AppColors.outline, size: 20),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password harus diisi';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return GestureDetector(
                  onTap: auth.isLoading ? null : _login,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: auth.isLoading ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                              ),
                            )
                          : Text(
                              'Masuk',
                              style: AppTextStyle.titleLg.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: AppTextStyle.labelLg.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.marginMobile,
        vertical: AppSizes.stackLg,
      ),
      color: AppColors.surfaceContainerLow,
      child: Column(
        children: [
          Text(
            'Satu portal login terpadu untuk akses:\nSiswa, Wali Kelas, dan Guru BK.',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user,
                size: 14,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Sistem Keamanan Terenkripsi Binusa',
                style: AppTextStyle.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
