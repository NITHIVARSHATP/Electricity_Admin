# Electricity_Admin
Flutter-based admin workflow module for civic electricity complaint management system. Includes AE dashboard, complaint execution flow, verification, and Firestore status updates.

## Module 1 – Execution & Verification (Normal Flow)

Implemented AE workflow screens and Firestore logic:

- `lib/screens/ae_dashboard_screen.dart`
- `lib/screens/complaint_detail_screen.dart`
- `lib/screens/assign_staff_screen.dart`
- `lib/screens/resolution_entry_screen.dart`
- `lib/services/complaint_service.dart`
- `lib/models/complaint_model.dart`

### Workflow covered

- Submitted → Under Review → In Progress → Resolved
- Reopened complaints appear again in AE active dashboard queue
- Field assignment: `assignedTo`, `assignedRole`
- Resolution update: `resolutionNote`, `proofImage`

### Safe defaults (auto-created when missing)

- `ward`: `Unknown`
- `assignedTo`: `Pending`
- `assignedRole`: `Pending`
- `resolutionNote`: `Not Added`
- `proofImage`: `placeholder_image_url`

### Integration

Open AE dashboard as an app screen:

- `AeDashboardScreen()`

Add required dependencies in your Flutter app if not already present:

- `cloud_firestore`

