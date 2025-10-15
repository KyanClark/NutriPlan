import 'package:flutter/material.dart';
import 'activity_level_page.dart';

class HeightWeightPage extends StatefulWidget {
  final int age;
  final String sex;
  
  const HeightWeightPage({
    super.key,
    required this.age,
    required this.sex,
  });

  @override
  State<HeightWeightPage> createState() => _HeightWeightPageState();
}

class _HeightWeightPageState extends State<HeightWeightPage> {
  // Height variables
  bool _isHeightInFeet = false;
  int _heightFeet = 5;
  int _heightInches = 6;
  int _heightCm = 170;
  
  // Weight variables
  bool _isWeightInKg = true;
  double _weightKg = 70.0;
  double _weightLbs = 154.0;
  
  // Skip options
  bool _skipHeight = false;
  bool _skipWeight = false;

  @override
  void initState() {
    super.initState();
    _updateHeightConversion();
    _updateWeightConversion();
  }

  void _updateHeightConversion() {
    if (_isHeightInFeet) {
      // Convert feet/inches to cm
      _heightCm = ((_heightFeet * 12 + _heightInches) * 2.54).round();
    } else {
      // Convert cm to feet/inches
      final totalInches = (_heightCm / 2.54).round();
      _heightFeet = totalInches ~/ 12;
      _heightInches = totalInches % 12;
    }
  }

  void _updateWeightConversion() {
    if (_isWeightInKg) {
      // Convert kg to lbs
      _weightLbs = _weightKg * 2.20462;
    } else {
      // Convert lbs to kg
      _weightKg = _weightLbs / 2.20462;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Height & Weight'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Height & Weight',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This helps us calculate your personalized nutrition goals. You can skip if you\'re not sure.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            
            // Height Section
            _buildHeightSection(),
            
            const SizedBox(height: 32),
            
            // Weight Section
            _buildWeightSection(),
            
            const Spacer(),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _canContinue() ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityLevelPage(
                        age: widget.age,
                        sex: widget.sex,
                        heightCm: _skipHeight ? null : _heightCm.toDouble(),
                        weightKg: _skipWeight ? null : _weightKg,
                      ),
                    ),
                  );
                } : null,
                child: Text(
                  _canContinue() ? 'Continue' : 'Skip Height & Weight',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Skip Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityLevelPage(
                        age: widget.age,
                        sex: widget.sex,
                        heightCm: null,
                        weightKg: null,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Skip Height & Weight',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Height',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _skipHeight ? Colors.grey : const Color(0xFF388E3C),
                ),
              ),
            ),
            Switch(
              value: !_skipHeight,
              onChanged: (value) {
                setState(() {
                  _skipHeight = !value;
                });
              },
              activeThumbColor: const Color(0xFF4CAF50),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (!_skipHeight) ...[
          // Unit Toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isHeightInFeet = false;
                      _updateHeightConversion();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isHeightInFeet ? const Color(0xFF4CAF50) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: const Color(0xFF4CAF50),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Centimeters',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_isHeightInFeet ? Colors.white : const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isHeightInFeet = true;
                      _updateHeightConversion();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isHeightInFeet ? const Color(0xFF4CAF50) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: const Color(0xFF4CAF50),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Feet & Inches',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isHeightInFeet ? Colors.white : const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Height Picker
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _isHeightInFeet ? _buildFeetInchesPicker() : _buildCmPicker(),
          ),
        ],
      ],
    );
  }

  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Weight',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _skipWeight ? Colors.grey : const Color(0xFF388E3C),
                ),
              ),
            ),
            Switch(
              value: !_skipWeight,
              onChanged: (value) {
                setState(() {
                  _skipWeight = !value;
                });
              },
              activeThumbColor: const Color(0xFF4CAF50),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (!_skipWeight) ...[
          // Unit Toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isWeightInKg = true;
                      _updateWeightConversion();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isWeightInKg ? const Color(0xFF4CAF50) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: const Color(0xFF4CAF50),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Kilograms',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isWeightInKg ? Colors.white : const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isWeightInKg = false;
                      _updateWeightConversion();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isWeightInKg ? const Color(0xFF4CAF50) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: const Color(0xFF4CAF50),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Pounds',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_isWeightInKg ? Colors.white : const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Weight Picker
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _isWeightInKg ? _buildKgPicker() : _buildLbsPicker(),
          ),
        ],
      ],
    );
  }

  Widget _buildCmPicker() {
    return Row(
      children: [
        Expanded(
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _heightCm = 100 + index;
                _updateHeightConversion();
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final value = 100 + index;
                final isSelected = value == _heightCm;
                return Center(
                  child: Text(
                    '$value cm',
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
                    ),
                  ),
                );
              },
              childCount: 151, // 100-250 cm
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeetInchesPicker() {
    return Row(
      children: [
        Expanded(
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _heightFeet = 3 + index;
                _updateHeightConversion();
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final value = 3 + index;
                final isSelected = value == _heightFeet;
                return Center(
                  child: Text(
                    '$value ft',
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
                    ),
                  ),
                );
              },
              childCount: 5, // 3-7 feet
            ),
          ),
        ),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _heightInches = index;
                _updateHeightConversion();
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final isSelected = index == _heightInches;
                return Center(
                  child: Text(
                    '$index in',
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
                    ),
                  ),
                );
              },
              childCount: 12, // 0-11 inches
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKgPicker() {
    return Row(
      children: [
        Expanded(
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _weightKg = 30.0 + (index * 0.5);
                _updateWeightConversion();
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final value = 30.0 + (index * 0.5);
                final isSelected = (value - _weightKg).abs() < 0.1;
                return Center(
                  child: Text(
                    '${value.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
                    ),
                  ),
                );
              },
              childCount: 341, // 30-200 kg in 0.5 increments
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLbsPicker() {
    return Row(
      children: [
        Expanded(
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _weightLbs = 66.0 + index;
                _updateWeightConversion();
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final value = 66.0 + index;
                final isSelected = value.round() == _weightLbs.round();
                return Center(
                  child: Text(
                    '${value.round()} lbs',
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
                    ),
                  ),
                );
              },
              childCount: 235, // 66-300 lbs
            ),
          ),
        ),
      ],
    );
  }

  bool _canContinue() {
    return !_skipHeight || !_skipWeight;
  }
}
