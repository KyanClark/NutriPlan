import 'package:flutter/material.dart';

class AITypingCursor extends StatefulWidget {
  final Color color;
  final double dotSize;
  final int dotCount;
  final Duration period;

  const AITypingCursor({
    super.key,
    this.color = const Color(0xFF2E7D32),
    this.dotSize = 6,
    this.dotCount = 3,
    this.period = const Duration(milliseconds: 300),
  });

  @override
  State<AITypingCursor> createState() => _AITypingCursorState();
}

class _AITypingCursorState extends State<AITypingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final active = (_controller.value * widget.dotCount).floor();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.dotCount, (i) {
            final isOn = i <= active;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: isOn ? widget.color : widget.color.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}


