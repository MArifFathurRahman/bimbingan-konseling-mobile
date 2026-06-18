import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../models/chat_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/profile_avatar.dart';

class CounselingBookingPage extends StatefulWidget {
  const CounselingBookingPage({super.key});

  @override
  State<CounselingBookingPage> createState() => _CounselingBookingPageState();
}

class _CounselingBookingPageState extends State<CounselingBookingPage> {
  final _topicController = TextEditingController();
  Counselor? _selectedCounselor;
  DateTime? _selectedDate;
  String? _selectedTime;

  final _timeSlots = ['09:00', '10:00', '11:00', '13:00', '14:00', '15:00'];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedCounselor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih konselor terlebih dahulu')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal konseling')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih waktu konseling')),
      );
      return;
    }
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi tujuan konseling')),
      );
      return;
    }

    AppDialog.info(
      context: context,
      title: 'Booking Berhasil',
      message:
          'Konseling dengan ${_selectedCounselor!.name} pada ${_selectedDate!.day}/${_selectedDate!.month} pukul $_selectedTime berhasil dijadwalkan.',
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.marginMobile,
                  AppSizes.stackLg,
                  AppSizes.marginMobile,
                  24,
                ),
                children: [
                  _buildCounselorSelection(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildDatePicker(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildTimeSlotGrid(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildTopicField(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildSubmitButton(),
                ],
              ),
            ),
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
            child: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text(
            'Booking Konseling',
            style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildCounselorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Pilih Konselor',
            style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.users
              .where('role', isEqualTo: 'admin')
              .snapshots(),
          builder: (context, snapshot) {
            final counselors = snapshot.data?.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Counselor.fromMap(data, doc.id);
            }).toList();

            if (counselors == null || counselors.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada konselor tersedia',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: counselors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final counselor = counselors[i];
                  final isSelected =
                      _selectedCounselor?.id == counselor.id;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCounselor = counselor),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceContainerLowest,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radius2xl),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: AppColors.shadowColor
                                      .withValues(alpha: 0.08),
                                  blurRadius: 20,
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ProfileAvatar(
                            name: counselor.name,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            counselor.name,
                            style: AppTextStyle.labelLg.copyWith(
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            counselor.role,
                            style: AppTextStyle.labelMd.copyWith(
                              color: isSelected
                                  ? AppColors.onPrimary
                                      .withValues(alpha: 0.8)
                                  : AppColors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Pilih Tanggal',
            style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final date = await AppDialog.pickDate(context, _selectedDate);
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day} ${_getMonth(_selectedDate!.month)} ${_selectedDate!.year}'
                        : 'Pilih tanggal konseling',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: _selectedDate != null
                          ? AppColors.onSurface
                          : AppColors.outline,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.outline,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Pilih Waktu',
            style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_timeSlots.length, (i) {
            final time = _timeSlots[i];
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = time),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                  ),
                ),
                child: Text(
                  time,
                  style: AppTextStyle.labelLg.copyWith(
                    color:
                        isSelected ? AppColors.onPrimary : AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTopicField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Tujuan Konseling',
            style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
          ),
        ),
        TextField(
          controller: _topicController,
          maxLines: 3,
          style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Tujuan konseling...',
            hintStyle: AppTextStyle.bodyMd.copyWith(color: AppColors.outline),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.all(AppSizes.cardPadding),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius2xl),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius2xl),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius2xl),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
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
          child: Text(
            'Konfirmasi Booking',
            style: AppTextStyle.titleLg.copyWith(color: AppColors.onPrimary),
          ),
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }
}
