# NutriPlan Project Structure & Organization

## 📁 Directory Structure

```
nutriplan/
├── android/                    # Android-specific configurations
├── ios/                       # iOS-specific configurations
├── lib/                       # Main Dart source code
│   ├── models/               # Data models and entities
│   ├── screens/              # UI screens and pages
│   ├── services/             # Business logic and external integrations
│   ├── widgets/              # Reusable UI components
│   └── utils/                # Helper functions and utilities
├── assets/                    # Static assets (images, data files)
│   ├── data/                 # CSV files and data sources
│   └── images/               # App images and icons
├── docs/                      # Project documentation
├── system_reports/            # Daily activity logs and system reports
├── test/                      # Unit and widget tests
├── web/                       # Web platform support
├── windows/                   # Windows platform support
├── macos/                     # macOS platform support
├── linux/                     # Linux platform support
├── pubspec.yaml              # Flutter dependencies and configuration
└── README.md                 # Project overview and setup instructions
```

## 🏗️ Architecture Patterns

### **Service Layer Architecture**
- **Business Logic**: Centralized in service classes
- **Data Access**: Abstracted through service interfaces
- **Dependency Injection**: Services injected where needed
- **Error Handling**: Consistent error handling across services

### **Model-View-Service (MVS)**
- **Models**: Data structures and business entities
- **Views**: UI screens and components
- **Services**: Business logic and data operations

## 📝 Naming Conventions

### **Files and Directories**
- **snake_case**: For file names and directory names
  - `meal_tracker_screen.dart`
  - `ai_meal_suggestion_service.dart`
  - `user_nutrition_goals.dart`

### **Classes and Types**
- **PascalCase**: For class names and type definitions
  - `MealTrackerScreen`
  - `AIMealSuggestionService`
  - `UserNutritionGoals`

### **Variables and Methods**
- **camelCase**: For variables, methods, and properties
  - `mealHistory`
  - `calculateNutrition()`
  - `userPreferences`

### **Constants**
- **SCREAMING_SNAKE_CASE**: For global constants
  - `MAX_RECIPE_TITLE_LENGTH`
  - `DEFAULT_SERVING_SIZE`
  - `API_TIMEOUT_DURATION`

## 🔧 Code Organization Guidelines

### **File Structure Standards**

#### **Models** (`lib/models/`)
```dart
// File: user_nutrition_goals.dart
class UserNutritionGoals {
  // 1. Static constants
  static const int maxCalories = 5000;
  
  // 2. Instance variables
  final String id;
  final int dailyCalories;
  
  // 3. Constructor
  const UserNutritionGoals({
    required this.id,
    required this.dailyCalories,
  });
  
  // 4. Factory constructors
  factory UserNutritionGoals.fromMap(Map<String, dynamic> map) {
    // Implementation
  }
  
  // 5. Methods
  Map<String, dynamic> toMap() {
    // Implementation
  }
}
```

#### **Services** (`lib/services/`)
```dart
// File: nutrition_calculator_service.dart
class NutritionCalculatorService {
  // 1. Private variables
  static final Map<String, dynamic> _cache = {};
  
  // 2. Public methods
  static Future<Map<String, dynamic>> calculateNutrition(
    List<String> ingredients,
  ) async {
    // Implementation
  }
  
  // 3. Private helper methods
  static Map<String, dynamic> _validateResults(
    Map<String, dynamic> results,
  ) {
    // Implementation
  }
}
```

#### **Screens** (`lib/screens/`)
```dart
// File: meal_tracker_screen.dart
class MealTrackerScreen extends StatefulWidget {
  // 1. Constructor and required parameters
  const MealTrackerScreen({
    super.key,
    required this.userId,
  });
  
  final String userId;
  
  @override
  State<MealTrackerScreen> createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends State<MealTrackerScreen> {
  // 1. Controllers and variables
  late ScrollController _scrollController;
  
  // 2. State variables
  bool _isLoading = false;
  List<MealHistoryEntry> _meals = [];
  
  // 3. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }
  
  // 4. Public methods
  Future<void> _loadMeals() async {
    // Implementation
  }
  
  // 5. Private helper methods
  void _initializeScreen() {
    // Implementation
  }
  
  // 6. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI implementation
    );
  }
}
```

### **Import Organization**
```dart
// 1. Dart core libraries
import 'dart:async';
import 'dart:convert';

// 2. Flutter libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// 4. Local imports (relative paths)
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../widgets/recipe_card.dart';

// 5. Local imports (absolute paths)
import 'package:nutriplan/utils/constants.dart';
```

## 🎯 Best Practices

