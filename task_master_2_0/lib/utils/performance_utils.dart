import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Run compute-intensive tasks on a background isolate
Future<T> computeInBackground<T, P>(ComputeCallback<P, T> callback, P param) {
  return compute(callback, param);
}

/// Debounce function to prevent excessive execution (e.g. for search fields)
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 300});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Helper extension for widgets that need to be optimized
extension PerformanceOptimizer on Widget {
  Widget withCachedBuilder({
    Key? key,
    String? debugLabel,
  }) {
    return _OptimizedChildBuilder(
      key: key,
      debugLabel: debugLabel,
      child: this,
    );
  }
}

class _OptimizedChildBuilder extends StatelessWidget {
  final Widget child;
  final String? debugLabel;

  const _OptimizedChildBuilder({
    super.key, 
    required this.child,
    this.debugLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Using RepaintBoundary to isolate complex widgets from causing full tree repaints
    return RepaintBoundary(child: child);
  }
}

/// Image loading with fade-in animation for better perceived performance
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInImage.assetNetwork(
      placeholder: 'assets/images/placeholder.png',
      image: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      imageErrorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
    );
  }
}
