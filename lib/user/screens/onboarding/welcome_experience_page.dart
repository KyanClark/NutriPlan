import 'package:flutter/material.dart';

import 'dishes_preferences.dart';
import '../../utils/onboarding_transitions.dart';

class WelcomeExperiencePage extends StatefulWidget {
  const WelcomeExperiencePage({super.key});

  @override
  State<WelcomeExperiencePage> createState() => _WelcomeExperiencePageState();
}

class _WelcomeExperiencePageState extends State<WelcomeExperiencePage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  
  // Animation controllers for first slide
  late AnimationController _logoPopController;
  late AnimationController _textEntranceController;
  late AnimationController _titleSlideController; // Separate controller for slide animation
  late AnimationController _contentController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _textSlideFromLeft;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  bool _animationComplete = false; // Track when animation is done

  final List<_WelcomeContent> _pages = [
    _WelcomeContent(
      backgroundColor: const Color(0xFF1B5E20),
      title: 'NutriPlan',
      subtitle: 'What is NutriPlan?',
      body: 'Your personal nutrition companion that makes meal planning simple and stress-free.\n\nMeal planning shouldn\'t be stressful.\nLet NutriPlan guide you—one smart choice at a time.',
      centerIcon: Icons.energy_savings_leaf,
      isIntro: true,
    ),
    _WelcomeContent(
      backgroundColor: Colors.white,
      title: 'Why NutriPlan works',
      subtitle: 'A coaching style experience without the overwhelm.',
      bulletPoints: [
        'Adapts to your health goals, allergies, and eating habits',
        'Generates realistic meal plans and grocery lists',
        'Keeps track of nutrition, portions, and habits',
      ],
      illustration: Icons.auto_awesome,
    ),
    _WelcomeContent(
      backgroundColor: Colors.white,
      title: 'Core features you\'ll love',
      subtitle: 'Built to guide you at every step.',
      bulletPoints: [
        'Interactive recipe guides with step-by-step instructions',
        'Smart meal planner with calendar-based planning',
        'Smart suggestions when cravings hit',
        'Calorie visuals and daily progress summaries',
      ],
      illustration: Icons.favorite_outline,
    ),
    _WelcomeContent(
      backgroundColor: Colors.white,
      title: 'Your NutriPlan journey',
      subtitle: 'Plan • Track • Improve',
      timeline: [
        TimelineStep(
          icon: Icons.event_note,
          title: 'Plan',
          description: 'Receive curated meals matched to your goals & flavor profile.',
        ),
        TimelineStep(
          icon: Icons.insights,
          title: 'Track',
          description: 'Log meals, monitor nutrition, and learn from smart summaries.',
        ),
        TimelineStep(
          icon: Icons.auto_graph,
          title: 'Improve',
          description: 'Get actionable insights and grocery support to stay consistent.',
        ),
      ],
      closingMessage:
          'Ready to eat better with less guesswork?\nTake a breath, feel excited—we\'ll build this together.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _logoPopController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textEntranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _titleSlideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Logo pop-in
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoPopController, curve: Curves.easeOutBack),
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoPopController, curve: Curves.easeOut),
    );
    // Text slides from left
    _textSlideFromLeft = Tween<Offset>(
      begin: const Offset(-0.4, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textEntranceController, curve: Curves.easeOutCubic),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textEntranceController, curve: Curves.easeOut),
    );
    // Title slide up animation - from center (0.5) to title position (0.2)
    // Slide distance: 0.2 - 0.5 = -0.3 (30% of screen height up)
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0), // Starts at dead center (relative to widget)
      end: const Offset(0, -0.30), // Slides up 30% to reach title position (20% from top)
    ).animate(
      CurvedAnimation(parent: _titleSlideController, curve: Curves.easeInOut),
    );
    // Content fade in animation
    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    
    // Start animations after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageIndex == 0) {
        _startIntroAnimations();
      }
    });
  }

  void _startIntroAnimations() {
    setState(() => _animationComplete = false);
    _logoPopController.reset();
    _textEntranceController.reset();
    _titleSlideController.reset();
    _contentController.reset();

    _logoPopController.forward().then((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        _textEntranceController.forward().then((_) {
          if (!mounted) return;
          Future.delayed(const Duration(milliseconds: 150), () {
            if (!mounted) return;
            _titleSlideController.forward().then((_) {
              if (!mounted) return;
              Future.delayed(const Duration(milliseconds: 200), () {
                if (!mounted) return;
                _contentController.forward().then((_) {
                  if (mounted) {
                    setState(() => _animationComplete = true);
                  }
                });
              });
            });
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _logoPopController.dispose();
    _textEntranceController.dispose();
    _titleSlideController.dispose();
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _pageIndex == _pages.length - 1;
    final isFirstPage = _pageIndex == 0;
    final greenBackground = const Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: isFirstPage ? greenBackground : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Hide back button and skip button on first page
            if (!isFirstPage)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                      onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                    ),
                    TextButton(
                      onPressed: () => _continueToSetup(context),
                      child: const Text('Skip', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _pageIndex = index);
                  // Restart animations when returning to first slide
                  if (index == 0) {
                    _startIntroAnimations();
                  } else {
                    setState(() => _animationComplete = true);
                  }
                },
                itemBuilder: (context, index) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: _buildPage(_pages[index]),
                ),
              ),
            ),
            // Show page indicator and next button (on first page, only after animation completes)
            if (!isFirstPage || _animationComplete) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _buildPageIndicator(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isFirstPage ? Colors.white : greenBackground,
                      foregroundColor: isFirstPage ? greenBackground : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (isLastPage) {
                        _continueToSetup(context);
                      } else {
                        _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
                      }
                    },
                    child: Text(isLastPage ? 'Let\'s get started!' : 'Next'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_WelcomeContent content) {
    final theme = Theme.of(context);
    final isIntro = content.isIntro;
    final textColor = isIntro ? Colors.white : Colors.black87;
    final secondaryText = isIntro ? Colors.white70 : Colors.grey[700];

    return Container(
      key: ValueKey(content.title),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isIntro ? Colors.transparent : content.backgroundColor,
        borderRadius: BorderRadius.circular(content.backgroundColor == Colors.white ? 0 : 28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.isIntro) ...[
            // Center the NutriPlan text and descriptions
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = constraints.maxHeight;
                  final centerY = screenHeight / 2;
                  final titleY = screenHeight * 0.20; // Title position (20% from top)
                  
                  return Stack(
                    children: [
                      // NutriPlan text - starts at dead center, slides to title position
                      AnimatedBuilder(
                        animation: _titleSlideAnimation,
                        builder: (context, child) {
                          // Calculate slide distance: from center (0.5) to title position (0.2) = -0.3
                          // Animation goes from 0 to -0.3, so multiply by screen height
                          final slideOffset = _titleSlideAnimation.value.dy * screenHeight;
                          return Positioned(
                            top: centerY - 21 + slideOffset, // Start at center, slide up
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ScaleTransition(
                                    scale: _logoScaleAnimation,
                                    child: FadeTransition(
                                      opacity: _logoFadeAnimation,
                                      child: Image.asset(
                                        'assets/widgets/NutriPlan_Logo.png',
                                        height: 60,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  SlideTransition(
                                    position: _textSlideFromLeft,
                                    child: FadeTransition(
                                      opacity: _textFadeAnimation,
                                      child: Text(
                                        'NutriPlan',
                                        style: theme.textTheme.displayLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          fontSize: 42,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Animated body - fade in after title slides up (subtitle removed)
                      Positioned(
                        top: titleY + 60, // Position below where title will be
                        left: 0,
                        right: 0,
                        child: FadeTransition(
                          opacity: _contentFadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              content.body!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                height: 1.6,
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ] else
            const SizedBox(height: 32),
          if (!content.isIntro) ...[
            Text(
              content.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryText,
                height: 1.5,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (content.bulletPoints != null) ...[
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: content.bulletPoints!.map(
                    (text) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: content.backgroundColor == Colors.white ? Colors.grey[100] : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            content.illustration ?? Icons.bolt,
                            color: const Color(0xFF4CAF50),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              text,
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ),
          ] else if (content.timeline != null) ...[
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    ...content.timeline!.map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(step.icon, color: const Color(0xFF4CAF50)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      content.closingMessage ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[800],
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    final isFirstPage = _pageIndex == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = _pageIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 22 : 8,
          decoration: BoxDecoration(
            color: isActive 
                ? (isFirstPage ? Colors.white : const Color(0xFF4CAF50))
                : (isFirstPage ? Colors.white.withOpacity(0.4) : Colors.black26),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
  void _continueToSetup(BuildContext context) {
    Navigator.pushReplacement(
      context,
      OnboardingPageRoute(page: const DietTypePage()),
    );
  }
}

class _WelcomeContent {
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final String? body;
  final IconData? centerIcon;
  final List<String>? bulletPoints;
  final IconData? illustration;
  final List<TimelineStep>? timeline;
  final String? closingMessage;
  final bool isIntro;

  _WelcomeContent({
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    this.body,
    this.centerIcon,
    this.bulletPoints,
    this.illustration,
    this.timeline,
    this.closingMessage,
    this.isIntro = false,
  });
}

class TimelineStep {
  final IconData icon;
  final String title;
  final String description;

  TimelineStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}