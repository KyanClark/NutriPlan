# Admin Panel Web Setup Guide

## Overview
The admin panel is now a **web-only** interface accessible via URL routing. It's optimized for desktop/web browsers with a responsive layout.

## Access

### Web URL
Access the admin panel at:
```
https://your-domain.com/#/admin
```

Or locally during development:
```
http://localhost:port/#/admin
```

### Route Configuration
The admin route is configured in `lib/main.dart`:
```dart
routes: {
  '/': (context) => const LoginScreen(),
  '/admin': (context) => const AdminWebPage(),
}
```

## Features

### Web-Optimized Layout
- **Responsive Design**: Adapts to different screen sizes
- **Grid View**: Recipe cards display in a 3-column grid on wide screens (>800px)
- **List View**: Falls back to list view on smaller screens
- **Centered Container**: Max width of 1400px for optimal readability
- **Professional UI**: Clean, modern interface with proper spacing and shadows

### Recipe Management
- Search functionality with real-time filtering
- Grid/List view toggle based on screen width
- Add, edit, and delete recipes
- Comprehensive recipe form with all fields
- Image preview support

### Feedback Management
- Statistics dashboard with key metrics
- Filter by rating (1-5 stars)
- Filter by recipe
- View all user feedbacks
- Delete inappropriate feedback

## Security

### Access Control
- Automatically checks admin status on page load
- Redirects non-admin users with error message
- Only accessible on web platform (mobile app shows error)

### Admin Verification
The system checks admin status via:
1. `is_admin` field in `profiles` table
2. `role` field set to 'admin' or 'administrator'
3. Email in `admin_users` table (optional)

## Database Setup

Add admin access to a user:

**Option 1: Using is_admin field**
```sql
ALTER TABLE profiles ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;
UPDATE profiles SET is_admin = TRUE WHERE email = 'admin@example.com';
```

**Option 2: Using role field**
```sql
ALTER TABLE profiles ADD COLUMN role TEXT DEFAULT 'user';
UPDATE profiles SET role = 'admin' WHERE email = 'admin@example.com';
```

**Option 3: Using admin_users table**
```sql
CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
INSERT INTO admin_users (email) VALUES ('admin@example.com');
```

## Development

### Running Locally
```bash
flutter run -d chrome
# Navigate to http://localhost:port/#/admin
```

### Building for Web
```bash
flutter build web
# Deploy the build/web folder to your hosting service
```

## Mobile App Behavior

When accessed from the mobile app:
- Shows a message: "Admin Panel is only available on web"
- Instructs users to access from a web browser
- Prevents mobile navigation to admin features

## UI Components

### Recipe Management Tab
- Search bar with clear button
- "Add Recipe" button
- Grid view (3 columns) on wide screens
- List view on smaller screens
- Recipe cards with image, title, description, and action buttons

### Feedback Management Tab
- Statistics card with gradient background
- Filter dropdowns for rating and recipe
- Feedback cards with user info, rating, and comments
- Delete action for each feedback

## Future Enhancements

1. **Image Upload**: Integrate Supabase Storage for recipe images
2. **Bulk Operations**: Bulk delete/export recipes
3. **Advanced Filters**: Filter by tags, calories, cost range
4. **Analytics Dashboard**: Recipe performance metrics
5. **Export/Import**: CSV/JSON export and import
6. **User Management**: Manage users and roles
7. **Content Moderation**: Flag and review system
8. **Dark Mode**: Theme toggle for admin panel

## Troubleshooting

### Cannot Access Admin Panel
1. Verify admin status in database
2. Check if user is logged in
3. Ensure accessing from web browser (not mobile app)
4. Check browser console for errors

### Recipes Not Loading
1. Check network connection
2. Verify Supabase connection
3. Check browser console for API errors
4. Verify admin permissions

### Feedback Not Showing
1. Check if feedbacks exist in database
2. Verify filters are not too restrictive
3. Check browser console for errors

## Notes

- The admin panel is optimized for desktop/web use
- Mobile app users will see an error message if they try to access it
- All admin operations require authentication
- Error messages are user-friendly and informative
- The UI follows Material Design 3 principles






