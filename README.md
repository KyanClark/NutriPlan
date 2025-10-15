# NutriPlan - Filipino Nutrition & Meal Planning App

A comprehensive Flutter-based mobile application designed to help users manage nutrition, plan meals, and track dietary habits with a focus on Filipino cuisine and local nutritional data.

## 🎯 Project Overview

NutriPlan is a feature-rich nutrition and meal planning application that leverages the Food and Nutrition Research Institute (FNRI) database to provide accurate nutritional information for Filipino ingredients and recipes. The app offers personalized meal suggestions, comprehensive meal tracking, and an intuitive user interface for managing dietary goals.

## ✨ Key Features

### 🍽️ **Recipe Management**
- **Comprehensive Recipe Database**: 100+ Filipino recipes with detailed ingredients and instructions
- **Automatic Nutrition Calculation**: FNRI-based nutrition data with real-time calculation
- **Recipe Categories**: Organized by diet types, allergies, and cooking methods
- **User Feedback System**: Rating and review system for community-driven improvements

### 🧮 **Smart Nutrition Calculator**
- **FNRI Integration**: Local CSV database with 1542+ Filipino ingredients
- **Data Validation**: Automatic filtering of nutrition data for accuracy
- **Realistic Calculations**: Conservative quantity estimation and validation ranges
- **Complete Dish Matchging**: Priority-based nutrition calculation for common Filipino dishes

### 📊 **Comprehensive Meal Tracking & Analytics**
- **Meal Categorization**: Breakfast, lunch, dinner, and snacks with detailed tracking
- **Nutritional Analytics**: Weekly and monthly calorie and macro comparisons
- **AI Insights**: Gemini-powered insights on trends and action items
- **Goal Management**: Customizable nutrition targets and progress monitoring
- **Meal History**: Complete record of dietary intake with search and filtering

### 🎨 **Modern User Interface**
- **Responsive Design**: Optimized for various screen sizes and orientations
- **Dynamic Navigation**: Scroll-based transparency effects for modern aesthetics
- **Intuitive Workflows**: Streamlined user experience with minimal manual intervention
- **Accessibility Features**: User-friendly design with clear visual hierarchy

## 🏗️ Technical Architecture

### **Frontend Framework**
- **Flutter**: Cross-platform mobile development with Dart programming language
- **State Management**: Efficient state handling with setState and custom services
- **UI Components**: Material Design 3 components with custom styling

### **Backend Services**
- **Supabase**: Real-time database with authentication and storage
- **Local Data Processing**: FNRI CSV parsing for offline nutrition calculations
- **API Integration**: Gemini AI for insights with caching and rate-limit mitigation

### **Data Management**
- **Nutrition Database**: FNRI food composition data with 1542+ ingredients
- **Recipe Storage**: Structured recipe data with ingredients, instructions, and nutrition
- **User Profiles**: Comprehensive user data management with dietary preferences

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Git for version control

