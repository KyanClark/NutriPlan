# NutriPlan System Presentation Report

## Full System Walkthrough Presentation

### Signup Page

NutriPlan begins with a comprehensive user registration experience through the Signup Page, where new users can create their account by providing essential information including full name, email or phone number, and a secure password. The system offers flexible authentication options, allowing users to choose between email or phone-based registration, with form validation ensuring all required fields are properly completed before proceeding to the verification stage.

### SMS Authentication

Following account creation, users proceed to SMS Authentication, where they receive a six-digit verification code via SMS through the integrated iprogsms service. This two-factor authentication ensures account security and verifies the user's phone number, with a user-friendly interface featuring individual input fields for each digit and automatic resend functionality after a 60-second cooldown period. The system handles phone number formatting automatically, supporting various input formats and ensuring compatibility with the SMS service provider.

### Login Page

Once verified, users are seamlessly transitioned to the Login Page, which supports both email and phone number authentication with intelligent input detection that automatically determines whether the user is entering an email address or phone number. The login page includes login history suggestions for returning users, displaying previously used credentials for quick access, and provides smooth navigation to the main application experience upon successful authentication. The system includes error handling for invalid credentials, unverified accounts, and network issues, with clear user-friendly error messages.

### Welcome Experience

After successful authentication, first-time users are greeted with a Welcome Experience that introduces them to NutriPlan's core philosophy and features through an animated, multi-page presentation. This welcome journey explains how NutriPlan adapts to individual health goals, allergies, and eating habits while generating realistic meal plans and comprehensive grocery lists. The experience highlights key features including interactive recipe guides, smart meal planning with calendar-based organization, intelligent meal suggestions, and detailed calorie visuals with daily progress summaries. The welcome experience uses smooth page transitions and engaging animations to create an inviting first impression.

### Onboarding Pages

Following the welcome experience, users proceed through Onboarding Pages that collect essential personal information including age, gender, height, weight, activity level, and weight goals. The onboarding process also captures dietary preferences such as diet types, allergies, health conditions, and favorite dishes, ensuring that the system can provide personalized recommendations from the very beginning. The onboarding flow is designed to be intuitive and non-overwhelming, breaking down information collection into manageable steps with clear progress indicators.

### HomePage

Once onboarding is complete, users arrive at the HomePage, which serves as the central dashboard and navigation hub of the application. The homepage features a personalized greeting, an auto-rotating nutrition tips banner that cycles through health information every five seconds, and prominent access to Smart Meal Suggestions powered by AI. The interface displays meal categories with visual GIFs for quick browsing, including featured categories like Beef, Chicken, Desserts, and Fish. Recent activity sections show today's meal plan count and weekly statistics, while the profile avatar in the app bar provides quick access to user settings and preferences. The homepage is designed with a clean, modern card-based layout that prioritizes user engagement and feature discovery.

### Meal Planner > Recipe Page > Recipe Info > Meal Summary

From the homepage, users can access the Meal Planner, which provides a comprehensive calendar-based meal planning system. The planner allows users to select dates, choose meal types for breakfast, lunch, and dinner, and browse through an extensive recipe database. When users select a recipe, they navigate to the Recipe Page, which displays detailed information including ingredients, cooking instructions, nutritional data, and user ratings. The Recipe Info screen provides comprehensive nutrition breakdowns with visual macro chips showing protein, carbohydrates, fats, fiber, sugar, sodium, and cholesterol, all calculated using the FNRI database for accurate Filipino ingredient data. Users can add recipes to their meal plan, mark favorites, and view community feedback. After selecting meals, users proceed to the Meal Summary page, where they assign meal types and times, optionally include rice servings with automatic nutrition calculation, and review their complete meal plan before confirmation. The summary provides a comprehensive overview of all selected meals with their nutritional values, ensuring users can make informed decisions about their dietary choices.

### Shopping List Page

Once a meal plan is confirmed, users can generate a Shopping List Page that automatically aggregates all ingredients from their planned meals. The shopping list intelligently groups items by category, combines duplicate ingredients with proper quantity calculations, and provides a user-friendly interface for checking off purchased items. The system includes features for finding ingredient alternatives when items are unavailable, displays meal badges showing which recipes require each ingredient, and offers a summary card showing total items and meals included. The shopping list supports manual editing, quantity adjustments, and can be refreshed to reflect any changes in the meal plan.

### Interactive Recipe Page (with Feedback)

