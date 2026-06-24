import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> deleteDoctor(String doctorUid) async {
    try {
      // Delete from doctors collection
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorUid)
          .delete();

      // Delete from users collection (VERY IMP)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorUid)
          .delete();

      print("Doctor fully removed and login blocked!");
    } catch (e) {
      print("Error: $e");
    }
  }

  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String _email = '';
  String _password = '';
  String _selectedRole = 'Admin';

  final List<String> _roles = ['Admin', 'Doctor', 'Staff'];

  // 🔹 Login Function
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // 🔹 Step 1: Login user with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      final uid = credential.user!.uid;

      // 🔹 Step 2: Check if user exists in Firestore
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        // If user doc not found, logout and show error
        await _auth.signOut();
        throw Exception("User record not found in Firestore.");
      }

      final userData = userDoc.data()!;
      final role = userData['role'];

      // 🔹 Step 3: Verify Firestore role matches dropdown role
      if (role.toString().toLowerCase() != _selectedRole.toLowerCase()) {
        await _auth.signOut(); // logout unauthorized
        throw Exception("You are not authorized as $_selectedRole");
      }

      // 🔹 Step 4: Navigate to correct screen based on Firestore role
      if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'Doctor') {
        Navigator.pushReplacementNamed(context, '/doctor');
      } else if (role == 'Staff') {
        Navigator.pushReplacementNamed(context, '/staff');
      } else {
        throw Exception("Invalid role found in Firestore");
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Welcome $role!")));
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Authentication failed");
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔹 Error Message Snackbar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 🔹 UI (same as before)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      color: Colors.teal,
                      size: 60,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Clinic Portal Login",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Role Selection
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Login As",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Colors.teal,
                        ),
                      ),
                      value: _selectedRole,
                      items:
                          _roles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Email
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.teal,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (v) =>
                              v == null || !v.contains('@')
                                  ? 'Enter valid email'
                                  : null,
                      onSaved: (v) => _email = v!.trim(),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 Password
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.teal,
                        ),
                      ),
                      obscureText: true,
                      validator:
                          (v) =>
                              v == null || v.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                      onSaved: (v) => _password = v!,
                    ),

                    const SizedBox(height: 24),

                    // 🔹 Login Button
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.teal)
                        : ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text("Login"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _login,
                        ),

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Forgot Password?"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
