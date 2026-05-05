import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/grievance_provider.dart';
import '../providers/report_action_provider.dart';
import '../widgets/report_detail_sheet.dart';
import 'package:intl/intl.dart';

class AdminFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? filter) {
    state = filter;
  }
}

final adminFilterProvider = NotifierProvider<AdminFilterNotifier, String?>(() {
  return AdminFilterNotifier();
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Default coordinates for Guwhati University (approx) if location isn't instantly available
  final Map<String, double> _currentCoords = {'lat': 26.1552, 'lon': 91.6625};

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final reportsAsync = ref.watch(nearbyReportsProvider(_currentCoords));
    final reportState = ref.watch(reportActionProvider);
    final currentFilter = ref.watch(adminFilterProvider);

    // Listen for upload errors
    ref.listen<ReportState>(reportActionProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      body: Column(
        children: [
          // 1. Top Header Area
          Container(
            padding:
                const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hi there 👋',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.universityId ?? 'Student',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (user?.role == 'ADMIN')
                  InkWell(
                    onTap: () => context.push('/admin/users'),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.users, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('MANAGE USERS',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  icon: const Icon(LucideIcons.logOut, color: Colors.white),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),

          // 2. The Hero Action Card
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: InkWell(
                onTap: reportState.isSubmitting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await ref
                            .read(reportActionProvider.notifier)
                            .createReport();
                        if (success && mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Report submitted! AI is analyzing it.')),
                          );
                        }
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: reportState.isSubmitting
                            ? const SizedBox(
                                height: 40,
                                width: 40,
                                child: CircularProgressIndicator(
                                    color: AppTheme.primaryColor))
                            : const Icon(
                                LucideIcons.camera,
                                color: AppTheme.primaryColor,
                                size: 40,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        reportState.isSubmitting
                            ? 'Uploading...'
                            : 'Tap to report',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Report waste instantly with AI analysis',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. The List Section (Dynamic Data)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user?.role == 'ADMIN'
                            ? 'All Recent Reports'
                            : 'Nearby Reports',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () => ref.invalidate(nearbyReportsProvider),
                      ),
                    ],
                  ),
                  if (user?.role == 'ADMIN')
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', null, currentFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('LOGGED', 'LOGGED', currentFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('ACTION REQUIRED', 'ACTION_REQUIRED', currentFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('DISPATCHED', 'DISPATCHED', currentFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip('RESOLVED', 'RESOLVED', currentFilter),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: reportsAsync.when(
                      data: (reports) {
                        var filteredReports = reports;
                        if (user?.role == 'ADMIN' && currentFilter != null) {
                          filteredReports = reports.where((r) => r.status == currentFilter).toList();
                        }

                        if (filteredReports.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.checkCircle,
                                    size: 64, color: AppTheme.primaryColor),
                                SizedBox(height: 16),
                                Text('All clear! No reports found.',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(nearbyReportsProvider);
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24, top: 8),
                            itemCount: filteredReports.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              return InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        ReportDetailSheet(report: report),
                                  );
                                },
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Image Thumbnail (Left Side)
                                        if (report.imageUrl != null &&
                                            report.imageUrl!.isNotEmpty)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: report.imageUrl!,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2)),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                    LucideIcons.imageOff,
                                                    color: Colors.grey),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(LucideIcons.image,
                                                color: Colors.grey),
                                          ),
                                        const SizedBox(width: 16),

                                        // Content (Right Side)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'ID: ${report.id.substring(0, 8)}...',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  _buildStatusPill(
                                                      report.status),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                report.aiDescription,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  const Icon(LucideIcons.mapPin,
                                                      size: 12,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 11),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    DateFormat(
                                                            'MMM dd, hh:mm a')
                                                        .format(report.createdAt
                                                            .toLocal()), // Timezone Fix
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, String? currentFilter) {
    final isSelected = currentFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      onSelected: (selected) {
        if (selected) {
          ref.read(adminFilterProvider.notifier).state = value;
        }
      },
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status) {
      case 'LOGGED': // Matches backend enum
      case 'REPORTED':
        color = Colors.orange;
        break;
      case 'ACTION_REQUIRED':
        color = Colors.red;
        break;
      case 'DISPATCHED':
        color = Colors.blue;
        break;
      case 'RESOLVED':
        color = AppTheme.primaryColor;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
