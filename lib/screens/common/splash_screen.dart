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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6EC1E4), // Light blue
              Color(0xFF9BA8E8), // Purple-blue
              Color(0xFFE8A8D8), // Pink
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
                      'Level UP!',
                      style: TextStyle(
                        fontSize: titleSize + 8,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF8B5CF6), // Purple
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 4 : 8),
                    Text(
                      'ENEPL Training Game',
                      style: TextStyle(
                        fontSize: titleSize - 4,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFBD38D), // Yellow
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.2),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Elevate Your Potential. Conquer Every Challenge.',
                      style: TextStyle(
                        fontSize: subtitleSize - 1,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 48 : 60),
                    
                    SizedBox(
                      width: isMobile ? 36 : 40,
                      height: isMobile ? 36 : 40,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)), // Yellow
                        strokeWidth: 3.5,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    SizedBox(height: isMobile ? 60 : 80),
                    
                    Text(
                      'ENEPL',
                      style: TextStyle(
                        color: const Color(0xFFFBBF24), // Yellow
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
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
