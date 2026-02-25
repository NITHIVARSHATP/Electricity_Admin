import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/citizen_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/official_dashboard_screen.dart';
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Check if we are still connecting to Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. If user is logged in, check their role in Firestore
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users') // Assumes your roles are in a 'users' collection
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                // Extract the role field from Firestore
                final data = roleSnapshot.data!.data() as Map<String, dynamic>;
                String role = data['role'] ?? 'CITIZEN'; // Default to citizen if null

                if (role == 'OFFICIAL') {
                  return const OfficialDashboardScreen();
                } else {
                  return const CitizenDashboardScreen();
                }
              }

              // Handle case where user is authenticated but no Firestore doc exists
              return const CitizenDashboardScreen();
            },
          );
        }

        // 3. If no user is logged in, show Login
        return const LoginScreen();
      },
    );
  }
}