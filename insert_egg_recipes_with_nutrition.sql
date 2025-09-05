-- Insert Egg Recipes with Nutrition Data into Supabase
-- This SQL statement inserts 3 egg-based Filipino recipes with calories and macros

INSERT INTO recipes (title, image_url, short_description, ingredients, instructions, allergy_warning, diet_types, cost, calories, macros) VALUES

-- 1. Sunny Side up Egg
(
  'Sunny Side up Egg',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sunny_side_up_egg.jpg',
  'A sunny side up egg is a style of fried egg cooked on one side only, with the yolk left runny and the whites set. It is cooked gently over low to medium heat without flipping, giving it a bright yellow yolk that looks like a "sun," hence the name.',
  ARRAY[
    '1 egg',
    '2 tbsp of cooking oil',
    'Pinch of salt and pepper'
  ],
  ARRAY[
    'Preheat pan on medium-low for 1–2 minutes.',
    'Add cooking oil.',
    'Crack egg into a small bowl (optional), then slide it into the pan.',
    'Cook undisturbed until the whites are mostly set, ~2–3 min.',
    'If the top white is still jiggly, cover with a lid for 30–60 sec (or add 1 tsp water then cover) to steam—no flipping.',
    'Season with salt and pepper and serve.'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'High Protein Diet', 'Keto / Low Carbs', 'Flexitarian'],
  15.0,
  110,
  '{"protein": 6.0, "carbs": 1.0, "fat": 9.0, "fiber": 0.0, "sugar": 0.5, "sodium": 80.0, "cholesterol": 185.0}'::jsonb
),

-- 2. Scrambled Eggs
(
  'Scrambled Eggs',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/scrambled_eggs.jpeg',
  'Scrambled Eggs is a simple dish made by whisking eggs and cooking them with sautéed onions and tomatoes, sometimes with garlic or green onions for added flavor. It''s soft, savory, and often served with steamed rice for breakfast.',
  ARRAY[
    '2 eggs',
    '1 medium tomato, chopped',
    '1 medium onion, chopped',
    '1/2 tbsp of cooking oil',
    'Salt & pepper to taste',
    'Green onions optional'
  ],
  ARRAY[
    'Crack and beat eggs in a bowl until smooth, add a pinch of salt and pepper.',
    'Heat oil in a pan over medium heat.',
    'Sauté onion until soft, then add tomatoes and cook until tender and juicy.',
    'Pour in beaten eggs over the sautéed onion and tomato.',
    'Stir gently until eggs are just set but still soft (do not overcook).',
    'Top with green onions (optional), then serve hot with rice.'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'High Protein Diet', 'Keto / Low Carbs', 'Flexitarian'],
  25.0,
  234,
  '{"protein": 13.0, "carbs": 10.0, "fat": 17.0, "fiber": 2.0, "sugar": 5.0, "sodium": 200.0, "cholesterol": 370.0}'::jsonb
),

-- 3. Corned Beef Omelet
(
  'Corned Beef Omelet',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/corned_beef',
  'Corned Beef Omelet is a Filipino comfort dish made by mixing sautéed corned beef with beaten eggs, then pan-frying until golden. It''s simple, hearty, and perfect with rice for breakfast or any meal.',
  ARRAY[
    '1 can of corned beef',
    '2 pieces eggs',
    '1 piece onion',
    '2 cloves garlic',
    '3/4 cup green onion chopped',
    '2 tablespoons Cooking oil',
    'Salt and ground black pepper to taste'
  ],
  ARRAY[
    'Prepare the corned beef by sautéing. Heat oil in a pan and then saute garlic and onion. Add corned beef. Continue to saute for 3 to 5 minutes. Remove from the pan and let it cool down.',
    'Crack the eggs and place in a large mixing bowl. Add the salt and pepper. Beat until all the ingredients are well incorporated.',
    'Add sautéed Corned beef and green onions. Stir to mix the ingredients. Note: Make sure that the corned beef has cooled down before you execute this step.',
    'Heat a frying pan. Add 1 tablespoon cooking oil or use a cooking oil spray and spray oil on the pan.',
    'Scoop around ½ to ¾ cups of the corned beef and egg mixture and pour in the pan. Cook for 3 minutes on medium heat.',
    'Use a spatula to flip the omelet and cook the other side for 2 to 3 minutes.',
    'Transfer to a serving plate. Serve and Enjoy!'
  ],
  'Eggs, Soy/Wheat',
  ARRAY['Balance Diet', 'High Protein Diet', 'Flexitarian'],
  45.0,
  284,
  '{"protein": 13.0, "carbs": 5.0, "fat": 23.0, "fiber": 1.0, "sugar": 2.0, "sodium": 1041.0, "cholesterol": 49.0}'::jsonb
);
