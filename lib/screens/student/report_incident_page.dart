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

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isPrivate = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
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
        imageUrls = await _uploadImages(userId);
      }

      await FirebaseService.reports.add({
        'userId': userId,
        'userName': user?.name ?? '',
        'subject': _subjectController.text.trim(),
        'description': _descController.text.trim(),
        'imageUrls': imageUrls ?? [],
        'isPrivate': _isPrivate,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim laporan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: const BackButton(),
        title: Text('Laporkan Insiden', style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('DRAFT', style: AppTextStyle.labelLg.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.marginMobile),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gunakan form ini untuk melaporkan insiden atau pelanggaran yang Anda saksikan.',
                      style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Judul Laporan',
                hintText: 'Contoh: Perundungan di koridor',
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul harus diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Deskripsi Kejadian',
                hintText: 'Jelaskan apa yang terjadi, kapan, dan siapa saja yang terlibat...',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Deskripsi harus diisi' : null,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radius2xl),
                border: Border.all(color: AppColors.outlineVariant, width: 2, style: BorderStyle.solid),
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
                                top: 0, right: 0,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
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
                    style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSizes.radius2xl),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixedDim,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, color: AppColors.onSecondaryFixed, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kirim sebagai Pribadi', style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface)),
                        Text('Hanya admin yang dapat melihat', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
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
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 8),
                        Text('Kirim Laporan'),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
