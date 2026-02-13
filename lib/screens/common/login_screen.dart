import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../utils/responsive_utils.dart';
import '../../widgets/floating_decoration.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    bool isLoading = false;
    String dialogError = '';

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2F4B))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter your email address and we\'ll send you a link to reset your password.', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFFFFA726)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFA726), width: 2)),
                    ),
                  ),
                  if (dialogError.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF08A7E).withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF08A7E).withOpacity(0.5))),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFF08A7E), size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(dialogError, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty || !email.contains('@')) {
                      setDialogState(() => dialogError = 'Please enter a valid email address');
                      return;
                    }
                    setDialogState(() {
                      isLoading = true;
                      dialogError = '';
                    });
                    try {
                      await Supabase.instance.client.auth.resetPasswordForEmail(email);
                      if (!mounted) return;
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('Password reset link sent to $email', style: const TextStyle(fontWeight: FontWeight.w600)))]),
                          backgroundColor: const Color(0xFF6BCB9F),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        isLoading = false;
                        dialogError = 'Error: ${e.toString()}';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Send Reset Link', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
    emailController.dispose();
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
        // Update last login timestamp on profiles
        try {
          await Supabase.instance.client
              .from('profiles')
              .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
              .eq('user_id', response.user!.id);
        } catch (e) {
          debugPrint('Error updating login timestamp: $e');
        }

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

        // Get user's role from database
        final userRole = profile['role'] ?? 'user';
        
        // Get user's name for welcome message
        final userName =
            profile['full_name'] ??
            response.user!.email?.split('@')[0] ??
            'User';

        if (!mounted) return;

        // Show welcome dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EF8B).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 50,
                        color: Color(0xFF6BCB9F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome back,',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2F4B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Auto-dismiss after 1.5 seconds and navigate
        await Future.delayed(const Duration(milliseconds: 1500));

        if (!mounted) return;

        // Close dialog
        Navigator.of(context).pop();

        // Navigate based on user's role from database
        if (userRole == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } on AuthException catch (e) {
      String msg = e.message;
      
      // If generic invalid credentials error, check if email exists to give specific feedback
      if (msg.contains('Invalid login credentials')) {
        try {
          final bool emailExists = await Supabase.instance.client
              .rpc('check_email_exists', params: {'email_check': _emailController.text.trim()});
          
          if (emailExists) {
            msg = 'Incorrect password. Please try again.';
          } else {
            msg = 'Email not registered. Please sign up or contact admin.';
          }
        } catch (_) {
          // If RPC fails (e.g. not deployed yet), fall back to generic message
          // msg remains 'Invalid login credentials'
        }
      }

      setState(() {
        _isLoading = false;
        _errorMessage = msg;
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
    final logoSize = ResponsiveUtils.isMobile(context) ? 160.0 : 220.0;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF9E6), // Very light yellow
                  Color(0xFFF4EF8B), // Main yellow #f4ef8b
                  Color(0xFFE8D96F), // Darker yellow
                ],
              ),
            ),
          ),
          
          // Top left - star
          const Positioned(
            top: 50,
            left: 40,
            child: Icon(
              Icons.star,
              color: Color(0xFFFFC107),
              size: 45,
            ),
          ),
          
          // Top center-right - circle
          Positioned(
            top: 45,
            right: MediaQuery.of(context).size.width * 0.30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFD8BFD8).withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Diagonal stripe
          Positioned(
            top: 70,
            right: -30,
            child: Transform.rotate(
              angle: -0.6,
              child: Container(
                width: 180,
                height: 350,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4B5).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          
          // Wavy line at bottom
          Positioned(
            bottom: 80,
            left: -50,
            right: -50,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width + 100, 100),
              painter: WavePainter(),
            ),
          ),
            // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveUtils.isMobile(context)
                        ? double.infinity
                        : 500,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: logoSize,
                        width: logoSize,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: padding),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: padding * 0.33),
                      Text(
                        'Login to continue your journey',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: padding * 1.33),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.email_rounded,
                                  color: Colors.black,
                                ),
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
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1A2F4B),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.lock_rounded,
                                  color: Colors.black,
                                ),
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
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8D96F),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            // Forgot Password link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFFFA726),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Error message
                            if (_errorMessage.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF08A7E,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFF08A7E,
                                    ).withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFF08A7E),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage,
                                        style: const TextStyle(
                                          color: Color(0xFFD32F2F), // Dark red for visibility
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
                                  backgroundColor: const Color(0xFFFFA726),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shadowColor: const Color(
                                    0xFFE8D96F,
                                  ).withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: _isLoading
                                    ? Center(
                                        child: AspectRatio(
                                          aspectRatio: 1.0,
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF1E293B),
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontSize:
                                              ResponsiveUtils.getBodySize(
                                                context,
                                              ) +
                                              2,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
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
          ),
        ],
      ),
    );
  }
}

// Custom painter for wavy line decoration
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB6C1).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double i = 0; i < size.width; i++) {
      path.lineTo(
        i,
        size.height / 2 + 20 * sin(i / 50),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
