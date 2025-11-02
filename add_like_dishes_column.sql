-- Add like_dishes column to user_preferences table
-- Run this in Supabase SQL Editor

ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS like_dishes TEXT[] DEFAULT '{}'::TEXT[];

-- Add diet_type column if it doesn't exist
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS diet_type TEXT[] DEFAULT '{}'::TEXT[];

-- Optional: Migrate existing dish_preferences to like_dishes for existing users
UPDATE user_preferences 
SET like_dishes = dish_preferences 
WHERE like_dishes = '{}'::TEXT[] AND dish_preferences IS NOT NULL AND array_length(dish_preferences, 1) > 0;

