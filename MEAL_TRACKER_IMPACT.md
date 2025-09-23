# 📊 How Health Conditions Affect Your Meal Tracker

## 🎯 **Yes! Health conditions completely change your meal tracker goals and recommendations.**

Here's exactly how the 3 new conditions impact what users see in their daily nutrition tracking:

---

## 📱 **Meal Tracker Examples**

### **🩸 Anemia / Low Iron**

#### **Before (Normal User):**
```
Daily Goals:
🔥 2000 kcal
🥩 150g protein  
🍚 250g carbs
🥑 70g fat
🌾 30g fiber
🩸 18mg iron (women) / 8mg (men)
🍊 90mg vitamin C
```

#### **After (With Anemia):**
```
Daily Goals:
🔥 2000 kcal (same)
🥩 150g protein (same, but HEME IRON FOCUS*)
🍚 250g carbs (same)
🥑 70g fat (same)
🌾 30g fiber (same)
🩸 36mg iron (DOUBLED!) ⚠️
🍊 135mg vitamin C (+50% for iron absorption) ⚠️

*Special Focus:
- Prioritize meat, fish, poultry (heme iron)
- Pair iron foods with vitamin C
- Avoid tea/coffee with meals
- Include folate-rich foods
```

**Meal Suggestions Change:**
- ✅ **Prioritized**: Beef, liver, fish, spinach, lentils + citrus
- ⚠️ **Caution**: Tea, coffee (separate from meals)
- 🎯 **Combos**: "Beef with bell peppers" (iron + vitamin C)

---

### **🍺 Fatty Liver Disease**

#### **Before (Normal User):**
```
Daily Goals:
🔥 2000 kcal
🥩 150g protein
🍚 250g carbs
🥑 70g fat
🌾 30g fiber
🍯 50g sugar
```

#### **After (With Fatty Liver):**
```
Daily Goals:
🔥 1800 kcal (-10% for weight loss) ⚠️
🥩 150g protein (same)
🍚 250g carbs (same)
🥑 56g fat (-20% total fat) ⚠️
🌾 42g fiber (+40% for liver health) ⚠️
🍯 15g sugar (-70% VERY STRICT!) ⚠️

Special Restrictions:
🚫 NO ALCOHOL
⚠️ Low saturated fat focus
⚠️ Avoid fried foods
```

**Meal Suggestions Change:**
- ✅ **Prioritized**: Grilled fish, vegetables, whole grains
- 🚫 **Avoided**: Fried foods, sweets, processed foods, alcohol
- 🎯 **Focus**: Steamed, grilled, baked preparations

---

### **🌾 Malnutrition / Underweight**

#### **Before (Normal User):**
```
Daily Goals:
🔥 2000 kcal
🥩 150g protein
🍚 250g carbs
🥑 70g fat
🌾 30g fiber
```

#### **After (With Malnutrition):**
```
Daily Goals:
🔥 2800 kcal (+40% for weight gain!) ⚠️
🥩 195g protein (+30% for muscle building) ⚠️
🍚 250g carbs (same)
🥑 98g fat (+40% healthy fats) ⚠️
🌾 30g fiber (same)

Special Focus:
🥜 Calorie-dense foods (nuts, oils, dairy)
🍽️ 5-6 small frequent meals
💊 Micronutrient-rich foods
```

**Meal Suggestions Change:**
- ✅ **Prioritized**: Nuts, avocado, dairy, oils, protein shakes
- 🎯 **Portions**: Larger serving sizes
- ⏰ **Frequency**: More frequent meal reminders

---

## 📊 **Real User Dashboard Changes**

### **Example: 25F with Anemia**

**Normal Tracking:**
```
Today's Progress:
🔥 1,200 / 2,000 kcal (60%)
🥩 45 / 150g protein (30%)
🩸 8 / 18mg iron (44%) ✅ Normal
```

