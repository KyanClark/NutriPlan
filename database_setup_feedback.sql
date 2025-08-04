-- Create recipe_feedbacks table for the Feedback Feature
CREATE TABLE IF NOT EXISTS recipe_feedbacks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    recipe_id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_recipe_feedbacks_recipe_id ON recipe_feedbacks(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_feedbacks_user_id ON recipe_feedbacks(user_id);
CREATE INDEX IF NOT EXISTS idx_recipe_feedbacks_created_at ON recipe_feedbacks(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE recipe_feedbacks ENABLE ROW LEVEL SECURITY;

-- Create policies for recipe_feedbacks table
-- Allow users to read all feedbacks
CREATE POLICY "Allow users to read all feedbacks" ON recipe_feedbacks
    FOR SELECT USING (true);

-- Allow authenticated users to insert their own feedback
CREATE POLICY "Allow authenticated users to insert feedback" ON recipe_feedbacks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own feedback
CREATE POLICY "Allow users to update their own feedback" ON recipe_feedbacks
    FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to delete their own feedback
CREATE POLICY "Allow users to delete their own feedback" ON recipe_feedbacks
    FOR DELETE USING (auth.uid() = user_id);

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_recipe_feedbacks_updated_at 
    BEFORE UPDATE ON recipe_feedbacks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create a view for feedbacks with user information
CREATE OR REPLACE VIEW recipe_feedbacks_with_users AS
SELECT 
    rf.id,
    rf.recipe_id,
    rf.user_id,
    rf.rating,
    rf.comment,
    rf.created_at,
    rf.updated_at,
    p.username
FROM recipe_feedbacks rf
LEFT JOIN profiles p ON rf.user_id = p.id;

-- Grant permissions on the view
GRANT SELECT ON recipe_feedbacks_with_users TO authenticated; 