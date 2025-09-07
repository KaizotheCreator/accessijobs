import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'employer_login_page.dart';

class JobseekerLoginPage extends StatefulWidget {
  const JobseekerLoginPage({super.key});

  @override
  State<JobseekerLoginPage> createState() => _JobseekerLoginPageState();
}

class _JobseekerLoginPageState extends State<JobseekerLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _obscurePassword = true;
  String _selectedRole = 'Jobseeker';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// 🔹 Ensure Firestore structure exists for Jobseeker
  Future<void> _setupJobseekerData(User user) async {
    final userRef = FirebaseFirestore.instance.collection("users").doc(user.uid);

    // Root user doc
    await userRef.set({
      "email": user.email,
      "role": "jobseeker",
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Profile subcollection
    final profileDoc = userRef.collection("profile").doc("main");
    if (!(await profileDoc.get()).exists) {
      await profileDoc.set({
        "name": "",
        "title": "",
        "bio": "",
        "skills": [],
        "achievements": [],
        "certifications": [],
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }

    // Resumes subcollection
    final resumesRef = userRef.collection("resumes");
    final resumeDocs = await resumesRef.get();
    if (resumeDocs.docs.isEmpty) {
      await resumesRef.add({
        "title": "Default Resume",
        "theme": "modern",
        "payload": {},
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) return userDoc['role'];
      return null;
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  Future<void> _login() async {
  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill in all fields")),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user!;
    String? userRole = await getUserRole(user.uid);

    if (userRole == 'jobseeker') {
      // ✅ Only setup jobseeker data if their role is correct
      await _setupJobseekerData(user);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jobseeker login successful")),
      );
      Navigator.pushReplacementNamed(context, '/jobseeker_dashboard');
    } else {
      // ❌ Wrong role — log them out
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "This account is not registered as a Jobseeker. Please use Employer login."),
        ),
      );
    }
  } on FirebaseAuthException catch (e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = "No account found with this email.";
        break;
      case 'wrong-password':
        message = "Incorrect password.";
        break;
      case 'invalid-email':
        message = "Invalid email format.";
        break;
      case 'user-disabled':
        message = "This account has been disabled.";
        break;
      default:
        message = "Login failed: ${e.message}";
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Unexpected error: $e")),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user!;
      await _setupJobseekerData(user);

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Welcome! Your Jobseeker account has been created.")),
        );
        Navigator.pushReplacementNamed(context, '/jobseeker_dashboard');
      } else {
        String role = docSnapshot['role'];
        if (role == 'jobseeker') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Jobseeker login successful")),
          );
          Navigator.pushReplacementNamed(context, '/jobseeker_dashboard');
        } else {
          await FirebaseAuth.instance.signOut();
          await _googleSignIn.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "This Google account is registered as Employer. Please use Employer login.")),
          );
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: $error")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToSelectedRole(String? role) {
    if (role == 'Employer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmployerLoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/Login_Background.webp', fit: BoxFit.cover),
          SafeArea(
            child: Center(
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/admin_login'),
                          child: Image.asset('assets/logo.png', height: 50),
                        ),
                        DropdownButton<String>(
                          value: _selectedRole,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          onChanged: (String? newValue) {
                            setState(() => _selectedRole = newValue!);
                            _navigateToSelectedRole(newValue);
                          },
                          items: <String>['Jobseeker', 'Employer']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Jobseeker Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) {
                        if (!_isLoading) {
                          _login();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login", style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(color: Colors.white54, thickness: 1)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text("OR",
                              style: TextStyle(color: Colors.white70)),
                        ),
                        Expanded(
                            child: Divider(color: Colors.white54, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/google_logo.png',
                              height: 24, width: 24),
                          const SizedBox(width: 12),
                          Text(
                            "Sign in with Google",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () => Navigator.pushNamed(context, '/signup'),
                      child: Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(
                          color: _isLoading ? Colors.grey : Colors.blueAccent,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
