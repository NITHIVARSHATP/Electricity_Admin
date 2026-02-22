import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/complaint_model.dart';

class ComplaintService {
  ComplaintService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _complaints =>
      _firestore.collection('complaints');

  Stream<List<ComplaintModel>> streamActiveComplaints() {
    const activeStatuses = {
      'classified',
      'under_review',
      'in_progress',
      'resolved',
      'reopened',
    };

    return _complaints
        .snapshots()
        .map((snapshot) {
      final complaints = snapshot.docs
          .map(ComplaintModel.fromFirestore)
          .where(
            (item) => activeStatuses.contains(_normalizeStatus(item.status)),
          )
          .toList(growable: false);

      final sorted = complaints.toList(growable: false)
        ..sort((left, right) {
          final leftTime = left.createdAt;
          final rightTime = right.createdAt;

          if (leftTime == null && rightTime == null) return 0;
          if (leftTime == null) return 1;
          if (rightTime == null) return -1;
          return rightTime.compareTo(leftTime);
        });

      return sorted;
    });
  }

  String _normalizeStatus(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  Stream<ComplaintModel?> streamComplaintById(String complaintId) {
    return _complaints.doc(complaintId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ComplaintModel.fromFirestore(doc);
    });
  }

  Future<void> markUnderReview(String complaintId) async {
    await _ensureAllowedCurrentStatus(
      complaintId,
      allowed: {'classified', 'reopened'},
      actionLabel: 'Mark Under Review',
    );
    await _ensureModuleDefaults(complaintId);
    return _complaints.doc(complaintId).update({
      'status': 'under_review',
    });
  }

  Future<void> markInProgress(String complaintId) async {
    await _ensureAllowedCurrentStatus(
      complaintId,
      allowed: {'under_review'},
      actionLabel: 'Mark In Progress',
    );
    await _ensureFieldStaffAssigned(complaintId);
    await _ensureModuleDefaults(complaintId);
    return _complaints.doc(complaintId).update({
      'status': 'in_progress',
    });
  }

  Future<void> assignFieldStaff({
    required String complaintId,
    required String assignedTo,
    required String assignedRole,
  }) async {
    await _ensureAllowedCurrentStatus(
      complaintId,
      allowed: {'classified', 'under_review'},
      actionLabel: 'Assign Field Staff',
    );
    await _ensureModuleDefaults(complaintId);
    return _complaints.doc(complaintId).update({
      'assignedTo': assignedTo.trim().isEmpty ? 'Unassigned' : assignedTo.trim(),
      'assignedRole': assignedRole.trim().isEmpty ? 'Pending' : assignedRole,
    });
  }

  Future<void> markResolved({
    required String complaintId,
    required String resolutionNote,
    required String proofImage,
  }) async {
    await _ensureAllowedCurrentStatus(
      complaintId,
      allowed: {'in_progress'},
      actionLabel: 'Resolution Entry',
    );
    await _ensureModuleDefaults(complaintId);
    return _complaints.doc(complaintId).update({
      'status': 'resolved',
      'resolutionNote':
          resolutionNote.trim().isEmpty ? 'Not Added' : resolutionNote.trim(),
      'proofImage': proofImage.trim().isEmpty
          ? 'placeholder_image_url'
          : proofImage.trim(),
    });
  }

  Future<void> reopenComplaint(String complaintId) async {
    await _ensureAllowedCurrentStatus(
      complaintId,
      allowed: {'resolved'},
      actionLabel: 'Reopen Complaint',
    );
    return _complaints.doc(complaintId).update({
      'status': 'classified',
      'assignedTo': 'Unassigned',
      'assignedRole': 'Pending',
      'resolutionNote': 'Not Added',
      'proofImage': 'placeholder_image_url',
    });
  }

  Future<void> deleteComplaint(String complaintId) async {
    await _ensureAllowedCurrentStatus(
      complaintId,
      allowed: {'resolved'},
      actionLabel: 'Delete Complaint',
    );
    return _complaints.doc(complaintId).delete();
  }

  Future<void> _ensureAllowedCurrentStatus(
    String complaintId, {
    required Set<String> allowed,
    required String actionLabel,
  }) async {
    final snapshot = await _complaints.doc(complaintId).get();
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? <String, dynamic>{};
    final status = _normalizeStatus((data['status'] ?? '').toString());

    if (!allowed.contains(status)) {
      throw StateError(
        '$actionLabel is not allowed when status is $status.',
      );
    }
  }

  Future<void> _ensureFieldStaffAssigned(String complaintId) async {
    final snapshot = await _complaints.doc(complaintId).get();
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? <String, dynamic>{};
    final assignedTo = _normalizeStatus((data['assignedTo'] ?? '').toString());

    if (assignedTo.isEmpty ||
        assignedTo == 'pending' ||
        assignedTo == 'unassigned') {
      throw StateError('Assign field staff before marking in progress.');
    }
  }

  Future<void> _ensureModuleDefaults(String complaintId) async {
    final ref = _complaints.doc(complaintId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final updates = <String, dynamic>{};

      if (data['ward'] == null) updates['ward'] = 'Unknown';
      if (data['assignedTo'] == null) updates['assignedTo'] = 'Unassigned';
      if (data['assignedRole'] == null) updates['assignedRole'] = 'Pending';
      if (data['resolutionNote'] == null) updates['resolutionNote'] = 'Not Added';
      if (data['proofImage'] == null) {
        updates['proofImage'] = 'placeholder_image_url';
      }

      if (updates.isNotEmpty) {
        transaction.update(ref, updates);
      }
    });
  }
}
