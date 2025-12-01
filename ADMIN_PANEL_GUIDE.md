# Admin Panel Guide

## Overview
The admin panel has been successfully created with comprehensive recipe management and feedback viewing capabilities.

## Structure

### Services (`lib/services/admin/`)
1. **admin_service.dart** - Handles admin authentication and role checking
   - Checks `is_admin` field in profiles table
   - Checks `role` field for 'admin' or 'administrator'
   - Optional: Checks `admin_users` table for email-based admin list

2. **admin_recipe_service.dart** - Recipe CRUD operations
   - `createRecipe()` - Add new recipes
   - `updateRecipe()` - Edit existing recipes
   - `deleteRecipe()` - Remove recipes
   - `getAllRecipes()` - Fetch all recipes (no filtering)
   - `getRecipeById()` - Get single recipe
   - `searchRecipes()` - Search by title/description

3. **admin_feedback_service.dart** - Feedback management
   - `getAllFeedbacks()` - View all user feedbacks
   - `getOverallFeedbackStats()` - Statistics dashboard
   - `getFeedbacksByRecipe()` - Filter by recipe
   - `deleteFeedback()` - Remove inappropriate feedback
   - `updateFeedback()` - Edit feedback (admin override)
   - `getRecentFeedbacks()` - Recent feedbacks by date range

### Screens (`lib/screens/admin/`)
1. **admin_page.dart** - Main admin panel with tab navigation
   - Automatically checks admin access on load
   - Redirects non-admin users with error message
   - Two tabs: Recipes and Feedback

2. **tabs/recipe_management_tab.dart** - Recipe management interface
   - Search functionality
   - Add new recipe button
   - Recipe cards with image, title, description
   - Edit and delete actions
   - Pull-to-refresh support

3. **tabs/feedback_management_tab.dart** - Feedback viewer
   - Statistics dashboard (total feedbacks, avg rating, recipes)
   - Filter by rating (1-5 stars)
   - Filter by recipe
   - Feedback cards with user info, rating, comments
   - Delete feedback option

4. **widgets/recipe_form_dialog.dart** - Recipe form (add/edit)
   - Comprehensive form with all recipe fields
   - Dynamic ingredient list (add/remove)
   - Dynamic instruction steps (add/remove)
   - Dynamic tags (add/remove)
   - Nutritional information (protein, carbs, fats, fiber, sugar, sodium)
   - Image picker support (UI ready, needs storage integration)

## Access
The admin panel is accessible from the Profile screen. An "Admin Panel" option appears automatically for users with admin privileges.

## Database Setup Required

### Option 1: Add `is_admin` field to profiles table
```sql
ALTER TABLE profiles ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;
UPDATE profiles SET is_admin = TRUE WHERE email = 'admin@example.com';
```

### Option 2: Add `role` field to profiles table
```sql
ALTER TABLE profiles ADD COLUMN role TEXT DEFAULT 'user';
UPDATE profiles SET role = 'admin' WHERE email = 'admin@example.com';
```

### Option 3: Create admin_users table
```sql
CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
INSERT INTO admin_users (email) VALUES ('admin@example.com');
```

## Features Implemented

### Recipe Management
✅ Create new recipes
✅ Edit existing recipes
✅ Delete recipes (with confirmation)
✅ Search recipes
✅ View all recipes in card layout
✅ Recipe form with validation
✅ Dynamic ingredient/instruction/tag lists

### Feedback Management
✅ View all user feedbacks
✅ Statistics dashboard
✅ Filter by rating
✅ Filter by recipe
✅ Delete feedback (with confirmation)
✅ View user information with feedback
✅ Date formatting

## Suggested Improvements

### 1. Image Upload Integration
Currently, the image picker is UI-ready but needs Supabase Storage integration:
```dart
// In recipe_form_dialog.dart, after picking image:
final fileBytes = await pickedFile.readAsBytes();
final fileExt = pickedFile.path.split('.').last;
final filePath = 'recipe-images/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
final storage = Supabase.instance.client.storage.from('recipe-images');
await storage.upload(filePath, fileBytes);
final imageUrl = storage.getPublicUrl(filePath);
```

### 2. Bulk Operations
- Bulk delete recipes
- Bulk export recipes to CSV/JSON
- Bulk import recipes from CSV

### 3. Advanced Filtering
- Filter recipes by tags
- Filter recipes by calories range
- Filter recipes by cost range
- Sort by various criteria (date, popularity, rating)

### 4. Recipe Analytics
- Most viewed recipes
- Most favorited recipes
- Recipes with highest/lowest ratings
- Recipe performance metrics

### 5. Feedback Analytics
- Rating distribution charts
- Most reviewed recipes
- User engagement metrics
- Feedback trends over time

### 6. User Management (Future)
- View all users
- Manage user roles
- Suspend/activate users
- View user activity logs

### 7. Content Moderation
- Flag inappropriate feedback
- Auto-moderation rules
- Review queue for flagged content

### 8. Recipe Validation
- Ingredient validation against nutrition database
- Calorie calculation verification
- Duplicate recipe detection

### 9. Export/Import
- Export recipes to JSON/CSV
- Import recipes from JSON/CSV
- Recipe backup/restore

### 10. Notifications
- Email notifications for new feedback
- Alerts for low-rated recipes
- Weekly admin summary reports

### 11. Search Enhancements
- Full-text search across all fields
- Search by ingredients
- Search by nutritional values
- Saved search filters

### 12. UI/UX Improvements
- Dark mode support
- Responsive design for tablets
- Drag-and-drop recipe ordering
- Recipe preview before saving
- Undo/redo for form changes

### 13. Performance Optimizations
- Pagination for large recipe lists
- Lazy loading for images
- Caching for frequently accessed data
- Optimistic UI updates

### 14. Security Enhancements
- Audit log for admin actions
- IP-based access restrictions
- Two-factor authentication for admin
- Session timeout warnings

### 15. Data Validation
- Recipe schema validation
- Image format/size validation
- URL validation for image URLs
- Sanitize user inputs

## Testing Checklist

- [ ] Admin access check works correctly
- [ ] Non-admin users cannot access admin panel
- [ ] Recipe creation with all fields
- [ ] Recipe editing preserves data
- [ ] Recipe deletion with confirmation
- [ ] Search functionality
- [ ] Feedback filtering by rating
- [ ] Feedback filtering by recipe
- [ ] Feedback deletion
- [ ] Statistics calculation accuracy
- [ ] Form validation
- [ ] Error handling for network issues
- [ ] Image upload (when implemented)

## Notes

- The admin panel automatically checks permissions on load
- All admin operations require authentication
- Error messages are user-friendly
- Confirmation dialogs prevent accidental deletions
- The UI follows Material Design 3 principles
- All services use proper error handling and logging

