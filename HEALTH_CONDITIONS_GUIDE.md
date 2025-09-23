# 🩺 Health Conditions & Nutrition Adjustments

## 🎯 Overview

The NutriPlan app now includes **medical condition-based nutrition adjustments** that automatically modify your nutrition goals based on specific health needs. This ensures users get safe, appropriate nutrition recommendations.

## 🏥 Available Health Conditions

### 1. **🩺 Diabetes / High Blood Sugar**
**Adjustments Applied:**
- ⬇️ **Carbs**: Reduced by 30% to prevent blood sugar spikes
- ⬆️ **Fiber**: Increased by 50% to slow glucose absorption  
- ⬇️ **Sugar**: Cut sugar limit in half for better glucose control
- ⬆️ **Protein**: Increased by 20% to maintain satiety with fewer carbs

**Example**: Base 2000 kcal → 140g carbs (instead of 200g), 45g fiber (instead of 30g)

### 2. **🧠 Stroke Recovery**
**Adjustments Applied:**
- ⬇️ **Sodium**: Very strict 1500mg limit (vs normal 2300mg)
- ⬇️ **Calories**: Reduced by 10% for weight management
- ❤️ **Heart-healthy fats**: Focus on omega-3 rich foods
- ⬇️ **Saturated fat**: Reduced by 30% for cardiovascular health

**Example**: Base 2000 kcal → 1800 kcal, 1500mg sodium max

### 3. **🫀 High Blood Pressure (Hypertension)**
**Adjustments Applied:**
- ⬇️ **Sodium**: 2000mg limit (DASH diet principles)
- ⬆️ **Potassium**: Increased by 30% to counteract sodium
- 🧂 **Magnesium focus**: Emphasis on magnesium-rich foods
- ⬇️ **Saturated fat**: Reduced by 20%

**Example**: Base 2000 kcal → 2000mg sodium max, higher potassium targets

### 4. **💪 Fitness Enthusiast**
**Adjustments Applied:**
- ⬆️ **Protein**: Increased by 50% for muscle building/recovery
- ⬆️ **Calories**: Increased by 20% for performance needs
- 🏃 **Carb timing**: Focus on pre/post workout carbohydrates
- 💊 **Performance nutrients**: Emphasis on creatine-rich foods

**Example**: Base 2000 kcal → 2400 kcal, 225g protein (instead of 150g)

### 5. **🫘 Kidney Disease**
**Adjustments Applied:**
- ⬇️ **Protein**: Reduced by 30% to reduce kidney workload
- ⬇️ **Sodium**: 2000mg limit to reduce fluid retention
- ⬇️ **Phosphorus**: 800mg limit (kidney filtration concern)
- ⬇️ **Potassium**: 2000mg limit (kidney excretion concern)

**Example**: Base 150g protein → 105g protein, strict mineral limits

### 6. **❤️ Heart Disease**
**Adjustments Applied:**
- ⬇️ **Saturated fat**: Reduced by 40% for heart health
- ⬇️ **Sodium**: 2000mg limit to reduce blood pressure
- 🐟 **Omega-3 focus**: Emphasis on heart-healthy fats
- ⬆️ **Fiber**: Increased by 30% for cholesterol management

**Example**: Base 70g fat → focus on unsaturated fats, high fiber foods

### 7. **👴 Senior (65+)**
**Adjustments Applied:**
- ⬆️ **Protein**: Increased by 30% to prevent muscle loss (sarcopenia)
- ⬆️ **Calcium**: Increased by 20% for bone health
- 🦴 **Vitamin D focus**: Emphasis on vitamin D rich foods
- ⬇️ **Calories**: Slightly reduced (5%) for slower metabolism

**Example**: Base 150g protein → 195g protein, higher calcium targets

## 📊 **Real-World Examples**

