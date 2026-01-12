import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../config/supabase_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    // Show splash for at least 3 seconds
    // Show splash for at least 1.5 seconds for a snappy feel
    final minSplashTime = Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      // Initialize Supabase if not already initialized
      // We check a flag or just try-catch. Supabase.initialize throws if called twice, but we can check instance.
      try {
        Supabase.instance; // Should throw if not initialized
      } catch (_) {
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          anonKey: SupabaseConfig.supabaseAnonKey,
        );
      }
    } catch (e) {
      debugPrint("Supabase Init Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Connection Error: $e'), backgroundColor: Colors.red),
        );
      }
      return; // Stop here if init fails
    }

    await minSplashTime;
    
    if (!mounted) return;

    // Check if user is authenticated
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // User is logged in, check their role
      try {
        // Simple retry logic for profile fetch could be added here
        final response = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('user_id', session.user.id)
            .single();
        
        final role = response['role'];
        
        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
      } catch (e) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // Not logged in, go to welcome screen
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final logoSize = isMobile ? 180.0 : 250.0;
    final titleSize = isMobile ? 32.0 : 40.0;
    final subtitleSize = isMobile ? 14.0 : 16.0;
    final spacing = isMobile ? 24.0 : 32.0;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDF8F0), // Cream
              Color(0xFFFFF5E6), // Lighter cream
              Color(0xFFFEF3E2), // Warm cream
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: spacing),
                    
                    Text(
                      'ENEPL Quiz',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A2F4B),
                        letterSpacing: -1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    Text(
                      'Learn • Practice • Excel',
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: const Color(0xFF1A2F4B).withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 48 : 60),
                    
                    SizedBox(
                      width: isMobile ? 36 : 40,
                      height: isMobile ? 36 : 40,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6BCB9F)),
                        strokeWidth: 3.5,
                      ),
                    ),
                    SizedBox(height: isMobile ? 60 : 80),
                    
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: const Color(0xFF1A2F4B).withOpacity(0.4),
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w500,
                      ),
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
