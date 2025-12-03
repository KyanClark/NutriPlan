-- Insert Filipino Recipes into Supabase
-- This SQL statement inserts 5 authentic Filipino recipes with macros when available

INSERT INTO recipes (
  title,
  image_url,
  short_description,
  ingredients,
  instructions,
  macros,
  allergy_warning,
  calories,
  tags,
  cost,
  notes
) VALUES

(
  'Sinigang na Bangus',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sinigang_na_bangus.jpg',
  'Sinigang na Bangus is a simple and delicious sour clear broth fish soup made with milkfish and vegetables. It is a comforting, light yet satisfying dish that many families enjoy at home.',
  ARRAY[
    '0.67 lbs. bangus (milkfish), cleaned and sliced',
    '0.33 (40g pack) Knorr Sinigang sa Sampaloc Mix (Original)',
    '0.33 bunch fresh kangkong leaves',
    '4 pieces sitaw (snake beans), cut into 2-inch pieces',
    '2 to 2.67 pieces okra',
    '0.67 pieces long green pepper (siling pangsigang)',
    '0.33 medium tomato, wedged', 
    '0.33 medium yellow onion, wedged',
    '0.83 tablespoons fish sauce',
    '0.08 teaspoon ground black pepper',
    '0.67 quarts water'
  ],
  ARRAY[
    'Heat a cooking pot and pour in the water.',
    'Add tomato and onion. Let the mixture boil.',
    'Add the bangus (milkfish). Cover and cook over medium heat for 8 to 12 minutes.',
    'Add Knorr Sinigang sa Sampaloc Mix. Stir and cook for 2 minutes.',
    'Put the long green pepper, sitaw (snake beans), and okra into the pot. Stir, cover, and cook for 5 to 7 minutes.',
    'Add fish sauce and ground black pepper. Stir to distribute the seasoning.',
    'Put the kangkong leaves into the pot. Cover and turn the heat off. Let it sit for 5 minutes to finish cooking in the residual heat.',
    'Transfer to a serving bowl and serve hot.'
  ],
  NULL, -- macros will be calculated later
  'Fish',
  NULL, -- calories will be calculated later
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Low-Fat', 'Pescatarian'],
  160,
  ''
),

(
  'Ginisang Repolyo with Chicken',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginisang_repolyo_with_chicken.jpg',
  'Ginisang Repolyo with Chicken is a quick, budget-friendly stir-fried cabbage and chicken dish. It is light, healthy, and perfect for everyday meals.',
  ARRAY[
    '0.25 head cabbage, chopped',
    '2 ounces boneless chicken breast, sliced thinly',
    '0.5 piece Knorr Chicken Cube',
    '0.5 small red bell pepper, sliced into strips',
    '0.5 small green bell pepper, sliced into strips',
    '0.75 tablespoons oyster sauce',
    '0.5 piece onion, sliced',
    '2 cloves garlic, crushed',
    '0.63 cups water',
    '1.5 tablespoons cooking oil',
    'Salt and ground black pepper to taste'
  ],
  ARRAY[
    'Heat cooking oil in a pot over medium heat.',
    'Sauté onion and garlic until the onion softens.',
    'Add the sliced chicken. Cook until the color turns light brown.',
    'Pour in 0.63 cups water. Let it boil.',
    'Add Knorr Chicken Cube. Cover the pot and continue cooking until most of the water has evaporated.',
    'Put the oyster sauce and cabbage into the cooking pot. Stir and sauté for about 1 minute.',
    'Add a bit more water if needed and continue cooking for about 5 minutes or until the cabbage is tender-crisp.',
    'Add the red and green bell peppers. Season with salt and ground black pepper. Continue cooking for 2 minutes.',
    'Transfer to a serving plate and serve.'
  ],
  jsonb_build_object(
    'calories', 96.5,
    'carbs', 7,
    'fiber', 2,
    'fat', 5.5,
    'sugar', 3.5,
    'protein', 4,
    'sodium', 242,
    'cholesterol', 9
  ),
  'Shellfish',
  97,
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Friendly', 'Flexitarian'],
  120,
  'Contains oyster sauce, which may include shellfish and gluten depending on the brand.'
),