### **Scenario 1: 45-year-old with Diabetes**
```
Base Goals: 2000 kcal, 150g protein, 200g carbs, 70g fat
Diabetes Adjustments:
✅ Calories: 2000 kcal (unchanged)
✅ Protein: 180g (+20% for satiety)
✅ Carbs: 140g (-30% for blood sugar control)  
✅ Fat: 70g (unchanged)
✅ Fiber: 45g (+50% to slow glucose absorption)
✅ Sugar: <25g (cut in half)
```

### **Scenario 2: 30-year-old Fitness Enthusiast**
```
Base Goals: 2200 kcal, 165g protein, 220g carbs, 75g fat
Fitness Adjustments:
✅ Calories: 2640 kcal (+20% for performance)
✅ Protein: 248g (+50% for muscle building)
✅ Carbs: 264g (+20% for workout fuel)
✅ Fat: 90g (+20% for hormone production)
✅ Focus: Pre/post workout nutrition timing
```

### **Scenario 3: 70-year-old with High Blood Pressure**
```
Base Goals: 1800 kcal, 135g protein, 180g carbs, 65g fat
Senior + Hypertension Adjustments:
✅ Calories: 1710 kcal (-5% for slower metabolism)
✅ Protein: 176g (+30% to prevent muscle loss)
✅ Carbs: 180g (unchanged)
✅ Fat: 52g (-20% saturated fat focus)
✅ Sodium: 2000mg max (vs normal 2300mg)
✅ Potassium: +30% (DASH diet principles)
```

## 🔄 **How Multiple Conditions Work**

Users can select **multiple conditions** and the system applies **all relevant adjustments**:

```
Example: Senior (65+) + Diabetes
✅ Protein: +30% (senior) + 20% (diabetes) = +50% total
✅ Carbs: -30% (diabetes)
✅ Calories: -5% (senior metabolism)
✅ Fiber: +50% (diabetes)
✅ Sugar: -50% (diabetes)
```

## 💾 **Database Storage**

Health conditions are stored in the `user_preferences` table:

```sql
health_conditions: ['diabetes', 'fitness_enthusiast']
sodium_limit: 2000.0
-- Adjusted nutrition goals are recalculated and saved
calorie_goal: 2400
protein_goal: 225
carb_goal: 140
-- etc.
```

## 🎨 **UI Features**

### **Visual Design:**
- 🎨 **Color-coded conditions**: Each condition has its own color (red for diabetes, blue for fitness, etc.)
- ✅ **Clear descriptions**: Simple explanations of what each condition affects
- 🔒 **Mutual exclusivity**: Selecting "None" deselects all others
- 📊 **Real-time preview**: Shows how conditions will adjust goals

### **User Experience:**
- 🚨 **Medical disclaimer**: Clear indication these are general guidelines
- 📚 **Educational content**: Explains why each adjustment is made
- 🔄 **Easy modification**: Users can change conditions anytime in settings
- 👨‍⚕️ **Professional consultation**: Encourages consulting healthcare providers

## ⚠️ **Safety Features**

### **Minimum Limits:**
- 🚫 **Calorie floors**: Never goes below 1200 kcal (women) / 1500 kcal (men)
- 🚫 **Protein minimums**: Ensures adequate protein even with kidney disease
- 🚫 **Essential nutrients**: Maintains minimum requirements for vitamins/minerals

### **Medical Disclaimers:**
- 📋 Clear messaging that this is for general guidance only
- 👨‍⚕️ Encourages consultation with healthcare providers
- 📚 Educational content about why adjustments are made
- 🔄 Easy to modify as health conditions change

## 🎯 **Benefits**

1. **🎯 Personalized**: Goes beyond generic diet advice
2. **⚕️ Medical relevance**: Based on established nutritional guidelines for each condition
3. **🛡️ Safety-first**: Built-in safeguards prevent dangerous restrictions
4. **📚 Educational**: Users learn why certain adjustments matter
5. **🇵🇭 Practical**: Works with Filipino food preferences and local ingredients
6. **🔄 Flexible**: Easy to update as health status changes

This system transforms NutriPlan from a generic nutrition tracker into a **medically-aware nutrition assistant** that adapts to real health needs! 🩺✨
