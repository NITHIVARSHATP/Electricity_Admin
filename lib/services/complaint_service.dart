import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/complaint_model.dart';

class ComplaintService {
  ComplaintService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _complaints =>
      _firestore.collection('complaints');

  Stream<List<ComplaintModel>> streamActiveComplaints() {
    const activeStatuses = ['Submitted', 'Under Review', 'Reopened'];

    return _complaints
        .where('status', whereIn: activeStatuses)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ComplaintModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<ComplaintModel?> streamComplaintById(String complaintId) {
    return _complaints.doc(complaintId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ComplaintModel.fromFirestore(doc);
    });
  }

  Future<void> markUnderReview(String complaintId) async {
    await _ensureModuleDefaults(complaintId);
    return _complaints.doc(complaintId).update({
      'status': 'Under Review',
    });
  }

  Future<void> markInProgress(String complaintId) async {
    await _ensureModuleDefaults(complaintId);
    return _complaints.doc(complaintId).update({
      'status': 'In Progress',
    });
  }

  Future<void> assignFieldStaff({
    required String complaintId,
    required String assignedTo,
    required String assignedRole,
  }) async {
    await _ensureModuleDefaults(complaintId);
    return _complaints.doc(complaintId).update({
      'assignedTo': assignedTo.trim().isEmpty ? 'Pending' : assignedTo.trim(),
      'assignedRole': assignedRole.trim().isEmpty ? 'Pending' : assignedRole,
    });
  }

  Future<void> markResolved({
    required String complaintId,
    required String resolutionNote,
    required String proofImage,
  }) async {
    await _ensureModuleDefaults(complaintId);
    return _complaints.doc(complaintId).update({
      'status': 'Resolved',
      'resolutionNote':
          resolutionNote.trim().isEmpty ? 'Not Added' : resolutionNote.trim(),
      'proofImage': proofImage.trim().isEmpty
          ? 'placeholder_image_url'
          : proofImage.trim(),
    });
  }

  Future<void> _ensureModuleDefaults(String complaintId) async {
    final ref = _complaints.doc(complaintId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final updates = <String, dynamic>{};

      if (data['ward'] == null) updates['ward'] = 'Unknown';
      if (data['assignedTo'] == null) updates['assignedTo'] = 'Pending';
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
