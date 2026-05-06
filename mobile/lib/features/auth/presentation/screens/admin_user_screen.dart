import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../../../core/theme/app_theme.dart';
import '../providers/admin_user_provider.dart';
import '../../data/models/user.dart';

class AdminUserScreen extends ConsumerStatefulWidget {
  const AdminUserScreen({super.key});

  @override
  ConsumerState<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends ConsumerState<AdminUserScreen> {
  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final uIdController = TextEditingController();
    final pinController = TextEditingController();
    String selectedRole = 'STUDENT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: uIdController,
                  decoration: const InputDecoration(
                    labelText: 'University ID / Roll No.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Secret PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                    DropdownMenuItem(
                        value: 'SANITATION_WORKER', child: Text('Sanitation')),
                    DropdownMenuItem(
                        value: 'ELECTRICIAN', child: Text('Electrician')),
                    DropdownMenuItem(
                        value: 'SECURITY', child: Text('Security')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedRole = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              onPressed: () async {
                final success = await ref
                    .read(adminUserNotifierProvider.notifier)
                    .createUser(uIdController.text, pinController.text, selectedRole);

                if (success && mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User created successfully!')));
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ref.read(adminUserNotifierProvider).error ?? 'Error')));
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, WidgetRef ref, User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete ${user.universityId}? This action cannot be undone.'),
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

    if (confirm == true && mounted) {
      final success = await ref
          .read(adminUserNotifierProvider.notifier)
          .deleteUser(user.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUserListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileSpreadsheet),
            tooltip: 'Import CSV',
            onPressed: () async {
              final result = await fp.FilePicker.pickFiles(
                type: fp.FileType.custom,
                allowedExtensions: ['csv'],
              );
              
              if (result != null && result.files.single.path != null) {
                final filePath = result.files.single.path!;
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Uploading CSV...')),
                );
                
                final response = await ref
                    .read(adminUserNotifierProvider.notifier)
                    .importUsersCsv(filePath);
                
                if (context.mounted) {
                  if (response != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${response['message']} (${response['count']} imported)')),
                    );
                  } else {
                    final error = ref.read(adminUserNotifierProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Import failed')),
                    );
                  }
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showAddUserDialog(context, ref),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminUserListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.role == 'ADMIN'
                        ? Colors.purple.withValues(alpha: 0.2)
                        : Colors.blue.withValues(alpha: 0.2),
                    child: Icon(
                      user.role == 'ADMIN' ? LucideIcons.shieldCheck : LucideIcons.user,
                      color: user.role == 'ADMIN' ? Colors.purple : Colors.blue,
                    ),
                  ),
                  title: Text(user.universityId,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Role: ${user.role}'),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                    onPressed: () => _confirmDeleteUser(context, ref, user),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
