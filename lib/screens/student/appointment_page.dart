import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../models/counseling_model.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/section_title.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  int _currentNav = 1;

  final _appointments = [
    Appointment(
      id: '1',
      title: 'Mental Wellness Check-in',
      description: 'Routine counseling session',
      counselorName: 'Ms. Sarah Jenkins',
      counselorImage: '',
      date: DateTime.now().add(const Duration(days: 1)),
      time: '10:30 AM',
      room: 'Room 402',
      status: 'upcoming',
    ),
    Appointment(
      id: '2',
      title: 'Academic Guidance',
      description: 'Discuss academic progress',
      counselorName: 'Pak Ahmad',
      counselorImage: '',
      date: DateTime.now().add(const Duration(days: 3)),
      time: '02:00 PM',
      room: 'Room 105',
      status: 'upcoming',
    ),
    Appointment(
      id: '3',
      title: 'Follow-up Session',
      description: 'Follow-up from last session',
      counselorName: 'Bu Dewi',
      counselorImage: '',
      date: DateTime.now().subtract(const Duration(days: 5)),
      time: '09:00 AM',
      room: 'Room 402',
      status: 'completed',
    ),
  ];

  String _formatDate(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff == 1) return 'Tomorrow';
    if (diff == 0) return 'Today';
    return '${date.day}/${date.month}/${date.year}';
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
                  100,
                ),
                children: [
                  Text(
                    'Appointments',
                    style: AppTextStyle.headlineLg.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSizes.stackLg),
                  const SectionTitle(title: 'Upcoming'),
                  const SizedBox(height: AppSizes.stackMd),
                  ..._appointments
                      .where((a) => a.status == 'upcoming')
                      .map(_buildAppointmentCard),
                  if (_appointments
                      .where((a) => a.status == 'upcoming')
                      .isNotEmpty)
                    const SizedBox(height: AppSizes.stackLg),
                  const SectionTitle(title: 'History'),
                  const SizedBox(height: AppSizes.stackMd),
                  ..._appointments
                      .where((a) => a.status == 'completed')
                      .map(_buildAppointmentCard),
                ],
              ),
            ),
            _buildBottomNav(),
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
            'Appointments',
            style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isUpcoming = appointment.status == 'upcoming';

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  appointment.title,
                  style: AppTextStyle.titleLg.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? AppColors.secondaryContainer
                      : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  _formatDate(appointment.date),
                  style: AppTextStyle.labelMd.copyWith(
                    color: isUpcoming
                        ? AppColors.onSecondaryContainer
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appointment.description,
            style: AppTextStyle.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 14, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      appointment.counselorName,
                      style: AppTextStyle.labelLg.copyWith(
                        color: AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text(
                    appointment.time,
                    style: AppTextStyle.labelMd.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.room, size: 14, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text(
                    appointment.room,
                    style: AppTextStyle.labelMd.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
            ],
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joining session...')),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Join Session',
                    style: AppTextStyle.labelLg.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNav,
      items: const [
        NavItem(icon: Icons.dashboard, label: 'Dashboard', route: '/student/dashboard'),
        NavItem(icon: Icons.forum, label: 'Counseling', route: '/student/counseling'),
        NavItem(icon: Icons.person, label: 'Profile', route: '/student/profile'),
      ],
      onTap: (i) {
        if (i == 0) {
          Navigator.pop(context);
        } else if (i == 2) {
          setState(() => _currentNav = i);
        } else {
          setState(() => _currentNav = i);
        }
      },
    );
  }
}