**With Anemia Condition:**
```
Today's Progress:
🔥 1,200 / 2,000 kcal (60%)
🥩 45 / 150g protein (30%)
🩸 8 / 36mg iron (22%) ⚠️ CRITICAL LOW!
🍊 30 / 135mg vitamin C (22%) ⚠️ Need more!

💡 Suggestions:
- Add beef or spinach to your next meal
- Have orange juice with iron-rich foods
- Avoid tea with meals today
```

### **Example: 40M with Fatty Liver**

**Normal Tracking:**
```
Today's Progress:
🔥 1,800 / 2,000 kcal (90%)
🍯 45 / 50g sugar (90%) ✅ Normal
🥑 65 / 70g fat (93%) ✅ Normal
```

**With Fatty Liver Condition:**
```
Today's Progress:
🔥 1,800 / 1,800 kcal (100%) ✅ Perfect
🍯 45 / 15g sugar (300%) 🚫 WAY TOO HIGH!
🥑 65 / 56g fat (116%) ⚠️ Over limit
🌾 15 / 42g fiber (36%) ⚠️ Need more

⚠️ ALERTS:
- Sugar intake is 3x your limit!
- Try grilled fish instead of fried
- Add more vegetables for fiber
```

---

## 🎨 **Visual Changes in App**

### **Color-Coded Warnings:**
- 🟢 **Green**: Meeting health condition goals
- 🟡 **Yellow**: Approaching limits
- 🔴 **Red**: Exceeding safe limits for condition
- 🚫 **Red with X**: Completely avoid (alcohol for fatty liver)

### **Smart Notifications:**
```
🩸 Anemia Alert: "Pair your spinach salad with orange slices for better iron absorption!"

🍺 Fatty Liver Alert: "Your sugar is at 80% of daily limit. Choose water instead of juice."

🌾 Malnutrition Alert: "You're 500 calories behind goal. Try adding nuts or avocado to your meal."
```

### **Recipe Recommendations:**
- **Anemia**: Iron-rich recipes move to top
- **Fatty Liver**: Low-sugar, grilled options prioritized
- **Malnutrition**: High-calorie, nutrient-dense meals featured

---

## 🔄 **Dynamic Adjustments**

### **Recipe Filtering:**
```python
# Example logic
if user.has_condition('anemia'):
    prioritize_recipes_with(['beef', 'spinach', 'lentils'])
    suggest_combinations(['iron_food + vitamin_c'])
    
if user.has_condition('fatty_liver'):
    filter_out_recipes_with(['fried', 'high_sugar'])
    prioritize_cooking_methods(['grilled', 'steamed'])
    
if user.has_condition('malnutrition'):
    prioritize_recipes_with(['high_calorie', 'nutrient_dense'])
    suggest_larger_portions()
```

### **Meal Planning:**
- **Anemia**: Ensures iron + vitamin C combos in meal plans
- **Fatty Liver**: Automatically excludes high-sugar/fried options
- **Malnutrition**: Plans 5-6 smaller, calorie-dense meals

---

## 💾 **Database Impact**

Each user's condition preferences are stored and affect:

```sql
-- User's adjusted goals
SELECT calorie_goal, protein_goal, iron_goal, vitamin_c_goal 
FROM user_preferences 
WHERE health_conditions @> '["anemia"]';

-- Results in different targets for tracking
User A (no conditions): iron_goal = 18mg
User B (anemia): iron_goal = 36mg
```

---

## 🎯 **Summary**

**YES - Health conditions completely transform the meal tracker experience:**

1. **📊 Different Daily Goals**: Numbers change based on medical needs
2. **🎨 Visual Alerts**: Color-coded warnings for condition-specific limits
3. **🍽️ Recipe Suggestions**: Prioritizes condition-appropriate foods
4. **💡 Smart Tips**: Personalized advice (like iron + vitamin C pairing)
5. **⚠️ Safety Warnings**: Alerts when exceeding dangerous limits
6. **🎯 Meal Planning**: Automatically filters/suggests appropriate meals

This makes NutriPlan a **medically-aware nutrition assistant** rather than just a generic calorie counter! 🩺✨
