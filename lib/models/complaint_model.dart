import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String complaintId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String userId;
  final double? latitude;
  final double? longitude;
  final String imageUrl;
  final DateTime? createdAt;
  final String ward;
  final String assignedTo;
  final String assignedRole;
  final String resolutionNote;
  final String proofImage;

  const ComplaintModel({
    required this.complaintId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.createdAt,
    required this.ward,
    required this.assignedTo,
    required this.assignedRole,
    required this.resolutionNote,
    required this.proofImage,
  });

  factory ComplaintModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime? createdAt;
    final createdAtValue = data['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    } else if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue);
    }

    return ComplaintModel(
      complaintId: (data['complaintId'] ?? doc.id).toString(),
      title: (data['title'] ?? 'No Title').toString(),
      description: (data['description'] ?? 'No Description').toString(),
      category: (data['category'] ?? data['aiCategory'] ?? 'Uncategorized')
          .toString(),
      priority: (data['priority'] ?? data['aiPriority'] ?? 'Normal').toString(),
      status: (data['status'] ?? 'Submitted').toString(),
      userId: (data['userId'] ?? 'Unknown User').toString(),
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      createdAt: createdAt,
      ward: (data['ward'] ?? 'Unknown').toString(),
        assignedTo: (data['assignedTo'] ?? 'Unassigned').toString(),
      assignedRole: (data['assignedRole'] ?? 'Pending').toString(),
      resolutionNote: (data['resolutionNote'] ?? 'Not Added').toString(),
      proofImage:
          (data['proofImage'] ?? 'placeholder_image_url').toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