After meal planning and shopping, users can follow their recipes through the Interactive Recipe Page, which provides a step-by-step cooking guide with visual instructions, built-in timers for cooking steps, and the ability to mark steps as complete. The interactive experience guides users through each cooking instruction, making meal preparation accessible even for beginners. Upon completing a recipe, users are prompted to provide feedback through a rating and comment system, which contributes to the community-driven recipe improvement process. The feedback system allows users to rate recipes from one to five stars and share their cooking experience, with all feedback stored and displayed on recipe pages to help other users make informed decisions.

### Meal Tracker

Throughout the day, users can track their nutrition through the Meal Tracker, which provides real-time calculation of daily macros including calories, protein, carbohydrates, fats, fiber, sugar, sodium, and cholesterol. The tracker displays visual progress bars showing advancement toward daily nutrition goals, integrates seamlessly with the meal planner to mark completed meals, and maintains a calendar view showing dates with logged meals. The system automatically calculates nutrition values from completed recipes and meal plans, providing users with comprehensive insights into their daily dietary intake. The meal tracker supports multiple meal types and provides detailed breakdowns for each logged meal.

### Analytics Page

For deeper insights, users can access the Analytics Page, which offers comprehensive nutritional analysis through interactive charts and visualizations. The analytics dashboard displays weekly and monthly views with area charts showing calorie intake trends, pie charts illustrating macro distribution, and detailed breakdowns of all nutritional metrics. The system provides AI-powered insights that analyze eating patterns, suggest improvements, and highlight areas where users are meeting or exceeding their goals. The analytics page includes comparison features showing progress over time, identifies trends in eating habits, and offers actionable recommendations based on the user's dietary preferences and health conditions.

### Profile Screen > Profile Info > Dietary Preferences

User customization and account management are handled through the Profile Screen, which serves as the central hub for personal information and settings. The profile screen displays user avatar, name, and email, with quick access to various account features. Within the profile, users can access Profile Information, where they can view and edit personal details including age, gender, height, weight, activity level, and weight goals. The profile information screen also displays calculated nutrition goals based on the user's physical attributes and objectives, ensuring that all recommendations and tracking align with individual needs. Additionally, users can manage their Dietary Preferences, where they can update diet types, allergies, health conditions, favorite dishes, and nutrition needs. The dietary preferences system directly influences meal suggestions, recipe filtering, and nutritional recommendations throughout the application.

### Favorites Page

Users can maintain a collection of favorite recipes through the Favorites Page, which displays all recipes that have been marked as favorites with a simple, elegant interface. The favorites page allows users to quickly access their preferred recipes, remove items from favorites, and navigate directly to recipe details. The system synchronizes favorites across all recipe pages, ensuring a consistent user experience throughout the application.

### Meal History

For historical reference, users can access their Meal History, which provides a comprehensive record of all past meal plans organized by days, weeks, or months. The meal history screen allows users to review previous meal selections, view completed meal plans, and even reuse past meal plans by navigating to the meal summary page. The history is organized chronologically with intuitive grouping and filtering options, making it easy for users to track their meal planning patterns over time.

### Smart Meal Suggestions

One of NutriPlan's most powerful features is Smart Meal Suggestions, which leverages AI technology to provide personalized meal recommendations based on the user's dietary preferences, health conditions, meal history, and current nutritional needs. The smart suggestions system analyzes gaps in daily nutrition, considers budget-friendly options, accounts for health conditions like anemia, fatty liver disease, or malnutrition, and provides context-aware recommendations for breakfast, lunch, and dinner. The system explains why each suggestion is made, tracks previously suggested meals, and allows users to quickly add suggestions directly to their meal plan. The AI-powered suggestions adapt to user feedback, learning from accepted and rejected recommendations to improve future suggestions.

### Logout

Finally, when users are ready to end their session, they can securely log out through the Profile Screen's logout functionality. The logout process includes a confirmation dialog to prevent accidental sign-outs, securely clears the authentication session, and returns users to the login screen. The system ensures that all user data is properly saved before logout, maintaining data integrity and providing a smooth transition for the next login session.

---

Throughout this entire journey, NutriPlan maintains a cohesive user experience with consistent design patterns, smooth navigation transitions, and comprehensive data synchronization. The system integrates multiple services including Supabase for backend operations, FNRI database for accurate nutritional information, and AI services for intelligent meal suggestions, all working together to provide users with a complete nutrition and meal planning solution tailored specifically for Filipino cuisine and dietary needs.

