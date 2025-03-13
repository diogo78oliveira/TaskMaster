import 'package:flutter/material.dart';
import 'dart:ui';

class AnimatedBackground extends StatefulWidget {
  final ThemeData theme;
  
  const AnimatedBackground({super.key, required this.theme});
  
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        // Base gradient with enhanced colors for light theme
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.light 
                ? [
                    Color(0xFFE3F2FD), // Very light blue
                    Color(0xFFF5F5F5), // Light grey
                    Color(0xFFE1F5FE), // Another light blue variant
                  ]
                : [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.9),
                  ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        
        // Animated elements
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Top right blob with enhanced colors
                Positioned(
                  top: -size.height * 0.1 - 50 * _controller.value,
                  right: -size.width * 0.1 - 30 * _controller.value,
                  child: Container(
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: theme.brightness == Brightness.light
                          ? [
                              Color(0xFFBBDEFB).withOpacity(0.4), // Soft blue
                              Color(0xFFBBDEFB).withOpacity(0.2),
                              Colors.transparent,
                            ]
                          : [
                              theme.colorScheme.primary.withOpacity(0.25),
                              theme.colorScheme.primary.withOpacity(0.1),
                              Colors.transparent,
                            ],
                        stops: const [0.2, 0.7, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(300),
                    ),
                  ),
                ),
                
                // Bottom left blob with enhanced colors
                Positioned(
                  bottom: -size.height * 0.1 + 30 * _controller.value,
                  left: -size.width * 0.2 + 40 * _controller.value,
                  child: Container(
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: theme.brightness == Brightness.light
                          ? [
                              Color(0xFFB3E5FC).withOpacity(0.4), // Another soft blue shade
                              Color(0xFFB3E5FC).withOpacity(0.2),
                              Colors.transparent,
                            ]
                          : [
                              theme.colorScheme.secondary.withOpacity(0.25),
                              theme.colorScheme.secondary.withOpacity(0.1),
                              Colors.transparent,
                            ],
                        stops: const [0.2, 0.7, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(300),
                    ),
                  ),
                ),
                
                // Center detail with enhanced colors
                Positioned(
                  top: size.height * 0.4 - 20 * _controller.value,
                  right: size.width * 0.3 + 30 * _controller.value,
                  child: Container(
                    width: size.width * 0.35,
                    height: size.width * 0.35,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: theme.brightness == Brightness.light
                          ? [
                              Color(0xFFE1F5FE).withOpacity(0.5), // Light blue tertiary
                              Color(0xFFE1F5FE).withOpacity(0.2),
                              Colors.transparent,
                            ]
                          : [
                              theme.colorScheme.tertiary.withOpacity(0.15),
                              theme.colorScheme.tertiary.withOpacity(0.05),
                              Colors.transparent,
                            ],
                        stops: const [0.2, 0.6, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(300),
                    ),
                  ),
                ),
                
                // Extra decorative element for light theme (top left)
                if (theme.brightness == Brightness.light)
                  Positioned(
                    top: size.height * 0.15 + 15 * _controller.value,
                    left: size.width * 0.2 - 20 * _controller.value,
                    child: Container(
                      width: size.width * 0.25,
                      height: size.width * 0.25,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFE1BEE7).withOpacity(0.3), // Light purple
                            Color(0xFFE1BEE7).withOpacity(0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.2, 0.6, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(300),
                      ),
                    ),
                  ),
                
                // Subtle pattern overlay with blur
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      width: size.width,
                      height: size.height,
                      color: Colors.transparent,
                    ),
                  ),
                ),
                
                // For light theme, add a semi-transparent colored overlay
                if (theme.brightness == Brightness.light)
                  Container(
                    width: size.width,
                    height: size.height,
                    color: Color(0xFFECEFF1).withOpacity(0.25), // Light blueish-grey
                  ),
                
                // Subtle pattern overlay
                Opacity(
                  opacity: theme.brightness == Brightness.light ? 0.02 : 0.03,
                  child: CustomPaint(
                    size: Size(size.width, size.height),
                    painter: PatternPainter(
                      color: theme.brightness == Brightness.light 
                          ? Color(0xFF90CAF9) // Soft blue for pattern in light mode
                          : theme.colorScheme.onSurface,
                      progress: _controller.value,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// Custom painter for subtle pattern
class PatternPainter extends CustomPainter {
  final Color color;
  final double progress;
  
  PatternPainter({required this.color, required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    final spacing = 40.0; // Increased spacing
    final offset = progress * spacing;
    
    // Draw horizontal lines
    for (double y = -offset; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    for (double x = -offset; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}