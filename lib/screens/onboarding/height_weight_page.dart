import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'activity_level_page.dart';
import '../../utils/onboarding_transitions.dart';

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
    // Initialize conversions once - no need to call setState here
    if (!_isHeightInFeet) {
      // Ensure feet/inches are synced with cm
      final totalInches = (_heightCm / 2.54).round();
      _heightFeet = totalInches ~/ 12;
      _heightInches = totalInches % 12;
    }
    if (_isWeightInKg) {
      // Ensure lbs are synced with kg
      _weightLbs = _weightKg * 2.20462;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF388E3C)),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 16),
              Text(
                'Height & Weight',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF388E3C),
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This helps us calculate your personalized nutrition goals. You can skip if you\'re not sure.',
                style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 20),
              
              // Height Section
              _buildHeightSection(),
              
              const SizedBox(height: 16),
              
              // Weight Section
              _buildWeightSection(),
              
              const SizedBox(height: 24),
              
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
                      OnboardingPageRoute(
                        page: ActivityLevelPage(
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
              
              const SizedBox(height: 12),
              
              // Skip Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      OnboardingPageRoute(
                        page: ActivityLevelPage(
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
              const SizedBox(height: 16), // Bottom padding for scroll
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeightSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showHeightDialog(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.height,
                  color: Color(0xFF4CAF50),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Height',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _skipHeight 
                          ? 'Tap to set height' 
                          : (_isHeightInFeet 
                              ? '$_heightFeet ft $_heightInches in' 
                              : '$_heightCm cm'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _skipHeight ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showHeightDialog() {
    int tempHeightCm = _heightCm;
    int tempHeightFeet = _heightFeet;
    int tempHeightInches = _heightInches;
    bool tempIsFeet = _isHeightInFeet;
    
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header with unit toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _skipHeight = true;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Skip'),
                      ),
                      // Unit Toggle
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                tempIsFeet = false;
                                tempHeightCm = ((tempHeightFeet * 12 + tempHeightInches) * 2.54).round();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: !tempIsFeet ? const Color(0xFF4CAF50) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'cm',
                                style: TextStyle(
                                  color: !tempIsFeet ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                tempIsFeet = true;
                                final totalInches = (tempHeightCm / 2.54).round();
                                tempHeightFeet = totalInches ~/ 12;
                                tempHeightInches = totalInches % 12;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: tempIsFeet ? const Color(0xFF4CAF50) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ft/in',
                                style: TextStyle(
                                  color: tempIsFeet ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _heightCm = tempHeightCm;
                            _heightFeet = tempHeightFeet;
                            _heightInches = tempHeightInches;
                            _isHeightInFeet = tempIsFeet;
                            _skipHeight = false;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Done', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: tempIsFeet
                        ? Row(
                            children: [
                              // Feet picker
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: (tempHeightFeet - 3).clamp(0, 5),
                                  ),
                                  itemExtent: 36,
                                  magnification: 1.1,
                                  useMagnifier: true,
                                  onSelectedItemChanged: (index) {
                                    setDialogState(() {
                                      tempHeightFeet = 3 + index;
                                      tempHeightCm = ((tempHeightFeet * 12 + tempHeightInches) * 2.54).round();
                                    });
                                  },
                                  children: List.generate(6, (index) {
                                    return Center(
                                      child: Text(
                                        '${3 + index} ft',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              // Inches picker
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: tempHeightInches.clamp(0, 11),
                                  ),
                                  itemExtent: 36,
                                  magnification: 1.1,
                                  useMagnifier: true,
                                  onSelectedItemChanged: (index) {
                                    setDialogState(() {
                                      tempHeightInches = index;
                                      tempHeightCm = ((tempHeightFeet * 12 + tempHeightInches) * 2.54).round();
                                    });
                                  },
                                  children: List.generate(12, (index) {
                                    return Center(
                                      child: Text(
                                        '$index in',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          )
                        : CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: (tempHeightCm - 100).clamp(0, 150),
                            ),
                            itemExtent: 36,
                            magnification: 1.1,
                            useMagnifier: true,
                            onSelectedItemChanged: (index) {
                              setDialogState(() {
                                tempHeightCm = 100 + index;
                                final totalInches = (tempHeightCm / 2.54).round();
                                tempHeightFeet = totalInches ~/ 12;
                                tempHeightInches = totalInches % 12;
                              });
                            },
                            children: List.generate(151, (index) {
                              return Center(
                                child: Text(
                                  '${100 + index} cm',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              );
                            }),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeightSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showWeightDialog(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monitor_weight,
                  color: Color(0xFF4CAF50),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weight',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _skipWeight 
                          ? 'Tap to set weight' 
                          : (_isWeightInKg 
                              ? '${_weightKg.toStringAsFixed(1)} kg' 
                              : '${_weightLbs.round()} lbs'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _skipWeight ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showWeightDialog() {
    double tempWeightKg = _weightKg;
    double tempWeightLbs = _weightLbs;
    bool tempIsKg = _isWeightInKg;
    
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final initialWeight = tempIsKg 
                ? tempWeightKg.round().clamp(30, 200) 
                : tempWeightLbs.round().clamp(66, 440);
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header with unit toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _skipWeight = true;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Skip'),
                      ),
                      // Unit Toggle
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                tempIsKg = true;
                                tempWeightKg = tempWeightLbs / 2.20462;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: tempIsKg ? const Color(0xFF4CAF50) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'kg',
                                style: TextStyle(
                                  color: tempIsKg ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                tempIsKg = false;
                                tempWeightLbs = tempWeightKg * 2.20462;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: !tempIsKg ? const Color(0xFF4CAF50) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'lbs',
                                style: TextStyle(
                                  color: !tempIsKg ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _weightKg = tempWeightKg;
                            _weightLbs = tempWeightLbs;
                            _isWeightInKg = tempIsKg;
                            _skipWeight = false;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Done', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: tempIsKg 
                            ? (initialWeight - 30).clamp(0, 170)
                            : (initialWeight - 66).clamp(0, 374),
                      ),
                      itemExtent: 36,
                      magnification: 1.1,
                      useMagnifier: true,
                      onSelectedItemChanged: (index) {
                        setDialogState(() {
                          if (tempIsKg) {
                            tempWeightKg = (30 + index).toDouble();
                            tempWeightLbs = tempWeightKg * 2.20462;
                          } else {
                            tempWeightLbs = (66 + index).toDouble();
                            tempWeightKg = tempWeightLbs / 2.20462;
                          }
                        });
                      },
                      children: List.generate(
                        tempIsKg ? 171 : 375,
                        (index) {
                          final value = tempIsKg ? (30 + index) : (66 + index);
                          final unit = tempIsKg ? ' kg' : ' lbs';
                          return Center(
                            child: Text(
                              '$value$unit',
                              style: const TextStyle(fontSize: 20),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  bool _canContinue() {
    return !_skipHeight || !_skipWeight;
  }
}
