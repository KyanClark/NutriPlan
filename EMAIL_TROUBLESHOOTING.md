# Email Verification Troubleshooting Guide

## Issue: No Email Received in Gmail

If you're not receiving verification emails in your Gmail account, here are the steps to diagnose and fix the issue:

## Step 1: Use the Debug Tool

1. **Open the app** and go to the signup screen
2. **Click the "🔧 Test Email Verification (Debug)" button** at the bottom
3. **Enter your email and password** in the test screen
4. **Click "Test Signup"** to see detailed error messages

## Step 2: Check Common Issues

### A. Check Spam/Junk Folder
- **Look in your Gmail spam folder** - Supabase emails might be marked as spam
- **Check "All Mail" folder** in Gmail
- **Search for "supabase" or "verification"** in your entire Gmail

### B. Verify Email Address
- **Double-check the email address** you entered
- **Make sure there are no typos** (e.g., gnail.com instead of gmail.com)
- **Try a different email address** to test

### C. Wait for Delivery
- **Email delivery can take 1-5 minutes**
- **Don't immediately assume it failed**
- **Check again after waiting**

## Step 3: Supabase Configuration Issues

### Check Supabase Dashboard
1. **Go to your Supabase project dashboard**
2. **Navigate to Authentication > Settings**
3. **Check if "Enable email confirmations" is turned ON**
4. **Verify your site URL is correct**

### Email Provider Configuration
1. **In Supabase dashboard, go to Settings > API**
2. **Check if you have a custom SMTP server configured**
3. **If not configured, Supabase uses their default email service**

## Step 4: Test with Different Email Providers

Try these email addresses to test:
- **Gmail**: your-email@gmail.com
- **Outlook**: your-email@outlook.com
- **Yahoo**: your-email@yahoo.com

## Step 5: Check Console Logs

1. **Open browser developer tools** (F12)
2. **Go to Console tab**
3. **Look for any error messages** when signing up
4. **Check Network tab** for failed requests

## Step 6: Common Error Messages

### "Invalid email format"
- **Solution**: Check email syntax (must have @ and domain)

### "Email already registered"
- **Solution**: Use a different email or try logging in instead

### "Rate limit exceeded"
- **Solution**: Wait 1-5 minutes before trying again

### "Email service unavailable"
- **Solution**: Check Supabase status page or try later

## Step 7: Alternative Solutions

### Option 1: Use Different Email
- **Try a different Gmail account**
- **Use a different email provider** (Outlook, Yahoo, etc.)

### Option 2: Check Supabase Status
- **Visit https://status.supabase.com**
- **Check if email service is operational**

### Option 3: Contact Support
- **If nothing works, contact Supabase support**
- **Include your project URL and error messages**

## Step 8: Manual Verification (If Needed)

If email verification continues to fail:

1. **Go to Supabase dashboard**
2. **Navigate to Authentication > Users**
3. **Find your user account**
4. **Manually confirm the email** (if you have admin access)

## Debug Information to Collect

When reporting issues, include:
- **Email address used**
- **Error messages from debug screen**
- **Time when you tried to sign up**
- **Browser/device information**
- **Supabase project URL**

## Quick Test Commands

You can also test directly in the Supabase dashboard:

1. **Go to Authentication > Users**
2. **Click "Add user"**
3. **Enter email and password**
4. **Check if verification email is sent**

---

**Still having issues?** Use the debug tool in the app and share the error messages for more specific help. 