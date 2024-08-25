import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'login.dart'; // Import the LoginPage

class SignUpResponse {
  final String message;
  final bool success;

  SignUpResponse({required this.message, required this.success});

  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    return SignUpResponse(
      message: json['message'],
      success: json['success'],
    );
  }
}

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _gender;
  int? _level;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Set _level to 4 if it is null
        final level = _level ?? 4;

        final response = await signUpUser(
          _nameController.text,
          _gender ?? '',
          _emailController.text,
          level,
          _passwordController.text,
        );

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User signed up successfully!'),
            ),
          );
          // Navigate to the home page after successful sign-up
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()), // Replace HomePage with your actual home page widget
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
            ),
          );
        }
      } catch (e) {
        print('Error signing up user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while signing up. Please try again later.'),
          ),
        );
      }
    }
  }

  Future<SignUpResponse> signUpUser(String name, String gender, String email, int? level, String password) async {
    final url = Uri.parse('http://www.emaproject.somee.com/api/Student/signup');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'gender': gender,
        'email': email,
        'level': level,
        'password': password,
        'confirmPassword': password, // Assuming confirmPassword should be the same as password
      }),
    );

    if (response.statusCode == 200) {
      if (response.headers['content-type']?.contains('application/json') ?? false) {
        final jsonResponse = jsonDecode(response.body);
        return SignUpResponse.fromJson(jsonResponse);
      } else {
        // Handle plain text response
        return SignUpResponse(message: response.body, success: true);
      }
    } else {
      throw Exception('Failed to sign up user: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'ex@gmail.com'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // Updated email validation regex
                    const emailRegex = r'^[\w-\.]+@stud\.fci-cu\.edu\.eg$';
                    if (!RegExp(emailRegex).hasMatch(value)) {
                      return 'Please enter a valid email ending with @stud.fci-cu.edu.eg';
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Male',
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                    ),
                    const Text('Male'),
                    Radio<String>(
                      value: 'Female',
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                    ),
                    const Text('Female'),
                  ],
                ),
                DropdownButtonFormField<int?>(
                  value: _level,
                  decoration: const InputDecoration(labelText: 'Level'),
                  items: [null, 1, 2, 3, 4].map((int? value) {
                    return DropdownMenuItem<int?>(
                      value: value,
                      child: value != null ? Text('Level $value') : const Text('Select a level'),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setState(() {
                      _level = value;
                    });
                  },

                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    // Password strength regex
                    const passwordRegex = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
                    if (!RegExp(passwordRegex).hasMatch(value)) {
                      return 'Password must be at least 8 characters and contain at least one uppercase letter, one lowercase letter, one number, and one special character';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Sign Up'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage
                    );
                  },
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

