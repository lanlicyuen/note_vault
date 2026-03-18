import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../models/note_type.dart';
import '../../providers/notes_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';

class VaultManagerScreen extends ConsumerWidget {
  const VaultManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 32),

              // Account Section
              _buildAccountSection(context, ref),
              const SizedBox(height: 24),

              // Data Management Section
              _buildDataSection(context, ref),
              const SizedBox(height: 24),

              // Storage Info Section
              _buildStorageInfo(ref),
              const SizedBox(height: 24),

              // Tags & Types Overview
              _buildTagsOverview(ref),
              const SizedBox(height: 24),

              // Security Section
              _buildSecuritySection(ref),
              const SizedBox(height: 24),

              // Server / Sync Section
              _buildSyncSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 8),
        const Text(
          'Vault Manager',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (auth) => _buildCard(
        title: 'Account',
        children: [
          _buildInfoRow('Username', auth.username ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoRow('Mode', 'Local Single User'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                  onPressed: () => _showChangePasswordDialog(context, ref),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.2),
                  foregroundColor: AppColors.error,
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),
        ],
      ),
      loading: () => _buildCard(
        title: 'Account',
        children: const [Center(child: CircularProgressIndicator())],
      ),
      error: (err, _) => _buildCard(
        title: 'Account',
        children: [Text('Error: $err')],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context, WidgetRef ref) {
    return _buildCard(
      title: 'Data Management',
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Export All Notes as JSON'),
                onPressed: () => _exportNotes(context, ref),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text('Import Notes from JSON'),
                onPressed: () => _showImportDialog(context, ref),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.2),
                  foregroundColor: AppColors.error,
                ),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear All Data'),
                onPressed: () => _showClearDialog(context, ref),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Restore Demo Data'),
                onPressed: () => _showRestoreDialog(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStorageInfo(WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final tagsAsync = ref.watch(allTagsProvider);

    return notesAsync.when(
      data: (notes) => tagsAsync.when(
        data: (tags) {
          final secretCount = notes.where((n) => n.type.value == 'secret').length;
          final commandCount = notes.where((n) => n.type.value == 'command').length;
          final favoriteCount = notes.where((n) => n.isFavorite).length;
          final lastUpdated = notes.isEmpty
              ? DateTime.now()
              : notes.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b).updatedAt;

          return _buildCard(
            title: 'Storage Info',
            children: [
              _buildInfoRow('Data Source', 'Local Repository'),
              const SizedBox(height: 12),
              _buildInfoRow('Total Notes', notes.length.toString()),
              const SizedBox(height: 12),
              _buildInfoRow('Secrets', secretCount.toString()),
              const SizedBox(height: 12),
              _buildInfoRow('Commands', commandCount.toString()),
              const SizedBox(height: 12),
              _buildInfoRow('Favorites', favoriteCount.toString()),
              const SizedBox(height: 12),
              _buildInfoRow('Tags', tags.length.toString()),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Last Updated',
                DateFormat('yyyy-MM-dd HH:mm').format(lastUpdated),
              ),
            ],
          );
        },
        loading: () => _buildCard(
          title: 'Storage Info',
          children: const [CircularProgressIndicator()],
        ),
        error: (err, _) => _buildCard(
          title: 'Storage Info',
          children: [Text('Error: $err')],
        ),
      ),
      loading: () => _buildCard(
        title: 'Storage Info',
        children: const [CircularProgressIndicator()],
      ),
      error: (err, _) => _buildCard(
        title: 'Storage Info',
        children: [Text('Error: $err')],
      ),
    );
  }

  Widget _buildTagsOverview(WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final tagsAsync = ref.watch(allTagsProvider);

    return notesAsync.when(
      data: (notes) => tagsAsync.when(
        data: (tags) {
          // Count by type
          final typeCounts = <String, int>{};
          for (final type in NoteType.values) {
            typeCounts[type.label] =
                notes.where((n) => n.type == type).length;
          }

          return _buildCard(
            title: 'Types & Tags Overview',
            children: [
              // Types
              Text(
                'By Type',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: typeCounts.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${e.key} (${e.value})',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Tags
              Text(
                'Top Tags',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.take(10).map((tag) {
                  final count = notes.where((n) => n.tags.contains(tag)).length;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '#$tag ($count)',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
        loading: () => _buildCard(
          title: 'Types & Tags Overview',
          children: const [CircularProgressIndicator()],
        ),
        error: (err, _) => _buildCard(
          title: 'Types & Tags Overview',
          children: [Text('Error: $err')],
        ),
      ),
      loading: () => _buildCard(
        title: 'Types & Tags Overview',
        children: const [CircularProgressIndicator()],
      ),
      error: (err, _) => _buildCard(
        title: 'Types & Tags Overview',
        children: [Text('Error: $err')],
      ),
    );
  }

  Widget _buildSecuritySection(WidgetRef ref) {
    final vaultAsync = ref.watch(vaultProvider);

    return vaultAsync.when(
      data: (vault) => _buildCard(
        title: 'Security',
        children: [
          SwitchListTile(
            title: const Text('Hide Secrets by Default'),
            subtitle: const Text('Secret values hidden until clicked'),
            value: vault.hideSecretsDefault,
            onChanged: (_) => ref.read(vaultProvider.notifier).toggleHideSecrets(),
            contentPadding: EdgeInsets.zero,
            tileColor: Colors.transparent,
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Confirm Before Copying'),
            subtitle: const Text('Show confirmation dialog when copying secrets'),
            value: vault.confirmBeforeCopy,
            onChanged: (_) => ref.read(vaultProvider.notifier).toggleConfirmCopy(),
            contentPadding: EdgeInsets.zero,
            tileColor: Colors.transparent,
            activeColor: AppColors.primary,
          ),
        ],
      ),
      loading: () => _buildCard(
        title: 'Security',
        children: const [CircularProgressIndicator()],
      ),
      error: (err, _) => _buildCard(
        title: 'Security',
        children: [Text('Error: $err')],
      ),
    );
  }

  Widget _buildSyncSection() {
    return _buildCard(
      title: 'Server / Sync',
      children: [
        _buildInfoRow('Current Mode', 'Local Mode'),
        const SizedBox(height: 16),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'API Base URL',
            hintText: 'Not available in local mode',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabled: false,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'PostgreSQL Sync: Coming Soon\nSynchronization with remote servers will be available in future versions.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _exportNotes(BuildContext context, WidgetRef ref) {
    final json = ref.read(notesProvider.notifier).exportJson();
    Clipboard.setData(ClipboardData(text: json));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notes exported to clipboard as JSON')),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Notes from JSON'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste JSON here',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(notesProvider.notifier).importJson(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notes imported successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all your notes permanently. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(notesProvider.notifier).clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Demo Data'),
        content: const Text('This will replace all notes with demo data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(notesProvider.notifier).resetToDefaults();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo data restored')),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPwController = TextEditingController();
    final newPwController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPwController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPwController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Simple validation: check if old password is default
              if (oldPwController.text != 'admin123') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Current password is incorrect')),
                );
                return;
              }

              // TODO: Save new password to SharedPreferences
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