### **Code Quality Standards**
1. **Documentation**: All public methods must have documentation comments
2. **Error Handling**: Comprehensive error handling with user-friendly messages
3. **Validation**: Input validation for all user inputs
4. **Performance**: Efficient algorithms and data structures
5. **Testing**: Unit tests for all business logic

### **UI/UX Guidelines**
1. **Consistency**: Use consistent spacing, colors, and typography
2. **Accessibility**: Support for screen readers and accessibility features
3. **Responsiveness**: Optimize for different screen sizes
4. **Loading States**: Always show loading indicators for async operations
5. **Error States**: Clear error messages with recovery options

### **Database Design**
1. **Normalization**: Proper database normalization
2. **Indexing**: Strategic use of database indexes
3. **Constraints**: Appropriate foreign key and check constraints
4. **Security**: Row-level security for user data isolation

## 📊 Data Flow Patterns

### **Recipe Management Flow**
```
User Input → Validation → Service Layer → Database → Response → UI Update
```

### **Nutrition Calculation Flow**
```
Ingredients → FNRI Service → Data Validation → Calculation → Result → Storage
```

### **Meal Tracking Flow**
```
Meal Log → Categorization → Nutrition Calculation → Database → Analytics Update
```

## 🔄 State Management

### **Local State**
- **setState**: For simple component state
- **ValueNotifier**: For reactive state changes
- **ChangeNotifier**: For complex state management

### **Global State**
- **Services**: Singleton services for global state
- **Event Bus**: For cross-component communication
- **Shared Preferences**: For persistent user settings

## 🧪 Testing Strategy

### **Test Organization**
```
test/
├── unit/                     # Unit tests for services and models
├── widget/                   # Widget tests for UI components
└── integration/              # Integration tests for workflows
```

### **Test Naming**
```dart
// File: test/unit/services/nutrition_calculator_service_test.dart
void main() {
  group('NutritionCalculatorService', () {
    test('should calculate nutrition for valid ingredients', () async {
      // Test implementation
    });
    
    test('should handle empty ingredient list', () async {
      // Test implementation
    });
  });
}
```

## 📈 Performance Guidelines

### **Memory Management**
1. **Dispose Controllers**: Always dispose of controllers in dispose method
2. **Image Caching**: Implement proper image caching strategies
3. **List Optimization**: Use ListView.builder for large lists
4. **Async Operations**: Cancel unnecessary async operations

### **Database Optimization**
1. **Query Efficiency**: Optimize database queries
2. **Connection Pooling**: Efficient database connection management
3. **Caching**: Implement appropriate caching strategies
4. **Batch Operations**: Use batch operations for multiple updates

## 🔒 Security Considerations

### **Data Protection**
1. **Input Sanitization**: Validate and sanitize all user inputs
2. **Authentication**: Secure user authentication
3. **Authorization**: Proper access control for user data
4. **Encryption**: Encrypt sensitive data in storage

### **API Security**
1. **Rate Limiting**: Implement API rate limiting
2. **Input Validation**: Validate all API inputs
3. **Error Handling**: Don't expose sensitive information in errors
4. **HTTPS**: Use secure connections for all API calls

## 📝 Documentation Standards

### **Code Comments**
```dart
/// Calculates the total nutrition for a recipe based on ingredients.
/// 
/// This method processes the ingredient list and calculates the total
/// nutritional values using the FNRI database.
/// 
/// Parameters:
/// - [ingredients]: List of ingredient names
/// - [quantities]: Map of ingredient names to quantities in grams
/// 
/// Returns a [Map] containing the calculated nutrition values.
/// 
/// Throws [NutritionCalculationException] if ingredients cannot be processed.
Future<Map<String, dynamic>> calculateRecipeNutrition(
  List<String> ingredients,
  Map<String, double> quantities,
) async {
  // Implementation
}
```

### **README Updates**
- Update README.md when adding new features
- Document breaking changes clearly
- Include setup instructions for new dependencies
- Update usage examples for new functionality

## 🚀 Deployment Guidelines

### **Build Configuration**
1. **Environment Variables**: Use proper environment configuration
2. **Build Variants**: Configure debug, release, and staging builds
3. **Code Signing**: Proper code signing for production releases
4. **Version Management**: Consistent version numbering

### **Release Process**
1. **Testing**: Comprehensive testing before release
2. **Documentation**: Update release notes and documentation
3. **Deployment**: Staged deployment to production
4. **Monitoring**: Monitor application performance post-release

---

This structure ensures maintainable, scalable, and professional code quality throughout the NutriPlan project. Follow these guidelines to maintain consistency and best practices across all development activities.
