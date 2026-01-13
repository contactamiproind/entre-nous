import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/floating_decoration.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize default users asynchronously (non-blocking)
    _initializeApp();

    // Setup animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  Color(0xFF6EC1E4), // Light blue
                  Color(0xFF9BA8E8), // Purple-blue
                  Color(0xFFE8A8D8), // Pink
                ],
              ),
            ),
          ),
          
          // Top left - small circle
          const FloatingDecoration(
            shape: 'circle',
            color: Color(0xFFF9A8D4), // Light pink circle
            size: 40,
            top: 50,
            left: 30,
            opacity: 0.7,
          ),
          // Left side - curved arc (using squiggle)
          const FloatingDecoration(
            shape: 'squiggle',
            color: Color(0xFFC4B5FD), // Light purple arc
            size: 80,
            top: 180,
            left: -20,
            opacity: 0.6,
          ),
          
          // Top right - yellow circle
          const FloatingDecoration(
            shape: 'circle',
            color: Color(0xFFFBBF24), // Yellow circle
            size: 55,
            top: 30,
            right: 30,
            opacity: 0.7,
          ),
          // Diagonal squiggle
          const FloatingDecoration(
            shape: 'squiggle', 
            color: Color(0xFFFFFFFF), // White squiggle
            size: 100, 
            top: 100,
            right: -30,
            opacity: 0.5,
            delay: 0.3,
          ),
            // Main content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
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
                                color: const Color(0xFFFBBF24), // Yellow accent
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entre Nous Quiz',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.05),
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
                                color: Colors.white.withOpacity(0.9),
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
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF6BCB9F,
                              ).withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'START',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.play_circle_fill_rounded, size: 32),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
