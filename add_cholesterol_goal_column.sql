-- Add cholesterol_goal column to user_preferences table
-- This column will store the user's daily cholesterol goal in mg

ALTER TABLE user_preferences 
ADD COLUMN IF NOT EXISTS cholesterol_goal DECIMAL(5,2) DEFAULT 300.0;

-- Add comment to document the column
COMMENT ON COLUMN user_preferences.cholesterol_goal IS 'Daily cholesterol goal in milligrams (mg)';

-- Update existing records to have the default cholesterol goal
UPDATE user_preferences 
SET cholesterol_goal = 300.0 
WHERE cholesterol_goal IS NULL;

-- Verify the column was added
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_preferences' 
AND column_name = 'cholesterol_goal';