### **Installation Steps**

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/nutriplan.git
   cd nutriplan
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase & Environment**
   - Create a Supabase project at [supabase.com](https://supabase.com)
   - Set environment variables (see below)
   - Set up the required database tables (see Database Schema section)

4. **Run the Application**
   ```bash
   flutter run
   ```

### **Environment Configuration**

Create a `.env` file in the project root:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
FNRI_DATA_PATH=assets/data/fnri_detailed_nutritional_data.csv
```

Notes:
- The `.gitignore` includes common env file patterns and API key names.
- Gemini calls are cached to reduce cost and avoid rate limiting.

## 📊 Database Schema

### **Core Tables**

#### **recipes**
```sql
CREATE TABLE recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  image_url TEXT,
  short_description TEXT,
  ingredients TEXT[] NOT NULL,
  instructions TEXT[] NOT NULL,
  macros JSONB,
  calories INTEGER,
  allergy_warning TEXT,
  diet_types TEXT[],
  cost DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **meal_history**
```sql
CREATE TABLE meal_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  recipe_id UUID REFERENCES recipes(id),
  meal_category TEXT NOT NULL,
  meal_time TIMESTAMP WITH TIME ZONE,
  nutrition_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **user_nutrition_goals**
```sql
CREATE TABLE user_nutrition_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  daily_calories INTEGER,
  daily_protein DECIMAL(5,2),
  daily_fat DECIMAL(5,2),
  daily_carbs DECIMAL(5,2),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🔧 Configuration

### **FNRI Data Integration**
The app uses local FNRI CSV data for nutrition calculations. Ensure the CSV file is placed in:
```
assets/data/fnri_detailed_nutritional_data.csv
```

### **Supabase Setup**
1. Enable Row Level Security (RLS) for all tables
2. Configure authentication providers (Google, Email)
3. Set up storage buckets for recipe images
4. Configure real-time subscriptions for live updates

## 📱 Usage Guide

### **For End Users**

#### **Getting Started**
1. **Account Creation**: Sign up with email or Google account
2. **Profile Setup**: Configure dietary preferences and nutrition goals
3. **Recipe Browsing**: Explore Filipino recipes with detailed nutrition information
4. **Meal Planning**: Create personalized meal plans with AI suggestions
5. **Progress Tracking**: Monitor nutritional intake and goal achievement

#### **Key Workflows**
- **Recipe Discovery**: Browse recipes by category, diet type, or ingredients
- **Meal Logging**: Record meals with automatic nutrition calculation
- **Goal Setting**: Define and track personalized nutrition targets
- **Analytics Review**: Analyze eating patterns and nutritional trends

### **For Developers**

#### **Adding New Features**
1. Follow the established project structure
2. Use consistent naming conventions (snake_case for files, camelCase for variables)
3. Implement proper error handling and validation
4. Add comprehensive documentation for new services

#### **Code Organization**
```
lib/
├── models/          # Data models and entities
├── screens/         # UI screens and pages
├── services/        # Business logic and external integrations
├── widgets/         # Reusable UI components
└── utils/           # Helper functions and utilities
```

## 🧪 Testing

### **Unit Tests**
```bash
flutter test
```

### **Integration Tests**
```bash
flutter test integration_test/
```

### **Manual Testing Checklist**
- [ ] User authentication and profile management
- [ ] Recipe browsing and nutrition calculation
- [ ] Meal tracking and categorization
- [ ] AI meal suggestions
- [ ] Data persistence and synchronization

## 📈 Performance & Caching

### **Optimization Strategies**
- **Local Data Caching**: FNRI nutrition data cached for offline access
- **Lazy Loading**: Images and data loaded on-demand
- **Efficient Queries**: Optimized database queries with proper indexing
- **Memory Management**: Proper disposal of controllers and listeners
 - **Gemini Caching**: AI insights and smart suggestions cached (5–10 mins)
 - **Request Deduping**: Avoid duplicate concurrent AI requests

### **Monitoring**
- Performance metrics tracking
- Error logging and reporting
- User analytics and behavior patterns

## 🔒 Security Features

### **Data Protection**
- **Authentication**: Secure user authentication with Supabase Auth
- **Authorization**: Row-level security for user data isolation
- **Input Validation**: Comprehensive input sanitization and validation
- **Secure Storage**: Encrypted storage for sensitive user information

## 🤝 Contributing

### **Development Guidelines**
1. **Code Style**: Follow Dart/Flutter best practices
2. **Documentation**: Maintain comprehensive code documentation
3. **Testing**: Ensure adequate test coverage for new features
4. **Review Process**: Submit pull requests for code review

### **Commit Message Format**
```
type(scope): brief description

- Use conventional commit types (feat, fix, docs, style, refactor, test, chore)
- Keep descriptions clear and professional
- Reference issues when applicable
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **FNRI (Food and Nutrition Research Institute)**: For providing comprehensive Filipino nutrition data
- **Flutter Team**: For the excellent cross-platform development framework
- **Supabase**: For the powerful backend-as-a-service platform
- **Open Source Community**: For contributing libraries and tools

## 📞 Support

### **Documentation**
- [API Documentation](docs/api.md)
- [User Guide](docs/user-guide.md)
- [Developer Guide](docs/developer-guide.md)

### **Contact**
- **Project Issues**: [GitHub Issues](https://github.com/yourusername/nutriplan/issues)
- **Feature Requests**: Submit through GitHub Issues
- **Technical Support**: Check documentation or create detailed issue reports

---

**NutriPlan** - Empowering Filipinos with intelligent nutrition management and meal planning solutions. 🍽️🇵🇭
