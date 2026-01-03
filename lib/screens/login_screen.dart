import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedRole = 'user'; // Default to user

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Get user profile to check role
        var profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('user_id', response.user!.id)
            .maybeSingle();

        // If profile doesn't exist, create it
        if (profile == null) {
          try {
            // Default to 'user' role unless it's the specific admin email (optional safeguard)
            // For now just use the selected role or default to 'user'
            final newProfile = {
              'user_id': response.user!.id,
              'email': response.user!.email,
              'role': 'user', // Default new users to 'user'
              'created_at': DateTime.now().toIso8601String(),
            };
            
            await Supabase.instance.client.from('profiles').insert(newProfile);
            profile = newProfile;
          } catch (e) {
            debugPrint('Error creating profile: $e');
            // If insert fails, we can't proceed safely with role check
             setState(() {
              _isLoading = false;
              _errorMessage = 'User profile missing and could not be created.';
            });
            await Supabase.instance.client.auth.signOut();
            return;
          }
        }

        if (!mounted) return;

        // Verify the selected role matches the user's actual role
        // Note: In a real app, you might just redirect based on role
        // If the user is an admin in DB, they can login as User or Admin (implied privilege)
        // BUT strict check: request role must match DB role
        if (profile['role'] != _selectedRole) {
           // Allow Admin to login as User? usually yes, but let's stick to strict or allow
           // If DB says 'admin', allow both. If DB says 'user', allow only 'user'.
           if (profile['role'] == 'user' && _selectedRole == 'admin') {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Access Denied: You do not have Admin privileges.';
              });
              await Supabase.instance.client.auth.signOut();
              return;
           }
           // If profile is admin but selected user, it's fine, we just treat them as user for navigation
           // If strict matching is desired:
           // if (profile['role'] != _selectedRole) { ... }
        }

        // Navigate based on selected role (assuming valid)
        if (_selectedRole == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error logging in: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.getPagePadding(context);
    final titleSize = ResponsiveUtils.getH1Size(context);
    final subtitleSize = ResponsiveUtils.getBodySize(context);
    final logoSize = ResponsiveUtils.isMobile(context) ? 60.0 : 80.0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.isMobile(context) ? double.infinity : 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(padding * 0.67),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A2F4B).withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: padding),
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1A2F4B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: padding * 0.33),
                  Text(
                    'Login to continue your journey',
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: const Color(0xFF1A2F4B).withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: padding * 1.33),
                
                // Role selection
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'user';
                              _errorMessage = '';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'user'
                                  ? const Color(0xFF6BCB9F) // Teal
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: _selectedRole == 'user'
                                      ? Colors.white
                                      : const Color(0xFF1A2F4B).withOpacity(0.5),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == 'user'
                                        ? Colors.white
                                        : const Color(0xFF1A2F4B).withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'admin';
                              _errorMessage = '';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'admin'
                                  ? const Color(0xFFF08A7E) // Coral
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings_rounded,
                                  size: 20,
                                  color: _selectedRole == 'admin'
                                      ? Colors.white
                                      : const Color(0xFF1A2F4B).withOpacity(0.5),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == 'admin'
                                        ? Colors.white
                                        : const Color(0xFF1A2F4B).withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF1A2F4B)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFF1A2F4B), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF1A2F4B)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFF1A2F4B), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Error message
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF08A7E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF08A7E).withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFF08A7E)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: Color(0xFF1A2F4B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: ResponsiveUtils.getButtonHeight(context),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF8C67D),
                            foregroundColor: const Color(0xFF1A2F4B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Color(0xFF1A2F4B),
                                )
                              : Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getBodySize(context) + 2,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                           Navigator.pushNamed(context, '/signup');
                        },
                        child: Text(
                          'Don\'t have an account? Sign Up',
                           style: TextStyle(
                              color: const Color(0xFF1A2F4B).withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                           ),
                        ),
                      ),
                      SizedBox(height: padding),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
