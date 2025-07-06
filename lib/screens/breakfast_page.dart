import 'package:flutter/material.dart';
import '../main.dart';

class BreakfastPage extends StatelessWidget {
  const BreakfastPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(142, 190, 155, 1.0),
              Color.fromRGBO(125, 189, 228, 1.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Custom Header with Back Button
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Stack(
                children: [
                  // Centered title
                  Center(
                    child: Text(
                      'Breakfast',
                      style: TextStyle(
                        fontSize: ResponsiveDesign.responsiveFontSize(context, 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Header Content
            Container(
              padding: ResponsiveDesign.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Text(
                    'Start your day with nutritious and energizing meals',
                    style: TextStyle(
                      fontSize: ResponsiveDesign.responsiveFontSize(context, 14),
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: _buildEmptyState(context),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 200,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add breakfast meal functionality coming soon!'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          backgroundColor: const Color(0xFFFF6B6B),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Meal Plan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wb_sunny,
            size: isSmallScreen ? 64 : 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            'No Breakfast meals planned',
            style: TextStyle(
              fontSize: ResponsiveDesign.responsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            'Tap the + button to add your first breakfast meal',
            style: TextStyle(
              fontSize: ResponsiveDesign.responsiveFontSize(context, 14),
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
} 