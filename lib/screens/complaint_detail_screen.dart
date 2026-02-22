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
  static const String _assignedOfficialEmail = 'sakthi@gmail.com';
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

          final normalizedStatus = _normalizeStatus(complaint.status);
          final canMarkUnderReview =
              normalizedStatus == 'classified' || normalizedStatus == 'reopened';
          final canAssignFieldStaff =
              normalizedStatus == 'classified' || normalizedStatus == 'under_review';
          final canMarkInProgress = normalizedStatus == 'under_review';
          final canResolutionEntry = normalizedStatus == 'in_progress';
            final canReopenComplaint = normalizedStatus == 'resolved';
            final canDeleteComplaint = normalizedStatus == 'resolved';
          final showActions = canMarkUnderReview ||
              canAssignFieldStaff ||
              canMarkInProgress ||
              canResolutionEntry ||
              canReopenComplaint ||
              canDeleteComplaint;

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _sectionCard(
                  title: 'Complaint Info',
                  children: [
                    _detailItem('Title', complaint.title),
                    _detailItem('Description', complaint.description),
                    _detailItem('Category', complaint.category),
                    _detailItem('Priority', complaint.priority),
                    _detailItem('Status', _displayStatus(complaint.status)),
                    if (normalizedStatus == 'resolved')
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Problem Resolved',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'Location Details',
                  children: [
                    _detailItem(
                      'Coordinates',
                      'Lat: ${complaint.latitude?.toStringAsFixed(5) ?? 'N/A'}, '
                          'Long: ${complaint.longitude?.toStringAsFixed(5) ?? 'N/A'}',
                    ),
                    _detailItem('Ward', complaint.ward),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'Assignment Details',
                  children: [
                    _detailItem('Assigned Official', _assignedOfficialEmail),
                    _detailItem('Assigned Field Staff', _assignedFieldStaffText(complaint)),
                    _detailItem('Assigned Role', _assignedRoleText(complaint.assignedRole)),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'Resolution Details',
                  children: [
                    _detailItem('Resolution Note', complaint.resolutionNote),
                    _detailItem('Proof Image', complaint.proofImage),
                  ],
                ),
                const SizedBox(height: 12),
                if (complaint.imageUrl.trim().isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
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
                    ),
                  ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Workflow Actions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _detailItem(
                          'Assigned Official',
                          _assignedOfficialEmail,
                        ),
                        _detailItem(
                          'Assigned Field Staff',
                          _assignedFieldStaffText(complaint),
                        ),
                        _detailItem(
                          'Current Status',
                          _displayStatus(complaint.status),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          showActions
                              ? 'Buttons shown are valid for this status.'
                              : 'This complaint is read-only for AE workflow.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (showActions)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final narrow = constraints.maxWidth < 700;
                              final visibleButtons = <Widget>[
                                if (canMarkUnderReview)
                                  ElevatedButton.icon(
                                    onPressed: _loading
                                        ? null
                                        : () => _updateStatusUnderReview(
                                            complaint.complaintId,
                                          ),
                                    icon: const Icon(Icons.rule_folder),
                                    label: const Text('Mark Under Review'),
                                  ),
                                if (canAssignFieldStaff)
                                  OutlinedButton.icon(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => AssignStaffScreen(
                                                  complaintId:
                                                      complaint.complaintId,
                                                  complaintService:
                                                      widget.complaintService,
                                                ),
                                              ),
                                            );
                                          },
                                    icon: const Icon(Icons.person_add_alt),
                                    label: const Text('Assign Field Staff'),
                                  ),
                                if (canMarkInProgress)
                                  ElevatedButton.icon(
                                    onPressed: _loading
                                        ? null
                                        : () => _updateStatusInProgress(
                                            complaint.complaintId,
                                          ),
                                    icon: const Icon(Icons.build_circle),
                                    label: const Text('Mark In Progress'),
                                  ),
                                if (canResolutionEntry)
                                  OutlinedButton.icon(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ResolutionEntryScreen(
                                                  complaintId:
                                                      complaint.complaintId,
                                                  complaintService:
                                                      widget.complaintService,
                                                ),
                                              ),
                                            );
                                          },
                                    icon: const Icon(Icons.verified),
                                    label: const Text('Resolution Entry'),
                                  ),
                                if (canReopenComplaint)
                                  OutlinedButton.icon(
                                    onPressed: _loading
                                        ? null
                                        : () => _reopenComplaint(
                                            complaint.complaintId,
                                          ),
                                    icon: const Icon(Icons.restart_alt),
                                    label: const Text('Reopen Complaint'),
                                  ),
                                if (canDeleteComplaint)
                                  OutlinedButton.icon(
                                    onPressed: _loading
                                        ? null
                                        : () => _deleteComplaint(
                                            complaint.complaintId,
                                          ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFC62828),
                                      side: const BorderSide(
                                        color: Color(0xFFC62828),
                                      ),
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete Complaint'),
                                  ),
                              ];

                              if (narrow) {
                                return Column(
                                  children: [
                                    for (var index = 0;
                                        index < visibleButtons.length;
                                        index++) ...[
                                      SizedBox(
                                        width: double.infinity,
                                        child: visibleButtons[index],
                                      ),
                                      if (index != visibleButtons.length - 1)
                                        const SizedBox(height: 8),
                                    ],
                                  ],
                                );
                              }

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: visibleButtons
                                    .map(
                                      (button) => SizedBox(
                                        width: (constraints.maxWidth - 8) / 2,
                                        child: button,
                                      ),
                                    )
                                    .toList(growable: false),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                  if (_loading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
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
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            decoration: TextDecoration.none,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                decoration: TextDecoration.none,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(decoration: TextDecoration.none),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  String _displayStatus(String status) {
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

  String _assignedFieldStaffText(ComplaintModel complaint) {
    final assignedTo = complaint.assignedTo.trim();
    final assignedRole = complaint.assignedRole.trim();
    final normalizedAssignedTo = assignedTo.toLowerCase();
    final normalizedRole = assignedRole.toLowerCase();

    final isUnassigned = assignedTo.isEmpty ||
        normalizedAssignedTo == 'pending' ||
        normalizedAssignedTo == 'unassigned' ||
        (normalizedAssignedTo == _assignedOfficialEmail &&
            (normalizedRole.isEmpty || normalizedRole == 'pending'));

    if (isUnassigned) {
      return 'Unassigned';
    }

    if (normalizedRole.isEmpty || normalizedRole == 'pending') {
      return assignedTo;
    }

    return '$assignedTo ($assignedRole)';
  }

  String _assignedRoleText(String role) {
    final value = role.trim();
    if (value.isEmpty || value.toLowerCase() == 'pending') {
      return 'Pending';
    }
    return value;
  }

        String _normalizeStatus(String value) {
          return value
          .trim()
          .toLowerCase()
          .replaceAll('-', '_')
          .replaceAll(' ', '_');
        }

  Future<void> _updateStatusUnderReview(String complaintId) async {
    setState(() => _loading = true);
    try {
      await widget.complaintService.markUnderReview(complaintId);
      _showMessage('Status updated to under_review');
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
      _showMessage('Status updated to in_progress');
    } catch (error) {
      final message = error.toString();
      if (message.toLowerCase().contains('assign field staff')) {
        await _showAssignmentRequiredAlert();
      } else {
        _showMessage('Failed to update status: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _reopenComplaint(String complaintId) async {
    setState(() => _loading = true);
    try {
      await widget.complaintService.reopenComplaint(complaintId);
      _showMessage('Complaint reopened and moved back to AE workflow.');
    } catch (error) {
      _showMessage('Failed to reopen complaint: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteComplaint(String complaintId) async {
    final confirmed = await _confirmDelete();
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      await widget.complaintService.deleteComplaint(complaintId);
      if (!mounted) return;
      _showMessage('Complaint deleted successfully.');
      Navigator.of(context).pop();
    } catch (error) {
      _showMessage('Failed to delete complaint: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Complaint?'),
          content: const Text(
            'This action will permanently remove the resolved complaint. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _showAssignmentRequiredAlert() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assignment Required'),
          content: const Text(
            'Please assign the field officer first before marking this complaint as In Progress.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
