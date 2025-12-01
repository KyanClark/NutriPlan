-- Add like_dishes column to user_preferences table
-- Run this in Supabase SQL Editor

ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS like_dishes TEXT[] DEFAULT '{}'::TEXT[];

-- Add diet_type column if it doesn't exist
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS diet_type TEXT[] DEFAULT '{}'::TEXT[];

-- Add nutrition_needs column if it doesn't exist
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS nutrition_needs TEXT[] DEFAULT '{}'::TEXT[];

-- Add sodium_limit column if it doesn't exist (for tracking daily sodium intake limit)
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS sodium_limit DOUBLE PRECISION DEFAULT 2300.0;

-- Optional: Migrate existing dish_preferences to like_dishes for existing users
-- Only run if dish_preferences column exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'dish_preferences'
    ) THEN
        UPDATE user_preferences 
        SET like_dishes = dish_preferences 
        WHERE like_dishes = '{}'::TEXT[] 
        AND dish_preferences IS NOT NULL 
        AND array_length(dish_preferences, 1) > 0;
    END IF;
END $$;

