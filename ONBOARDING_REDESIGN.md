# 🎯 NutriPlan Onboarding Redesign

## ✨ What's New

The onboarding process has been completely redesigned to be more intuitive and personalized, focusing on **dish preferences** instead of abstract dietary types and **science-based nutrition goal calculation** based on user metrics.

**📱 New Flow:**
```
Dish Preferences → User Profile → Weight Goals → Nutrition Summary → Health Conditions → Allergies → Home
```

## 📱 New Onboarding Flow

### 1. **Dish Preferences** (`diet_type.dart` → redesigned)
- **🍽️ What Changed**: Instead of selecting abstract diet types like "Keto" or "Vegetarian"
- **🎯 New Approach**: Users select their favorite dish categories:
  - 🐟 Fish & Seafood (Bangus, tilapia, shrimp)
  - 🥩 Meat & Poultry (Chicken, pork, beef)
  - 🍲 Soups & Stews (Sinigang, tinola, bulalo)
  - 🍚 Rice Dishes (Fried rice, silog meals)
  - 🥗 Vegetables (Adobong kangkong, pinakbet)
  - 🍜 Noodles & Pasta (Pancit, spaghetti, bihon)
  - 🥘 Adobo & Braised (Chicken adobo, humba)
  - 🍳 Egg Dishes (Tortang talong, scrambled eggs)
  - 🌶️ Spicy Food (Bicol express, sisig)

### 2. **User Profile** (`user_profile_page.dart` → NEW)
- **📊 Personal Info**: Age, gender, height (cm), weight (kg)
- **🏃 Activity Level**: From sedentary to extremely active
- **🎨 Beautiful UI**: Clean form with validation and icons
- **⚡ Real-time Validation**: Ensures valid ranges for all inputs

### 3. **Weight Goals** (`weight_goal_page.dart` → NEW)
- **🎯 Clear Goals**:
  - 🔥 **Lose Weight**: 500 calorie deficit for 0.5-1kg/week loss
  - ⚖️ **Maintain Weight**: Balanced nutrition at TDEE
  - 💪 **Gain Weight**: 500 calorie surplus for 0.5-1kg/week gain
- **📊 BMI Display**: Shows current BMI and category
- **🧮 Smart Calculations**: Uses Mifflin-St Jeor equation for BMR

### 4. **Nutrition Goals Summary** (`nutrition_goals_summary_page.dart` → NEW)
- **📈 Personalized Goals**: Based on BMR, TDEE, and weight goal
- **🎯 Complete Breakdown**:
  - Daily calories with beautiful main card
  - Macronutrient distribution (protein/carbs/fat) with percentages
  - Micronutrients (fiber, sugar limits, cholesterol)
  - BMR/TDEE information for education
- **🎨 Visual Design**: Cards, colors, and icons for easy understanding

### 5. **Health Conditions** (`health_conditions_page.dart` → NEW)
- **🩺 Medical Conditions**:
  - Diabetes / High Blood Sugar (lower carbs, higher fiber)
  - Stroke Recovery (very low sodium, heart-healthy fats)
  - High Blood Pressure (low sodium, DASH principles)
  - Fitness Enthusiast (high protein, increased calories)
  - Kidney Disease (controlled protein, low sodium/phosphorus)
  - Heart Disease (low saturated fat, omega-3 focus)
  - Senior 65+ (higher protein, calcium, vitamin D)
- **🧮 Auto-Adjustments**: Nutrition goals automatically modified based on conditions
- **🎨 Color-coded UI**: Each condition has distinct colors and icons

### 6. **Allergies** (unchanged but improved navigation)
- **✅ Same Functionality**: Select food allergies and intolerances
- **🔄 Better Flow**: Now goes directly to home page after completion

## 🧮 Scientific Nutrition Calculation

### **BMR Calculation** (`nutrition_calculator_service.dart` → NEW)
Uses the **Mifflin-St Jeor Equation** (most accurate for modern populations):

**Men**: BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
**Women**: BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161

### **TDEE Calculation**
BMR × Activity Factor:
- **Sedentary**: 1.2 (desk job, no exercise)
- **Lightly Active**: 1.375 (light exercise 1-3 days/week)
- **Moderately Active**: 1.55 (moderate exercise 3-5 days/week)
- **Very Active**: 1.725 (hard exercise 6-7 days/week)
- **Extremely Active**: 1.9 (very hard exercise + physical job)

### **Calorie Adjustment**
- **Weight Loss**: TDEE - 500 calories (safe 0.5-1kg/week loss)
- **Weight Gain**: TDEE + 500 calories (healthy 0.5-1kg/week gain)
- **Maintenance**: TDEE (maintain current weight)
- **Safety Limits**: Minimum 1200 kcal (women) / 1500 kcal (men)

### **Macronutrient Distribution**
**Weight Loss** (higher protein):
- Protein: 30% of calories
- Fat: 25% of calories  
- Carbs: 45% of calories

**Weight Gain** (balanced):
- Protein: 20% of calories
- Fat: 30% of calories
- Carbs: 50% of calories

**Maintenance** (balanced):
- Protein: 25% of calories
- Fat: 25% of calories
- Carbs: 50% of calories

## 🗂️ Database Schema Updates

The `user_preferences` table now stores:

```sql
- dish_preferences: TEXT[] -- Array of selected dish categories
- age: INTEGER
- gender: TEXT
- height_cm: REAL
- weight_kg: REAL  
- activity_level: TEXT
- weight_goal: TEXT
- calorie_goal: REAL
- protein_goal: REAL
- carb_goal: REAL
- fat_goal: REAL
- fiber_goal: REAL
- sugar_goal: REAL
- cholesterol_goal: REAL
- bmr: REAL -- For reference
- tdee: REAL -- For reference
```

## 🚫 Removed Features

- **❌ Servings Selection**: Removed the confusing "how many servings" page
- **❌ Abstract Diet Types**: No more "Keto", "Vegan", etc. - replaced with concrete dish preferences
- **❌ Generic Nutrition Goals**: No more hardcoded 2000 calorie defaults

## ✅ Benefits

1. **🎯 More Intuitive**: Users understand "I like fish dishes" better than "I follow a pescatarian diet"
2. **🧬 Science-Based**: Nutrition goals calculated using proven BMR/TDEE formulas
3. **👤 Truly Personalized**: Goals based on individual age, gender, size, activity, and goals
4. **📱 Better UX**: Beautiful, modern interface with clear progression
5. **🎓 Educational**: Users learn their BMR, TDEE, and why their goals are set that way
6. **🇵🇭 Filipino-Focused**: Dish categories reflect actual Filipino cuisine preferences

## 🔄 Migration Path

Existing users will see the new onboarding flow when they next update their preferences. The app gracefully handles both old and new data structures through the updated `UserNutritionGoals` model.
