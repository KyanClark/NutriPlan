-- Simple setup for user_preferences table
-- Run this in your Supabase SQL Editor

-- Step 1: Create the table
CREATE TABLE user_preferences (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Arrays for multiple selections
  dish_preferences TEXT[] DEFAULT '{}',
  allergies TEXT[] DEFAULT '{}',
  health_conditions TEXT[] DEFAULT '{}',
  
  -- User profile data
  age INTEGER,
  gender TEXT,
  height_cm DECIMAL(5,2),
  weight_kg DECIMAL(5,2),
  activity_level TEXT,
  weight_goal TEXT,
  
  -- Nutrition goals
  calorie_goal DECIMAL(8,2),
  protein_goal DECIMAL(8,2),
  carb_goal DECIMAL(8,2),
  fat_goal DECIMAL(8,2),
  fiber_goal DECIMAL(8,2),
  sugar_goal DECIMAL(8,2),
  cholesterol_goal DECIMAL(8,2),
  sodium_limit DECIMAL(8,2),
  iron_goal DECIMAL(8,2),
  vitamin_c_goal DECIMAL(8,2),
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- Step 2: Enable RLS (Row Level Security)
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Step 3: Create policies (users can only access their own data)
CREATE POLICY "Users can manage own preferences" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);
