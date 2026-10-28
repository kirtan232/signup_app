import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'success_screen.dart';

// put the instructor url here. if it is empty the app uses the mock tip.
const String baseUrl = '';

// gets a signup tip from the AI service (or the mock if no url)
// only sends the task and topic, never anything from the form.
Future<String> getSignupTip(bool pretendOffline) async {
  if (baseUrl == '') {
    await Future.delayed(const Duration(seconds: 1));
    if (pretendOffline) {
      throw Exception('offline');
    }
    return 'Use a longer password with a mix of letters, numbers and symbols. Do not reuse passwords from other sites.';
  }

  final response = await http
      .post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'task': 'signup_tip', 'topic': 'password_help'}),
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode != 200) {
    throw Exception('bad status');
  }
  final data = jsonDecode(response.body);
  String tip = data['tip'].toString().trim();
  if (tip == '' || tip == 'null') {
    throw Exception('empty tip');
  }
  return tip;
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 🔑 The Global Key - acts like a remote control for the form.
  final _formKey = GlobalKey<FormState>();

  // 📝 Controllers to track what the user types.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // 🎛️ true = dots, false = letters
  bool _obscurePassword = true;
  DateTime? _birthDate;
  bool _submitting = false;

  // AI tip stuff
  bool _loading = false;
  String _tip = '';
  String _error = '';
  bool _pretendOffline = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2008),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(), // no future birthdays!
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _dateController.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true); // potion starts brewing

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return; // user may have left the screen

    // pushReplacement() = no Back into the form after signing up
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SuccessScreen(userName: _nameController.text.trim()),
      ),
    );
  }

  void _getTip() async {
    setState(() {
      _loading = true;
      _tip = '';
      _error = '';
    });
    try {
      String tip = await getSignupTip(_pretendOffline);
      if (tip.length > 240) {
        tip = tip.substring(0, 240);
      }
      if (!mounted) return;
      setState(() {
        _tip = tip;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not get a tip right now. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // 👨 Parent
      appBar: AppBar(
        title: const Text('Signup App!'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form( // 👶 Child
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Create Your Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 👤 Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 📧 Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 🔒 Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 🎂 Birth Date Field
              TextFormField(
                controller: _dateController,
                readOnly: true, // taps open the picker, not the keyboard
                decoration: const InputDecoration(
                  labelText: 'Birth Date',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                validator: (_) =>
                    _birthDate == null ? 'Pick your birth date' : null,
                onTap: _pickBirthDate,
              ),
              const SizedBox(height: 24),

              // 🚀 Sign Up Button
              ElevatedButton(
                onPressed: _submitting ? null : _submit, // null = disabled
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Join the Mansion',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 30),

              // 🤖 AI Tip
              OutlinedButton(
                onPressed: _loading ? null : _getTip,
                child: const Text('Get a signup tip'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _pretendOffline,
                    onChanged: (value) {
                      setState(() {
                        _pretendOffline = value!;
                      });
                    },
                  ),
                  const Text('Pretend offline (test)'),
                ],
              ),
              if (_loading) const CircularProgressIndicator(),
              if (_tip != '')
                Text(
                  (baseUrl == '' ? 'AI-generated advice (Not real AI was called):\n' : 'AI-generated advice:\n') + _tip,
                ),
              if (_error != '') ...[
                Text(_error, style: const TextStyle(color: Colors.red)),
                TextButton(onPressed: _getTip, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
