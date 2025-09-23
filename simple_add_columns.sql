-- Simple version: Add only the essential missing columns
-- Run this in your Supabase SQL Editor

-- Add missing columns to existing user_preferences table
ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS dish_preferences TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS health_conditions TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS age INTEGER,
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS height_cm DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS weight_kg DECIMAL(5,2),
ADD COLUMN IF NOT EXISTS activity_level TEXT,
ADD COLUMN IF NOT EXISTS weight_goal TEXT,
ADD COLUMN IF NOT EXISTS sodium_limit DECIMAL(8,2),
ADD COLUMN IF NOT EXISTS iron_goal DECIMAL(8,2),
ADD COLUMN IF NOT EXISTS vitamin_c_goal DECIMAL(8,2);

-- Enable RLS if not already enabled
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policy
CREATE POLICY "Users can manage own preferences" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);
