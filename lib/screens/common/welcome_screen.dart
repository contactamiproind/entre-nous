import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/storage_service.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/floating_decoration.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize default users asynchronously (non-blocking)
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Run initialization in background without blocking UI
    try {
      await StorageService.initializeDefaultUsers();
    } catch (e) {
      // Silently fail - app will still work
      debugPrint('Initialization warning: $e');
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.getPagePadding(context);
    final logoSize = ResponsiveUtils.isMobile(context) ? 220.0 : 250.0;
    final titleSize = ResponsiveUtils.getH1Size(context) + 8;

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
          
          // Top left - small circle
          const FloatingDecoration(
            shape: 'circle',
            color: Color(0xFFFFFBD6), // Light yellow circle
            size: 40,
            top: 50,
            left: 30,
            opacity: 0.7,
          ),
          // Left side - curved arc (using squiggle)
          const FloatingDecoration(
            shape: 'squiggle',
            color: Color(0xFFFFC107), // Amber arc
            size: 80,
            top: 180,
            left: -20,
            opacity: 0.6,
          ),
          
          // Top right - yellow circle
          const FloatingDecoration(
            shape: 'circle',
            color: Color(0xFFE8D96F), // Yellow circle
            size: 55,
            top: 30,
            right: 30,
            opacity: 0.7,
          ),
          // Diagonal squiggle
          const FloatingDecoration(
            shape: 'squiggle', 
            color: Colors.black, // Black squiggle for visibility
            size: 100, 
            top: 100,
            right: -30,
            opacity: 0.5,
            delay: 0.3,
          ),
            // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with shadow
                    Image.asset(
                      'assets/logo.png',
                      height: logoSize,
                      width: logoSize,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 40),

                    // Welcome text
                    Text(
                      'Welcome to',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: const Color(0xFF1E293B), // Dark text
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entre Nous Experiences',
                      style: Theme.of(context).textTheme.displayLarge
                          ?.copyWith(
                            color: const Color(0xFF1E293B),
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'Play, Learn, Level Up!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                            color: Colors.black87, // Changed to black for visibility
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                    ),

                    const SizedBox(height: 60),

                    // Get Started button with enhanced styling
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtils.getButtonHeight(context) + 12,
                      child: ElevatedButton(
                        onPressed: _navigateToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA726), // Orange like LOGIN button
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'START',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.play_circle_fill_rounded, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
                .animate()
                .fade(duration: 1500.ms, curve: Curves.easeIn)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                  duration: 1500.ms,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
