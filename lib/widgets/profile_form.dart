import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileForm extends StatefulWidget {
  final UserProfile? initialProfile;
  final void Function(UserProfile) onSave;

  const ProfileForm({super.key, this.initialProfile, required this.onSave});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late List<String> _dietaryPreferences;
  late String _healthGoal;
  late List<String> _allergies;
  late double _budget;

  final List<String> dietaryOptions = [
    'Vegetarian', 'Vegan', 'Pescatarian', 'Keto', 'Halal', 'Kosher', 'None'
  ];
  final List<String> healthGoals = [
    'Weight Loss', 'Muscle Gain', 'Maintenance', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _name = p?.name ?? '';
    _dietaryPreferences = List<String>.from(p?.dietaryPreferences ?? []);
    _healthGoal = p?.healthGoal ?? healthGoals[0];
    _allergies = List<String>.from(p?.allergies ?? []);
    _budget = p?.budget ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
              onSaved: (v) => _name = v ?? '',
            ),
            const SizedBox(height: 12),
            Text('Dietary Preferences'),
            Wrap(
              spacing: 8,
              children: dietaryOptions.map((option) {
                final selected = _dietaryPreferences.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _dietaryPreferences.add(option);
                      } else {
                        _dietaryPreferences.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _healthGoal,
              decoration: const InputDecoration(labelText: 'Health Goal'),
              items: healthGoals.map((goal) => DropdownMenuItem(
                value: goal,
                child: Text(goal),
              )).toList(),
              onChanged: (v) => setState(() => _healthGoal = v ?? healthGoals[0]),
            ),
            const SizedBox(height: 12),
            Text('Allergies'),
            TextFormField(
              initialValue: _allergies.join(', '),
              decoration: const InputDecoration(hintText: 'e.g. peanuts, gluten'),
              onSaved: (v) => _allergies = v == null ? [] : v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _budget == 0.0 ? '' : _budget.toString(),
              decoration: const InputDecoration(labelText: 'Budget ( A3, 24, etc.)'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your budget';
                final val = double.tryParse(v);
                if (val == null || val < 0) return 'Enter a valid number';
                return null;
              },
              onSaved: (v) => _budget = double.tryParse(v ?? '') ?? 0.0,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    widget.onSave(UserProfile(
                      name: _name,
                      dietaryPreferences: _dietaryPreferences,
                      healthGoal: _healthGoal,
                      allergies: _allergies,
                      budget: _budget,
                    ));
                  }
                },
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 