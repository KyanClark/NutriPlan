import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin/admin_feedback_service.dart';

class FeedbackManagementTab extends StatefulWidget {
  const FeedbackManagementTab({super.key});

  @override
  State<FeedbackManagementTab> createState() => _FeedbackManagementTabState();
}

class _FeedbackManagementTabState extends State<FeedbackManagementTab> {
  List<Map<String, dynamic>> _feedbacks = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _filterRating = 'all';
  String _filterRecipe = 'all';
  List<Map<String, dynamic>> _recipes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AdminFeedbackService.getAllFeedbacks(),
        AdminFeedbackService.getOverallFeedbackStats(),
      ]);

      final feedbacks = results[0] as List<Map<String, dynamic>>;
      final stats = results[1] as Map<String, dynamic>;

      // Extract unique recipes from feedbacks
      final recipeMap = <String, Map<String, dynamic>>{};
      for (final feedback in feedbacks) {
        final recipe = feedback['recipes'] as Map<String, dynamic>?;
        if (recipe != null) {
          recipeMap[recipe['id'].toString()] = recipe;
        }
      }
      _recipes = recipeMap.values.toList();

      setState(() {
        _feedbacks = feedbacks;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading feedback: $e')),
        );
      }
    }
  }

  Future<void> _deleteFeedback(Map<String, dynamic> feedback) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AdminFeedbackService.deleteFeedback(feedback['id'].toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback deleted successfully')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting feedback: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredFeedbacks {
    var filtered = _feedbacks;

    if (_filterRating != 'all') {
      final rating = int.tryParse(_filterRating);
      if (rating != null) {
        filtered = filtered.where((f) => f['rating'] == rating).toList();
      }
    }

    if (_filterRecipe != 'all') {
      filtered = filtered.where((f) {
        final recipe = f['recipes'] as Map<String, dynamic>?;
        return recipe?['id'].toString() == _filterRecipe;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsCard(),
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredFeedbacks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.feedback_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No feedback found',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredFeedbacks.length,
                        itemBuilder: (context, index) {
                          final feedback = _filteredFeedbacks[index];
                          return _FeedbackCard(
                            feedback: feedback,
                            onDelete: () => _deleteFeedback(feedback),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final total = _stats['totalFeedbacks'] ?? 0;
    final avgRating = _stats['averageRating'] ?? 0.0;
    final totalRecipes = _stats['totalRecipes'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.feedback,
            value: total.toString(),
            label: 'Total Feedback',
          ),
          _StatItem(
            icon: Icons.star,
            value: avgRating.toStringAsFixed(1),
            label: 'Avg Rating',
          ),
          _StatItem(
            icon: Icons.restaurant_menu,
            value: totalRecipes.toString(),
            label: 'Recipes',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterRating,
              decoration: InputDecoration(
                labelText: 'Filter by Rating',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Ratings')),
                DropdownMenuItem(value: '5', child: Text('5 Stars')),
                DropdownMenuItem(value: '4', child: Text('4 Stars')),
                DropdownMenuItem(value: '3', child: Text('3 Stars')),
                DropdownMenuItem(value: '2', child: Text('2 Stars')),
                DropdownMenuItem(value: '1', child: Text('1 Star')),
              ],
              onChanged: (value) {
                setState(() => _filterRating = value ?? 'all');
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterRecipe,
              decoration: InputDecoration(
                labelText: 'Filter by Recipe',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Recipes')),
                ..._recipes.map((recipe) => DropdownMenuItem(
                      value: recipe['id'].toString(),
                      child: Text(
                        recipe['title'] ?? 'Unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: (value) {
                setState(() => _filterRecipe = value ?? 'all');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> feedback;
  final VoidCallback onDelete;

  const _FeedbackCard({
    required this.feedback,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rating = feedback['rating'] as int? ?? 0;
    final comment = feedback['comment'] as String? ?? '';
    final createdAt = feedback['created_at'] as String?;
    final recipe = feedback['recipes'] as Map<String, dynamic>?;
    final profile = feedback['profiles'] as Map<String, dynamic>?;
    final username = profile?['username'] ?? 'Anonymous';
    final recipeTitle = recipe?['title'] ?? 'Unknown Recipe';

    final dateFormat = DateFormat('MMM d, y • h:mm a');
    final date = createdAt != null
        ? dateFormat.format(DateTime.parse(createdAt))
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipeTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by $username',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comment,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

