import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/grievance_report.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/report_action_provider.dart';

class ReportDetailSheet extends ConsumerStatefulWidget {
  final GrievanceReport report;

  const ReportDetailSheet({super.key, required this.report});

  @override
  ConsumerState<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends ConsumerState<ReportDetailSheet> {
  String? _selectedStatus;
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
    _selectedDepartment = widget.report.aiDepartment;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'ADMIN';
    final isOwner = user?.id == widget.report.reporterId;
    final canDelete = isAdmin || isOwner;
    final reportState = ref.watch(reportActionProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Image Header
                    if (widget.report.imageUrl != null &&
                        widget.report.imageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: widget.report.imageUrl!,
                        height: 250,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 250,
                          color: Colors.grey[200],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 250,
                          color: Colors.grey[200],
                          child: const Icon(LucideIcons.imageOff,
                              size: 50, color: Colors.grey),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatusPill(widget.report.status),
                              Text(
                                DateFormat('MMM dd, yyyy - hh:mm a')
                                    .format(widget.report.createdAt.toLocal()),
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (isAdmin &&
                              widget
                                  .report.reporterUniversityId.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.user,
                                      size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reported by: ${widget.report.reporterUniversityId}',
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Department Tag
                          Row(
                            children: [
                              const Icon(LucideIcons.tag,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              const Text('Department Route: ',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                widget.report.aiDepartment,
                                style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // AI Description with Edit Button for Owner
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Issue Description',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor),
                              ),
                              if (isOwner)
                                IconButton(
                                  icon: const Icon(LucideIcons.pencil,
                                      size: 18, color: AppTheme.primaryColor),
                                  onPressed: () =>
                                      _editDescriptionDialog(context, ref),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.report.aiDescription,
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 24),

                          // Map View
                          const Text(
                            'Location',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(widget.report.latitude,
                                      widget.report.longitude),
                                  initialZoom: 16.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.mobile',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(widget.report.latitude,
                                            widget.report.longitude),
                                        width: 80,
                                        height: 80,
                                        child: const Icon(
                                          LucideIcons.mapPin,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Admin Actions (Dropdowns)
                          if (isAdmin) ...[
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text('Admin Controls',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 16),

                            // Department Dropdown
                            const Text('Route to Department:',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedDepartment,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(
                                    value: 'UNKNOWN', child: Text('UNKNOWN')),
                                DropdownMenuItem(
                                    value: 'CIVIL', child: Text('CIVIL')),
                                DropdownMenuItem(
                                    value: 'ELECTRICAL',
                                    child: Text('ELECTRICAL')),
                                DropdownMenuItem(
                                    value: 'ESTATE', child: Text('ESTATE')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedDepartment = val;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Status Dropdown
                            const Text('Report Status:',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(
                                    value: 'LOGGED', child: Text('LOGGED')),
                                DropdownMenuItem(
                                    value: 'ACTION_REQUIRED',
                                    child: Text('ACTION_REQUIRED')),
                                DropdownMenuItem(
                                    value: 'DISPATCHED',
                                    child: Text('DISPATCHED')),
                                DropdownMenuItem(
                                    value: 'RESOLVED', child: Text('RESOLVED')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedStatus = val;
                                });
                              },
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: reportState.isSubmitting
                                    ? null
                                    : () => _applyAdminChanges(context, ref),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: reportState.isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white))
                                    : const Text('Apply Changes',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],

                          if (canDelete) ...[
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: reportState.isSubmitting
                                    ? null
                                    : () => _deleteReport(context, ref),
                                icon: const Icon(LucideIcons.trash2,
                                    color: Colors.red),
                                label: const Text('Delete Report',
                                    style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _applyAdminChanges(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(reportActionProvider.notifier);

    // Check if status changed
    if (_selectedStatus != null && _selectedStatus != widget.report.status) {
      await notifier.updateStatus(widget.report.id, _selectedStatus!);
    }

    // Check if department changed
    if (_selectedDepartment != null &&
        _selectedDepartment != widget.report.aiDepartment) {
      await notifier.updateDetails(widget.report.id,
          department: _selectedDepartment!);
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin changes applied.')));
    }
  }

  void _editDescriptionDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: widget.report.aiDescription);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter specific details about the issue...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              final success = await ref
                  .read(reportActionProvider.notifier)
                  .updateDetails(widget.report.id,
                      description: controller.text);
              if (success && context.mounted) {
                Navigator.pop(context); // Close sheet to show fresh data
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Description updated!')));
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteReport(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text(
            'This action cannot be undone. It will be removed from the database and storage.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await ref
          .read(reportActionProvider.notifier)
          .deleteReport(widget.report.id);
      if (success && context.mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report deleted successfully.')));
      }
    }
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status) {
      case 'LOGGED':
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
