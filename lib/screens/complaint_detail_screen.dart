import 'package:flutter/material.dart';

import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import 'assign_staff_screen.dart';
import 'resolution_entry_screen.dart';

class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
    ComplaintService? complaintService,
  }) : _complaintService = complaintService;

  final String complaintId;
  final ComplaintService? _complaintService;

  ComplaintService get complaintService => _complaintService ?? ComplaintService();

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Detail')),
      body: StreamBuilder<ComplaintModel?>(
        stream: widget.complaintService.streamComplaintById(widget.complaintId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final complaint = snapshot.data;
          if (complaint == null) {
            return const Center(child: Text('Complaint not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailItem('Title', complaint.title),
                _detailItem('Description', complaint.description),
                _detailItem('Category', complaint.category),
                _detailItem('Priority', complaint.priority),
                _detailItem('Status', complaint.status),
                _detailItem(
                  'Location',
                  'Lat: ${complaint.latitude?.toStringAsFixed(5) ?? 'N/A'}, '
                      'Long: ${complaint.longitude?.toStringAsFixed(5) ?? 'N/A'}',
                ),
                _detailItem('Ward', complaint.ward),
                _detailItem('Assigned To', complaint.assignedTo),
                _detailItem('Assigned Role', complaint.assignedRole),
                _detailItem('Resolution Note', complaint.resolutionNote),
                _detailItem('Proof Image', complaint.proofImage),
                const SizedBox(height: 12),
                if (complaint.imageUrl.trim().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      complaint.imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Text('Unable to load complaint image'),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () => _updateStatusUnderReview(complaint.complaintId),
                      child: const Text('Mark Under Review'),
                    ),
                    OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AssignStaffScreen(
                                    complaintId: complaint.complaintId,
                                    complaintService: widget.complaintService,
                                  ),
                                ),
                              );
                            },
                      child: const Text('Assign Field Staff'),
                    ),
                    ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () => _updateStatusInProgress(complaint.complaintId),
                      child: const Text('Mark In Progress'),
                    ),
                    OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ResolutionEntryScreen(
                                    complaintId: complaint.complaintId,
                                    complaintService: widget.complaintService,
                                  ),
                                ),
                              );
                            },
                      child: const Text('Resolution Entry'),
                    ),
                  ],
                ),
                if (_loading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatusUnderReview(String complaintId) async {
    setState(() => _loading = true);
    try {
      await widget.complaintService.markUnderReview(complaintId);
      _showMessage('Status updated to Under Review');
    } catch (error) {
      _showMessage('Failed to update status: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _updateStatusInProgress(String complaintId) async {
    setState(() => _loading = true);
    try {
      await widget.complaintService.markInProgress(complaintId);
      _showMessage('Status updated to In Progress');
    } catch (error) {
      _showMessage('Failed to update status: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
