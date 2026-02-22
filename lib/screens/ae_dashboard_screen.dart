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
      ),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: complaintService.streamActiveComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load complaints: ${snapshot.error}'),
            );
          }

          final complaints = snapshot.data ?? <ComplaintModel>[];
          if (complaints.isEmpty) {
            return const Center(
              child: Text('No active complaints.'),
            );
          }

          return ListView.separated(
            itemCount: complaints.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return ListTile(
                title: Text(complaint.title),
                subtitle: Text(
                  'Category: ${complaint.category}\nPriority: ${complaint.priority}\nCreated: ${_formatDate(complaint.createdAt)}',
                ),
                isThreeLine: true,
                trailing: _statusChip(complaint.status),
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
    return Chip(
      label: Text(status),
      visualDensity: VisualDensity.compact,
    );
  }
}
