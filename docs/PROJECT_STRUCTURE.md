# NutriPlan Project Structure

## Overview
This document outlines the professional organization of the NutriPlan Flutter application, which follows domain-driven design principles and industry best practices for maintainable codebases.

## Directory Structure

### Root Level
```
nutriplan/
├── android/                 # Android platform-specific code
├── ios/                    # iOS platform-specific code
├── web/                    # Web platform-specific code
├── linux/                  # Linux platform-specific code
├── macos/                  # macOS platform-specific code
├── windows/                # Windows platform-specific code
├── assets/                 # Static assets (fonts, images, etc.)
├── lib/                    # Main Dart source code
├── test/                   # Test files
├── docs/                   # Project documentation
├── fnri-food-composition-scraper/  # Data scraping utilities
└── pubspec.yaml           # Flutter dependencies
```

### Core Application Structure (`lib/`)

#### Main Entry Point
- `main.dart` - Application entry point and configuration

#### Models (`lib/models/`)
- `meal_history_entry.dart` - Meal history data model
- `recipes.dart` - Recipe data model
- `user_nutrition_goals.dart` - User nutrition goals model

#### Services (`lib/services/`)
- `ai_meal_suggestion_service.dart` - AI-powered meal suggestions
- `feedback_service.dart` - User feedback management
- `fnri_nutrition_service.dart` - FNRI nutrition data service
- `login_history_service.dart` - User login tracking
- `recipe_nutrition_updater_service.dart` - Recipe nutrition updates
- `recipe_service.dart` - Recipe management operations

#### Utils (`lib/utils/`)
- `responsive_design.dart` - Responsive design utilities

#### Widgets (`lib/widgets/`)
- `animated_logo.dart` - Animated application logo
- `bottom_navigation.dart` - Bottom navigation component
- `custom_back_button.dart` - Custom back button widget
- `decorative_auth_background.dart` - Authentication background
- `loading_screen.dart` - Loading state component
- `meal_log_card.dart` - Meal logging card widget

#### Screens (`lib/screens/`)
The screens are organized into domain-based subfolders with barrel files for clean imports:

##### Authentication (`lib/screens/auth/`)
- `index.dart` - Barrel file exporting all auth screens
- `login_screen.dart` - User login interface
- `signup_screen.dart` - User registration interface
- `verify_screen.dart` - Email verification interface
- `desktop_email_verification_screen.dart` - Desktop verification

##### Recipe Management (`lib/screens/recipes/`)
- `index.dart` - Barrel file exporting all recipe screens
- `recipes_page.dart` - Main recipes listing and meal plan builder
- `see_all_recipe.dart` - Complete recipe catalog
- `recipe_info_screen.dart` - Detailed recipe information
- `interactive_recipe_page.dart` - Interactive recipe interface
- `recipe_steps_summary_page.dart` - Recipe steps overview

##### Meal Planning (`lib/screens/meal_plan/`)
- `index.dart` - Barrel file exporting all meal planning screens
- `meal_planner_screen.dart` - Meal planning interface
- `meal_plan_history_screen.dart` - Meal plan history
- `meal_plan_confirmation_page.dart` - Meal plan confirmation
- `meal_summary_page.dart` - Meal plan summary
- `servings_selection_page.dart` - Serving size selection

##### Analytics (`lib/screens/analytics/`)
- `index.dart` - Barrel file exporting analytics screens
- `analytics_page.dart` - Nutrition and meal analytics

##### Feedback System (`lib/screens/feedback/`)
- `index.dart` - Barrel file exporting feedback screens
- `feedback_thank_you_page.dart` - Feedback confirmation

##### Meal Tracking (`lib/screens/tracking/`)
- `index.dart` - Barrel file exporting tracking screens
- `meal_tracker_screen.dart` - Daily meal tracking

##### User Profile (`lib/screens/profile/`)
- `index.dart` - Barrel file exporting profile screens
- `profile_screen.dart` - User profile management

##### Onboarding (`lib/screens/onboarding/`)
- `index.dart` - Barrel file exporting onboarding screens
- `dietary_preferences_screen.dart` - Dietary preference selection
- `allergy_selection_page.dart` - Allergy and restriction selection

##### AI Features (`lib/screens/ai/`)
- `index.dart` - Barrel file exporting AI screens
- `ai_meal_suggestions_screen.dart` - AI-powered meal suggestions

##### Home (`lib/screens/home/`)
- `index.dart` - Barrel file exporting home screens
- `home_page.dart` - Main application home

##### Shared Components (`lib/screens/shared/`)
- `index.dart` - Barrel file exporting shared screens
- `diet_type.dart` - Diet type definitions

## Import Strategy

### Barrel Files
Each domain subfolder contains an `index.dart` file that exports all related screens. This provides:

1. **Clean Imports**: Developers can import from domain folders instead of individual files
2. **Maintainability**: Easy to add/remove screens without updating multiple import statements
3. **Organization**: Clear separation of concerns by domain
4. **Backward Compatibility**: Existing imports continue to work

### Example Usage
```dart
// Before (scattered imports)
import 'package:nutriplan/screens/recipes_page.dart';
import 'package:nutriplan/screens/recipe_info_screen.dart';

// After (organized imports)
import 'package:nutriplan/screens/recipes/';
import 'package:nutriplan/screens/meal_plan/';
```

## Benefits of This Structure

### 1. **Domain Separation**
- Related functionality is grouped together
- Clear boundaries between different application areas
- Easier to understand and navigate

### 2. **Scalability**
- New features can be added to appropriate domains
- Easy to add new domains as the application grows
- Maintains organization as complexity increases

### 3. **Team Collaboration**
- Multiple developers can work on different domains
- Reduced merge conflicts
- Clear ownership of different areas

### 4. **Maintenance**
- Easier to locate specific functionality
- Simplified refactoring within domains
- Better code organization for debugging

### 5. **Testing**
- Domain-specific test organization
- Easier to write focused unit tests
- Better test coverage organization

## Migration Notes

### Existing Code
- All existing imports continue to work
- No breaking changes to current functionality
- Screens remain in their original locations

### Future Development
- New screens should be added to appropriate domain folders
- Update barrel files when adding new screens
- Consider creating new domains for major feature areas

## Best Practices

### 1. **Naming Conventions**
- Use descriptive, domain-specific names
- Follow Flutter naming conventions
- Maintain consistency across similar components

### 2. **File Organization**
- Keep related files together
- Use barrel files for clean exports
- Maintain logical grouping within domains

### 3. **Import Management**
- Prefer domain imports over individual file imports
- Keep imports organized and clean
- Avoid circular dependencies

### 4. **Documentation**
- Update this document when adding new domains
- Document any domain-specific conventions
- Maintain clear separation of concerns

## Conclusion

This organized structure provides a solid foundation for the NutriPlan application's continued growth and development. It follows industry best practices and makes the codebase more maintainable, scalable, and professional.

The domain-based organization ensures that related functionality is grouped together, making it easier for developers to understand and work with the codebase. The barrel file approach maintains clean imports while preserving backward compatibility.