(
  'Sarciadong Isda',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sarciadong_tilapia.jpg',
  'Sarciadong Isda is a comforting dish made by simmering fried fish in a savory tomato and egg sauce. It is a great way to turn leftover fried fish into a hearty new meal.',
  ARRAY[
    '0.5 lbs tilapia, cleaned',
    '0.5 tomatoes, diced',
    '0.5 onions, diced',
    '0.25 cup water',
    '0.13 teaspoon ground black pepper',
    '0.75 green onions, chopped (optional)',
    '0.5 teaspoons garlic, minced',
    '0.5 eggs, beaten',
    '0.13 cup cooking oil',
    '0.5 teaspoons salt',
    'Fish sauce to taste'
  ],
  ARRAY[
    'Rub salt all over the fish.',
    'Heat oil in a frying pan and fry the fish until cooked and lightly crisp. Remove the fish and place on a plate lined with paper towels. Set aside.',
    'Using a clean pan, heat about 2 teaspoons of cooking oil.',
    'Sauté the garlic, onions, and tomatoes until the onions and tomatoes soften.',
    'Add fish sauce and ground black pepper, then stir.',
    'Put in the chopped green onions and water, then bring to a boil.',
    'Add the fried fish and simmer for 3 to 5 minutes so it absorbs the flavors.',
    'Pour the beaten eggs evenly over the pan. Let the eggs curdle or coagulate, then gently stir the mixture.',
    'Simmer for another 2 minutes, then transfer to a serving plate and serve hot.'
  ],
  jsonb_build_object(
    'calories', 134,
    'carbs', 2.25,
    'fiber', 0.5,
    'fat', 8.5,
    'sugar', 1,
    'protein', 12.5,
    'sodium', 330.5,
    'cholesterol', 48.75
  ),
  'Fish, Eggs',
  134,
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Pescatarian'],
  140,
  ''
),

(
  'Steamed Kangkong',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/steamed_kangkong.jpg',
  'Steamed Kangkong is a simple, budget-friendly vegetable dish made with water spinach, garlic, soy sauce, and a light seasoning. It is quick to prepare and a great way to enjoy leafy greens.',
  ARRAY[
    '2 tablespoons vegetable oil',
    '1 tablespoon soy sauce',
    '0.5 teaspoon ground black pepper',
    '1 tablespoon sugar',
    '4 cloves garlic, roughly chopped',
    '250 grams kangkong (water spinach), trimmed and sliced into 4-inch pieces',
    '1 small red onion, chopped',
    'Bagoong to serve (optional)'
  ],
  ARRAY[
    'In a bowl, mix together vegetable oil, soy sauce, ground black pepper, sugar, and chopped garlic.',
    'Add the kangkong and toss to combine until the leaves and stems are well coated with the mixture.',
    'Transfer the kangkong mixture to a plate or a lined steamer basket.',
    'Steam the kangkong mixture until fully cooked, about 5 minutes.',
    'Top with chopped red onions.',
    'Serve with bagoong on the side, if desired.'
  ],
  NULL, -- macros will be calculated later
  'Soy',
  NULL, -- calories will be calculated later
  ARRAY['Balance Diet', 'Dairy-Free', 'Gluten-Friendly', 'Low-Fat', 'Vegetarian', 'Vegan'],
  80,
  'Check your soy sauce brand for gluten if you need this to be fully gluten-free.'
),

(
  'Ginisang Monggo with Kalabasa',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginisang_monggo_with_kalabasa.jpeg',
  'Ginisang Monggo with Kalabasa is a hearty mung bean stew cooked with squash, leafy greens, and dried shrimp, then topped with crunchy chicharon. It is a comforting, protein- and fiber-rich Filipino favorite.',
  ARRAY[
    '4.67 ounces mung beans',
    '0.33 lb. calabaza squash, cubed',
    '0.08 cup salted dried shrimp (hibe)',
    '0.33 cup malunggay leaves',
    '0.67 cups spinach',
    '0.67 tomatoes, diced',
    '0.33 onion, chopped',
    '1.33 cloves garlic, chopped',
    '0.33 cup pork rinds (chicharon)',
    '2.67 grams Maggi Magic Sarap',
    '1 tablespoon fish sauce',
    '0.08 teaspoon ground black pepper',
    '0.5 quarts water',
    '1 tablespoon cooking oil'
  ],
  ARRAY[
    'Soak the mung beans in water overnight to help them cook faster and become creamier.',
    'Drain the mung beans before cooking.',
    'In a deep pot, heat the cooking oil over medium heat.',
    'Sauté the garlic until golden, then add the onions and tomatoes. Cook until softened and fragrant.',
    'Add the soaked mung beans and dried hibe (salted dried shrimp). Stir well to combine.',
    'Pour in the water and fish sauce. Cover and let it simmer until the mung beans are soft and the broth has thickened, adding more water as needed.',
    'Once the mung beans are tender and creamy, add the cubed kalabasa squash. Simmer until the squash is tender but still holds its shape.',
    'Add the malunggay leaves and spinach. Cook for about 1 minute, or until the greens are wilted.',
    'Season with ground black pepper and Maggi Magic Sarap. Adjust seasoning to taste.',
    'Transfer to a serving bowl and top with pork rinds (chicharon) before serving.'
  ],
  NULL, -- macros will be calculated later
  'Shellfish',
  NULL, -- calories will be calculated later
  ARRAY['Balance Diet', 'High Protein', 'High-Fiber', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  150,
  ''
);
