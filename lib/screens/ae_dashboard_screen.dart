import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import 'complaint_detail_screen.dart';

class AeDashboardScreen extends StatelessWidget {
  const AeDashboardScreen({
    super.key,
    ComplaintService? complaintService,
  }) : _complaintService = complaintService;

  final ComplaintService? _complaintService;

  @override
  Widget build(BuildContext context) {
    final complaintService = _complaintService ?? ComplaintService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AE Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: complaintService.streamActiveComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load complaints: ${snapshot.error}'),
              ),
            );
          }

          final complaints = snapshot.data ?? <ComplaintModel>[];
          if (complaints.isEmpty) {
            return const Center(
              child: Text('No active complaints.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final isResolved = _normalizeStatus(complaint.status) == 'resolved';
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ComplaintDetailScreen(
                          complaintId: complaint.complaintId,
                          complaintService: complaintService,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                complaint.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isResolved
                                      ? const Color(0xFF1B5E20)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (isResolved)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF2E7D32),
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Category: ${complaint.category}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _priorityChip(complaint.priority),
                            _statusChip(complaint.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Created: ${_formatDate(complaint.createdAt)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'N/A';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }

  static Widget _statusChip(String status) {
    final normalized = _normalizeStatus(status);
    Color background;
    Color foreground;

    switch (normalized) {
      case 'resolved':
        background = const Color(0xFFE8F5E9);
        foreground = const Color(0xFF2E7D32);
        break;
      case 'reopened':
        background = const Color(0xFFFFF8E1);
        foreground = const Color(0xFFF57F17);
        break;
      case 'in_progress':
        background = const Color(0xFFE3F2FD);
        foreground = const Color(0xFF1565C0);
        break;
      case 'under_review':
        background = const Color(0xFFEDE7F6);
        foreground = const Color(0xFF4A148C);
        break;
      case 'classified':
      default:
        background = const Color(0xFFF3E5F5);
        foreground = const Color(0xFF6A1B9A);
        break;
    }

    return Chip(
      label: Text(_displayStatus(status)),
      visualDensity: VisualDensity.compact,
      backgroundColor: background,
      labelStyle: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static String _normalizeStatus(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  static String _displayStatus(String status) {
    final normalized = status.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return status;

    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static Widget _priorityChip(String priority) {
    final value = priority.trim().toLowerCase();
    Color background;
    Color foreground;

    if (value == 'high') {
      background = const Color(0xFFFFEBEE);
      foreground = const Color(0xFFC62828);
    } else if (value == 'medium') {
      background = const Color(0xFFFFF3E0);
      foreground = const Color(0xFFEF6C00);
    } else {
      background = const Color(0xFFE8F5E9);
      foreground = const Color(0xFF2E7D32);
    }

    return Chip(
      label: Text(priority),
      visualDensity: VisualDensity.compact,
      backgroundColor: background,
      labelStyle: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
