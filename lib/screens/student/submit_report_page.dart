import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';

class SubmitReportPage extends StatefulWidget {
  const SubmitReportPage({super.key});

  @override
  State<SubmitReportPage> createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends State<SubmitReportPage> {
  final _subjectController = TextEditingController();
  final _detailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isPrivate = true;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 70);
    if (files.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(files.map((f) => File(f.path)));
      });
    }
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (file != null) {
      setState(() {
        _selectedImages.add(File(file.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages(String userId) async {
    final urls = <String>[];
    for (int i = 0; i < _selectedImages.length; i++) {
      final file = _selectedImages[i];
      final fileName =
          'reports/$userId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = FirebaseService.storage.ref().child(fileName);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      final userId = user?.id ?? '';

      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploading = true);
        imageUrls = await _uploadImages(userId);
        setState(() => _isUploading = false);
      }

      await FirebaseService.reports.add({
        'userId': userId,
        'userName': user?.name ?? '',
        'subject': _subjectController.text.trim(),
        'description': _detailController.text.trim(),
        'imageUrls': imageUrls ?? [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim laporan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.marginMobile,
                    AppSizes.stackLg,
                    AppSizes.marginMobile,
                    24,
                  ),
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: AppSizes.stackLg),
                    _buildForm(),
                  ],
                ),
              ),
            ),
            _buildSubmitFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.marginMobile),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.close, color: AppColors.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Submit New Record',
              style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              'DRAFT',
              style: AppTextStyle.labelLg.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: const Icon(
              Icons.description,
              color: AppColors.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incident Report',
                  style: AppTextStyle.headlineMd.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your submission helps us maintain a safe and supportive learning environment. Please provide as much detail as possible.',
                  style: AppTextStyle.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Subject'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _subjectController,
          style: AppTextStyle.bodyLg.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'E.g., Disciplinary Incident - Hallway 4',
            hintStyle: AppTextStyle.bodyLg.copyWith(
              color: AppColors.outlineVariant,
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
        ),
        const SizedBox(height: AppSizes.stackLg),
        _buildLabel('Detailed Information'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailController,
          maxLines: 8,
          style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText:
                'Describe the situation in detail, including dates, times, and individuals involved if known...',
            hintStyle: AppTextStyle.bodyMd.copyWith(
              color: AppColors.outlineVariant,
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.all(AppSizes.cardPadding),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius2xl),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius2xl),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius2xl),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Detailed information is required'
              : null,
        ),
        const SizedBox(height: AppSizes.stackLg),
        _buildAttachmentArea(),
        const SizedBox(height: AppSizes.stackLg),
        _buildPrivacyToggle(),
        const SizedBox(height: 96),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: AppTextStyle.labelLg.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildAttachmentArea() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImages[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (_selectedImages.isNotEmpty) const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _selectedImages.isNotEmpty
                ? '${_selectedImages.length} foto dipilih'
                : 'Tambahkan foto bukti',
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryFixedDim,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              color: AppColors.onSecondaryFixed,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit as Private',
                  style: AppTextStyle.titleLg.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Only administrators can view this',
                  style: AppTextStyle.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPrivate,
            onChanged: (v) => setState(() => _isPrivate = v),
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.marginMobile),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _isLoading ? null : _submit,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.brandGradientStart,
                      AppColors.brandGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.onPrimary,
                                  strokeWidth: 2,
                                ),
                              ),
                              if (_isUploading) ...[
                                const SizedBox(width: 12),
                                Text(
                                  'Mengupload foto...',
                                  style: AppTextStyle.titleLg.copyWith(
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Submit',
                                style: AppTextStyle.titleLg.copyWith(
                                  color: AppColors.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.send,
                                color: AppColors.onPrimary,
                                size: 20,
                              ),
                            ],
                          ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: 'By submitting, you agree to the ',
                style: AppTextStyle.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: 'Code of Conduct',
                    style: AppTextStyle.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
