import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class CelebrationWidget extends StatefulWidget {
  final bool show;
  final VoidCallback? onComplete;

  const CelebrationWidget({
    super.key,
    required this.show,
    this.onComplete,
  });

  @override
  State<CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<CelebrationWidget> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Start confetti if show is true on initial build
    if (widget.show) {
      debugPrint('🎊 CelebrationWidget: Starting confetti on init');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _confettiController.play();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && widget.onComplete != null) {
              widget.onComplete!();
            }
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(CelebrationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      debugPrint('🎊 CelebrationWidget: Starting confetti on update');
      if (mounted) {
        _confettiController.play();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && widget.onComplete != null) {
            widget.onComplete!();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎊 CelebrationWidget build: show=${widget.show}');
    if (!widget.show) return const SizedBox.shrink();

    return Stack(
      children: [
        // Left side confetti
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 4, // 45 degrees to the right
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 20,
            minBlastForce: 10,
            gravity: 0.3,
            colors: const [
              Color(0xFF6B5CE7),
              Color(0xFF3498DB),
              Color(0xFFFFD700),
              Color(0xFFFF6B9D),
              Color(0xFF4CAF50),
            ],
            createParticlePath: _drawStar,
          ),
        ),
        // Right side confetti
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3 * pi / 4, // 135 degrees to the left
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 20,
            minBlastForce: 10,
            gravity: 0.3,
            colors: const [
              Color(0xFF6B5CE7),
              Color(0xFF3498DB),
              Color(0xFFFFD700),
              Color(0xFFFF6B9D),
              Color(0xFF4CAF50),
            ],
            createParticlePath: _drawStar,
          ),
        ),
        // Center confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // Straight down
            emissionFrequency: 0.03,
            numberOfParticles: 30,
            maxBlastForce: 25,
            minBlastForce: 15,
            gravity: 0.2,
            colors: const [
              Color(0xFF6B5CE7),
              Color(0xFF3498DB),
              Color(0xFFFFD700),
              Color(0xFFFF6B9D),
              Color(0xFF4CAF50),
            ],
            createParticlePath: _drawStar,
          ),
        ),
      ],
    );
  }

  // Draw a star shape for particles
  Path _drawStar(Size size) {
    double width = size.width;
    double height = size.height;
    
    Path path = Path();
    path.moveTo(width / 2, 0);
    path.lineTo(width * 0.61, height * 0.35);
    path.lineTo(width, height * 0.35);
    path.lineTo(width * 0.68, height * 0.57);
    path.lineTo(width * 0.79, height);
    path.lineTo(width / 2, height * 0.75);
    path.lineTo(width * 0.21, height);
    path.lineTo(width * 0.32, height * 0.57);
    path.lineTo(0, height * 0.35);
    path.lineTo(width * 0.39, height * 0.35);
    path.close();
    
    return path;
  }
}
