# 🔄 Updated Dietary Preferences Screen

## ✅ **Complete Redesign - Now Saves ALL New Onboarding Data!**

The dietary preferences screen has been completely redesigned to handle all the new comprehensive user data from the redesigned onboarding flow.

---

## 📱 **What the Screen Now Shows**

### **📊 Nutrition Goals Summary Card**
```
📊 Your Current Goals
🔥 2,400 kcal    🥩 180g    🍚 270g    🥑 80g
   Calories      Protein     Carbs      Fat
```
- **Real-time display** of calculated nutrition goals
- **Updates automatically** when health conditions change
- **Color-coded** with green theme

### **🍽️ Food Preferences Section**

#### **1. Favorite Dishes** 
- **🐟 Fish & Seafood** - Bangus, tilapia, shrimp, crab, squid
- **🥩 Meat & Poultry** - Chicken, pork, beef, turkey  
- **🍲 Soups & Stews** - Sinigang, tinola, bulalo, nilaga
- **🍚 Rice Dishes** - Fried rice, silog meals, biryani
- **🥗 Vegetables** - Adobong kangkong, pinakbet, chopsuey
- **🍜 Noodles & Pasta** - Pancit, spaghetti, bihon, mami
- **🥘 Adobo & Braised** - Chicken adobo, pork adobo, humba
- **🍳 Egg Dishes** - Tortang talong, scrambled eggs, omelet
- **🌶️ Spicy Food** - Bicol express, sisig, spicy wings

#### **2. Health Conditions**
- **✅ None** - No specific health conditions
- **🩺 Diabetes** - Lower carbs, higher fiber
- **🧠 Stroke Recovery** - Low sodium, heart-healthy fats
- **🫀 High Blood Pressure** - Very low sodium, DASH diet
- **💪 Fitness Enthusiast** - High protein, increased calories
- **🫘 Kidney Disease** - Controlled protein, low sodium
- **❤️ Heart Disease** - Low saturated fat, omega-3 rich
- **👴 Senior (65+)** - Higher protein, calcium, vitamin D
- **🩸 Anemia** - Iron-rich foods, vitamin C
- **🍺 Fatty Liver** - Very low sugar, reduced fats
- **🌾 Malnutrition** - High calories, nutrient-dense foods

#### **3. Allergies & Restrictions**
- Dairy, Eggs, Peanuts, Tree Nuts, Soy
- Wheat/Gluten, Fish, Shellfish, Sesame

### **👤 Profile Information Section**

#### **Visual Cards Display:**
```
[🎂]     [👨]      [📏]      [⚖️]
 25      MALE     175 cm    70 kg
Age     Gender    Height    Weight
```

---

## 🔧 **Key Features**

### **✅ Complete Data Management**
- **Loads** all existing user preferences from Supabase
- **Saves** all changes with automatic nutrition goal recalculation
- **Displays** current nutrition goals prominently
- **Handles** health condition adjustments automatically

### **✅ Smart Nutrition Recalculation**
```dart
// When user changes health conditions or profile data:
1. Recalculate base goals using BMR/TDEE formulas
2. Apply health condition adjustments automatically
3. Save updated goals to database
4. Update UI with new targets
```

### **✅ User-Friendly Interface**
- **Multi-select dialogs** for dish preferences and health conditions
- **Clear visual cards** for profile information
- **Real-time updates** when selections change
- **Comprehensive validation** and error handling

### **✅ Health Condition Logic**
The screen includes simplified health adjustment logic:
- **Diabetes**: -30% carbs, +50% fiber, -50% sugar, +20% protein
- **Fatty Liver**: -70% sugar, -20% fat, -10% calories, +40% fiber
- **Malnutrition**: +40% calories, +30% protein, +40% fat
- **Anemia**: 2x iron, +50% vitamin C
- **Fitness**: +50% protein, +20% calories
- **Heart/Stroke/BP**: 2000mg sodium limit

---

## 📊 **Database Integration**

### **Fields Now Saved:**
```sql
UPDATE user_preferences SET
  -- New dish/health preferences
  dish_preferences = ['fish_seafood', 'meat_poultry', 'soups_stews'],
  health_conditions = ['diabetes', 'fitness_enthusiast'],
  allergies = ['dairy', 'shellfish'],
  
  -- User profile data
  age = 25,
  gender = 'male',
  height_cm = 175.0,
  weight_kg = 70.0,
  activity_level = 'moderately_active',
  weight_goal = 'lose_weight',
  
  -- Recalculated nutrition goals
  calorie_goal = 2100,
  protein_goal = 189,  -- Adjusted for diabetes + fitness
  carb_goal = 147,     -- Reduced for diabetes
  fat_goal = 70,
  fiber_goal = 45,     -- Increased for diabetes
  sugar_goal = 26,     -- Reduced for diabetes
  iron_goal = 18,
  vitamin_c_goal = 90,
  sodium_limit = 2300
WHERE user_id = 'user123';
```

---

## 🔄 **User Experience Flow**

### **Opening the Screen:**
1. **Loads** all existing preferences from database
2. **Displays** current nutrition goals in summary card
3. **Shows** selected preferences in each category
4. **Calculates** and displays profile information

### **Making Changes:**
1. **User taps** on any preference card
2. **Multi-select dialog** opens with current selections
3. **User modifies** selections as needed
4. **Dialog closes**, main screen updates immediately

### **Saving Changes:**
1. **User taps** "Save All Changes" button
2. **System recalculates** nutrition goals if profile changed
3. **Applies** health condition adjustments
4. **Saves** all data to Supabase
5. **Updates** nutrition goals display
6. **Shows** success confirmation

---

## 🎯 **Benefits**

### **For Users:**
- **One-stop management** of all preferences
- **Visual feedback** on how changes affect nutrition goals
- **Clear understanding** of their personalized targets
- **Easy modification** of any preference category

### **For the App:**
- **Centralized preference management**
- **Automatic goal recalculation** when conditions change
- **Consistent data** across all app features
- **Future-proof** structure for additional preferences

### **For Meal Tracking:**
- **Accurate, personalized targets** based on real health needs
- **Dynamic adjustments** when user conditions change
- **Comprehensive data** for smart recommendations
- **Medical relevance** for users with specific conditions

---

## 🔮 **Impact on Other Features**

### **Meal Tracker:**
- Uses updated nutrition goals for daily targets
- Shows condition-specific warnings and tips
- Prioritizes recipes based on dish preferences
- Filters out allergens automatically

### **Recipe Recommendations:**
- Suggests dishes from preferred categories
- Avoids ingredients based on health conditions
- Adjusts portion sizes for nutrition goals
- Highlights condition-appropriate recipes

### **Meal Planning:**
- Creates plans matching dish preferences
- Ensures health condition requirements are met
- Balances meals to hit adjusted nutrition targets
- Avoids problematic ingredients/cooking methods

This updated dietary preferences screen transforms user preference management from a basic settings page into a **comprehensive health and nutrition control center**! 🎛️✨
