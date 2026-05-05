import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/workforce_provider.dart';
import '../../data/models/grievance_report.dart';
import '../widgets/report_detail_sheet.dart';

class WorkforceQueueScreen extends ConsumerWidget {
  const WorkforceQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(workforceQueueProvider);
    final actionState = ref.watch(workforceNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departmental Tasks'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref.invalidate(workforceQueueProvider),
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: queueAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.clipboardCheck, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('All clear! No pending tasks.',
                      style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(workforceQueueProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = reports[index];
                return _TaskCard(report: report);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading queue: $err'),
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final GrievanceReport report;
  const _TaskCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ReportDetailSheet(report: report),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: report.imageUrl != null && report.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: report.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(LucideIcons.image),
                      ),
              ),
              const SizedBox(width: 16),
              // Task Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.aiDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to view on map',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reported: ${DateFormat('MMM dd, hh:mm a').format(report.createdAt.toLocal())}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Resolve Button
              Column(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.checkCircle2,
                        color: AppTheme.primaryColor),
                    onPressed: () => _confirmResolve(context, ref),
                  ),
                  const Text('Resolve',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmResolve(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Task?'),
        content: const Text(
            'Confirm that you have fixed this issue. This will move it to the RESOLVED state.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resolve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref
          .read(workforceNotifierProvider.notifier)
          .resolveReport(report.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task marked as RESOLVED!')),
        );
      }
    }
  }
}
