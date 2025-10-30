import 'package:flutter/material.dart';

class RecipeImageWithLoading extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  const RecipeImageWithLoading({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  @override
  State<RecipeImageWithLoading> createState() => _RecipeImageWithLoadingState();
}

class _RecipeImageWithLoadingState extends State<RecipeImageWithLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isLoading = true;
  bool _hasError = false;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
    
    // Preload the image
    _preloadImage();
  }

  void _preloadImage() async {
    try {
      _imageProvider = NetworkImage(widget.imageUrl);
      await _imageProvider!.resolve(ImageConfiguration.empty);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          // Loading animation
          if (_isLoading && !_hasError)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[300]!,
                        Colors.grey[100]!,
                        Colors.grey[300]!,
                      ],
                      stops: [
                        _animation.value - 0.3,
                        _animation.value,
                        _animation.value + 0.3,
                      ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                    ),
                  ),
                );
              },
            ),
          
          // Actual image - show when loaded
          if (!_isLoading && !_hasError && _imageProvider != null)
            ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: Image(
                image: _imageProvider!,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
              ),
            ),
          
          // Error widget
          if (_hasError)
            widget.errorWidget ??
                Container(
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius,
                    color: Colors.grey[300],
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
        ],
      ),
    );
  }
}
