import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CheckAnimation extends StatefulWidget {
  final bool isCompleted;
  final VoidCallback onTap;

  const CheckAnimation({
    Key? key,
    required this.isCompleted,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CheckAnimation> createState() => _CheckAnimationState();
}

class _CheckAnimationState extends State<CheckAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isCompleted ? Colors.green : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
            color: widget.isCompleted ? Colors.green : Colors.transparent,
          ),
          child: widget.isCompleted
              ? const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
} 