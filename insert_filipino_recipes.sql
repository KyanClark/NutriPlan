-- Insert Filipino Recipes into Supabase
-- This SQL statement inserts 25 authentic Filipino recipes with proper diet classifications and allergy warnings

INSERT INTO recipes (title, image_url, short_description, ingredients, instructions, allergy_warning, diet_types, cost) VALUES

-- 1. Vegan Longganisa
(
  'Vegan Longganisa',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/vegan_longganisa_with_mushroom.png',
  'This vegan version of longganisa uses a mix of extra firm tofu or tokwa and minced mushrooms that I seasoned and shaped into small links before pan-frying to create a plant-based version of a Filipino classic.',
  ARRAY[
    '10 oz extra firm tofu or tokwa',
    '1/2 lb mushrooms minced',
    '8 cloves garlic minced',
    '4 tbsp tomato paste',
    '1/2 tsp ground black pepper',
    '3-4 tbsp soy sauce adjust to taste',
    '1 tsp Knorr liquid seasoning',
    '1/4 cup brown sugar',
    '3 tbsp corn starch',
    '1 cup bread crumbs',
    'Neutral oil for frying',
    '1/2 tsp black salt or sub for regular adjust (to taste)',
    '1/2 tsp turmeric powder for color',
    '1 1/2 tsp nutritional yeast optional',
    'Ground black pepper',
    'Sprinkle of liquid aminos or soy sauce to taste',
    '1/4 cup distilled white vinegar for dipping',
    '1/2 small red onion diced',
    '1-2 tsp sugar adjust to taste',
    '1 red chili sliced optional'
  ],
  ARRAY[
    'Drain excess liquid from the tofu. I usually do this by wrapping the block in some paper towels before placing a plate or flat surface on top so the water seeps out and is absorbed by the towel.',
    'If using dried shiitake mushrooms, soak these in hot water for 30 minutes until rehydrated. You can also leave this to soak overnight. Squeeze out the water from the mushrooms.',
    'For all the mushrooms, you can finely mince these or process them.',
    'Heat a large pan or skillet over medium heat. Add a little oil. Add the mushrooms and sauté for 2-3 minutes or until cooked. Turn off the heat. Set aside to cool. Cooking the mushrooms will help draw out extra moisture.',
    'In a bowl, crumble the tofu with your hands. Add in the mushrooms and the rest of the ingredients. Mix throughly until well incorporated.',
    'You can taste some of the mixture and season more if needed.',
    'Shape 1.5 tbsp of the mixture into a small cocktail sausage-like shape. The longganisa or Filipino sausage mixture should hold up well. If it easily crumbles or falls apart, you can add 1-2 tbsp more of bread crumbs to help absorb the excess moisture.',
    'You can also shape the sausages however way you like.',
    'In a frying pan, add enough oil to submerge half of the sausages.',
    'To test out the heat of the oil, you can add a small piece of the longganisa. It should immediately sizzle in the oil.',
    'Add the longganisa in the oil. Cook the longganisa for 2-3 minutes on each side or until golden brown. Flip over and cook the remaining side.',
    'Drain the longganisa from the oil.',
    'Serve with the tofu scramble, garlic rice or sinangag, and vinegar for dipping. Enjoy!'
  ],
  'Soy, Wheat/Gluten',
  ARRAY['Vegan', 'Dairy Free', 'High Protein', 'Flexitarian'],
  85.0
),

-- 2. Garlic Butter Shrimp
(
  'Garlic Butter Shrimp',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/garlic_butter_shrimp.jpeg',
  'Garlic Butter Shrimp is a savory seafood dish where shrimp is sautéed in a rich mixture of garlic and butter, often enhanced with a touch of lemon juice, herbs, or seasoning. It''s known for its bold garlicky flavor, tender shrimp texture, and the silky butter sauce that coats each bite.',
  ARRAY[
    '0.33 lbs shrimp cleaned',
    '0.33 tablespoons parsley chopped',
    '0.04 cup butter',
    '0.17 head garlic crushed',
    '0.17 cup lemon lime soda',
    '0.17 teaspoon lemon juice salt and pepper to taste'
  ],
  ARRAY[
    'Marinate the shrimp in lemon soda for about 10 minutes',
    'Melt the butter in a pan.',
    'Add the garlic. Cook in low heat until the color turns light brown',
    'Put-in the shrimp. Adjust heat to high. Stir-fry until shrimp turns orange.',
    'Season with ground black pepper, salt, and lemon juice. Stir.',
    'Add parsley. Cook for 30 seconds.',
    'Serve hot. Share and Enjoy!'
  ],
  'Shellfish, Dairy',
  ARRAY['Balance Diet', 'Pescatarian', 'High Protein Diet', 'Flexitarian'],
  110.0
),

-- 3. Chicken Liver and Gizzard Adobo
(
  'Chicken Liver and Gizzard Adobo',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_liver_and_gizzard_adobo.jpeg',
  'Chicken Liver and Gizzard Adobo is a Filipino dish made by simmering chicken liver and gizzard in vinegar, soy sauce, garlic, onions, and spices, following the classic adobo cooking style. It is known for its savory and slightly tangy flavor, with the liver giving it richness while the gizzard adds a chewy texture.',
  ARRAY[
    '0.17 lb. chicken gizzard',
    '0.17 lb. chicken liver',
    '0.08 cup all-purpose flour',
    '0.08 cup soy sauce',
    '0.04 cup white vinegar',
    '0.17 teaspoon garlic powder',
    '1 piece dried bay leaves',
    '0.17 teaspoon whole peppercorn',
    '0.83 cloves crushed garlic',
    '0.13 cup water Salt to taste',
    '0.33 tablespoons green onion chopped',
    '0.67 tablespoons cooking oil'
  ],
  ARRAY[
    'Boil the chicken gizzard in 4 cups of water (covered) for 60 to 90 minutes. Drain the water and set aside.',
    'Sprinkle 1 teaspoon garlic powder and 1/4 teaspoon salt all over the chicken liver. Let it stay for 10 minutes.',
    'Heat the cooking oil in a frying pan.',
    'Dredge the chicken liver in all-purpose flour. Pan fry for 2 minutes per side. Remove the pan-fried chicken liver. Set aside.',
    'On the same pan using the remaining oil, add the garlic, Cook until the color turns light brown.',
    'Put-in the gizzard and pan-fried liver. Stir.',
    'Add the soy sauce and water. Let boil.',
    'Add the bay leaves and whole peppercorn. Cover and simmer for 15 to 20 minutes.',
    'Add the vinegar. Let the liquid re-boil. Stir and cook for 5 minutes.',
    'Turn the heat off. Transfer to a serving plate.',
    'Top with chopped green onions. Serve. Share and enjoy!'
  ],
  'Soy, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian', 'Dairy Free', 'Keto / Low Carbs'],
  100.0
),

-- 4. Chicken Feet Adobo
(
  'Chicken Feet Adobo',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_feet_adobo.jpeg',
  'Chicken Feet Adobo is a Filipino dish that features chicken feet cooked in the traditional adobo style, resulting in a savory, tangy, and gelatinous delicacy often eaten with rice or served as pulutan (appetizer).',
  ARRAY[
    '0.25 lb chicken feet cleaned',
    '0.06 cup soy sauce',
    '0.06 cup white vinegar',
    '0.25 tablespoon oyster sauce',
    '0.13 teaspoon whole peppercorn',
    '0.75 pieces Thai chili pepper dried',
    '0.38 teaspoons sugar',
    '0.75 pieces bay leaves dried',
    '1.25 cloves garlic crushed',
    '4.5 tablespoons cooking oil',
    '0.38 cups water salt as needed'
  ],
  ARRAY[
    'Heat cooking pot and pour-in 16 tablespoons of cooking oil.',
    'Fry the chicken feet until color turns light brown. Set aside.',
    'On a clean pot, heat 2 tablespoons of cooking oil.',
    'Saute garlic and dried chili.',
    'Put-in the fried chicken feet, soy sauce, and water. Let it boil.',
    'Add the dried bay leaves, whole peppercorn, oyster sauce, and sugar. Stir and simmer until chicken feet becomes tender. Note: add water as necessary.',
    'Add vinegar and stir. Cook for 5 minutes more. Taste and add salt as needed.',
    'Turn-off heat, and then transfer to a serving plate.',
    'Serve. Share and enjoy!'
  ],
  'Soy, Wheat/Gluten',
  ARRAY['Balance Diet', 'Flexitarian', 'Dairy Free', 'Keto / Low Carbs Diet', 'High Protein Diet'],
  75.0
),

-- 5. Dynamite Lumpia
(
  'Dynamite Lumpia',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/dynamite_lumpia.jpeg',
  'Dynamite Lumpia is a Filipino snack or appetizer made by wrapping long green chilies in spring roll wrappers, usually stuffed with cheese or meat, then deep-fried to create a crispy, spicy, and savory treat often enjoyed as pulutan (beer food) or side dish.',
  ARRAY[
    '5.33 pieces long green pepper',
    '75.6 g cheddar cheese',
    '5.33 pieces lumpia wrapper',
    '298.67 g cooking oil',
    '113.4 g ground pork',
    '0.67 piece onion minced',
    '2 cloves garlic crushed and minced',
    '0.67 piece egg',
    '1.33 tablespoons cooking oil',
    'Salt and ground black pepper to taste'
  ],
  ARRAY[
    'Prepare the ground pork stuffing by heating 3 tablespoons oil in a pan. Saute garlic and onion until the latter softens. Add ground pork. Saute until medium brown. Season with salt and ground black pepper. Remove from the pan and put on a large bowl. Let it cool down.',
    'Beat 1 piece of egg and pour into the cooked ground pork. Mix well. Set aside.',
    'Slice one side of the peppers lengthwise all the way to the bottom. Remove the seeds by gently scraping using a small spoon or a butter knife. Set aside.',
    'Slice the cheddar cheese into long pieces. Stuff individual slices of cheese into each pepper. Scoop the cooked meat mixture and stuff into the chili peppers. Make sure that there is enough meat.',
    'Wrap the stuffed peppers in lumpia wrapper.',
    'Heat 2 cups of oil in a pan. Fry each piece of dynamite lumpia in medium heat for 2 minutes per side or until lumpia wrapper turns golden brown. Note: you may fry longer if needed.',
    'Remove from pan and place over a wire rack. Let it cool down. Arrange in a serving plate and then serve with your favorite condiment.',
    'Share and enjoy!'
  ],
  'Dairy, Wheat/Gluten, Eggs',
  ARRAY['Balance Diet', 'Flexitarian'],
  100.0
),

-- 6. Ginisang Puso ng Saging
(
  'Ginisang Puso ng Saging',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginisang_puso_ng_saging.jpg',
  'Ginisang Puso ng Saging is a classic Filipino dish made from banana heart (the purple flower of the banana plant), sautéed with pork, onions, garlic, and flavored with vinegar and seasonings. Sotanghon (vermicelli noodles) is often added for texture, making the dish hearty yet light. It has a slightly tangy and savory flavor, with a tender-crisp bite from the banana heart and richness from the pork.',
  ARRAY[
    '1 cup banana heart (about 100 g, cleaned and shredded)',
    '60 g (2 oz) pork, thinly sliced',
    '¼ Knorr Pork Cube',
    '15 g (½ oz) vermicelli (sotanghon), soaked in water',
    '¼ medium onion, chopped',
    '1 clove garlic, minced',
    '2 tsp white vinegar (≈ 0.13 cup scaled)',
    '1 ¼ cups water',
    '¾ tbsp cooking oil',
    '¼ tbsp (¾ tsp) salt',
    'Fish sauce and ground black pepper to taste'
  ],
  ARRAY[
    'Clean the banana heart and slice it into thin pieces. Combine ½ cup vinegar and 1 cup of water in a large bowl. Put the sliced banana heart into the mixture. Rub the salt onto it and soak for 10 to 20 minutes. Drain the liquid mixture and then wring the banana hearts (a chunk at a time) to force the liquid to come out. Set aside.',
    'Soak the vermicelli in 2 cups of water for 12 minutes. Drain the water and then set the vermicelli aside.',
    'Heat the oil in pan. Sauté the garlic and onion until the latter softens.',
    'Add the pork sliced. Continue to cook until it browns.',
    'Pour 1 cup of water into the pan. Cover it and let the water boil. Adjust the heat between low to medium heat setting. Cook until the liquid completely evaporates.',
    'Add the sliced banana hearts. Sauté it for 2 minutes.',
    'Pour the remaining 1 cup of water into the pan. Let it boil. Add Knorr Pork Cube. Cover and cook until the water reduces to half. Note: you can add more water if the banana heart slices needs to be cooked further to soften.',
    'Remove the cover and season with fish sauce and ground black pepper as needed.',
    'Serve with rice.'
  ],
  'Soy, Wheat/Gluten, Shellfish',
  ARRAY['Balance Diet', 'Dairy Free', 'Flexitarian'],
  60.0
),

-- 7. Tofu Vegetable Stir Fry
(
  'Tofu Vegetable Stir Fry',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/tofu_vegetable_stir_fry.jpg',
  'Tofu Vegetable Stir-fry is a hearty and colorful dish made with crispy tofu and a medley of vegetables such as cabbage, bok choy, mushrooms, carrots and peas. This dish is versatile, served as a main with rice or noodles, or enjoyed as a nutritious side.',
  ARRAY[
    '0.2 head cabbage sliced',
    '0.4 Knorr Chicken Cube',
    '0.4 bunch baby bok choy sliced',
    '2.4 shiitake mushrooms sliced',
    '6 snow peas',
    '4.8 oz. tofu extra firm, cubed',
    '0.3 cups green peas',
    '0.4 carrot sliced',
    '0.4 onion sliced',
    '1.6 cloves garlic crushed',
    '0.8 tablespoons soy sauce',
    '0.8 teaspoons sesame oil',
    '0.4 tablespoon oyster sauce',
    '0.4 tablespoon cornstarch',
    '0.4 cup water',
    '0.4 cup cooking oil',
    '0.2 teaspoon sugar',
    'Salt and ground black pepper to taste'
  ],
  ARRAY[
    'Heat 1 cup of oil in a small cooking pot. Deep fry the tofu until it turns golden brown. Set aside.',
    'Heat 3 tablespoons of the same oil in a wok. Sauté onion and garlic.',
    'Add mushrooms and carrot once the onion softens.',
    'Pour the soy sauce. Sauté for 2 minutes.',
    'Add snow peas, Knorr Chicken Cube, and water. Let boil.',
    'Put the oyster sauce along with the cabbage, bok choy, and green peas into the wok. Toss. Cover. Cook for 3 minutes.',
    'Add the fried tofu and season with sugar, salt, and ground black pepper.',
    'Combine cornstarch with 3 tablespoons water. Mix well and then pour into the wok. Stir and continue cooking until the sauce thickens.',
    'Finish by adding sesame oil.',
    'Transfer to a serving bowl. Serve with rice.'
  ],
  'Soy, Shellfish, Wheat/Gluten',
  ARRAY['Balance Diet', 'Vegetarian', 'Dairy Free', 'Flexitarian'],
  70.0
),

-- 8. Utan nga Langka
(
  'Utan nga Langka',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/utan_nga_langka.png',
  'Utan nga Langka is a traditional Visayan vegetable dish made with unripe jackfruit simmered in creamy coconut milk and flavored with dried fish (such as dulong), bago leaves (or malunggay/spinach), and spices. The dish is savory, slightly earthy, and mildly spicy when chilies are added. It is often enjoyed with steamed rice as a comforting, everyday home-cooked meal in the Philippines.',
  ARRAY[
    '0.67 lbs. unripe jackfruit sliced',
    '0.33 Knorr Shrimp cube',
    '226 g coconut milk',
    '157.73 g bago leaves sliced',
    '78.86 g dried fish dulong',
    '0.67 onions chopped',
    '1.67 cloves garlic chopped',
    '1 Thai chili pepper',
    '0.67 tablespoons vinegar',
    'Fish sauce to taste',
    '1 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat oil in a large wok.',
    'Sauté onion and garlic.',
    'Add the dried fish once the onions soften. Cook for 1 minute.',
    'Add unripe jackfruit. Cook while stirring for 2 to 3 minutes.',
    'Add chili peppers and bago leaves. Stir.',
    'Season with 1 tablespoon fish sauce and then pour-in the coconut milk. Let boil.',
    'Add vinegar. Cook for 5 to 8 minutes.',
    'Add Knorr Shrimp Cube. Continue cooking until the liquid evaporates completely.',
    'Season with ground black pepper and fish sauce as needed.',
    'Transfer to a serving plate. Serve with warm rice.'
  ],
  'Fish/Seafood, Shellfish, Soy/Gluten, Coconut',
  ARRAY['Balance Diet', 'Dairy Free', 'Pescatarian', 'Flexitarian'],
  55.0
),

-- 9. Kilawing Labanos
(
  'Kilawing Labanos',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/kilawing_labanos.png',
  'Kilawin is synonymous to ceviche. It is the Filipino way of preparing food by marinating in acid. Fish, meat, and vegetable can be marinated in vinegar (acetic acid), or calamansi (citric acid) until it gets fully cooked. There are certain dishes that needs extra cooking through fire. This dish is a good example.',
  ARRAY[
    '0.5 piece daikon radish',
    '70.88 g pork minced',
    '42.52 g pork liver minced',
    '95.63 g white vinegar',
    '0.75 teaspoons sugar',
    '0.5 piece onion sliced',
    '2 cloves garlic minced',
    '1.5 tablespoons cooking oil',
    '1 tablespoons salt for prep',
    'Salt and pepper to taste'
  ],
  ARRAY[
    'Slice the daikon radish into thin pieces. Arrange in a bowl and then add 2 tablespoons salt. Rub salt all over the radish slices and let is stay for 15 minutes. Squeeze the juice out of the radish. Rinse with water until all the salt goes off. Squeeze to release water.',
    'Combine prepared radish, pork, pork liver, sugar, onion, and white vinegar in a large bowl. Toss until well blended. Marinate for 20 minutes.',
    'Heat oil in a cooking pot. Saute garlic until golden brown.',
    'Add the marinated mixture. Let boil. Stir and then adjust the heat between low to medium. Cover the pot and continue to cook for 20 to 25 minutes.',
    'Season with salt and ground black pepper. Serve with warm white rice.'
  ],
  'None',
  ARRAY['Balance Diet', 'Dairy Free', 'Gluten Free', 'Flexitarian'],
  50.0
),

-- 10. Kalabasa and Corned Beef Nuggets
(
  'Kalabasa and Corned Beef Nuggets',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/kalabasa_and_corned_beef_nuggets.png',
  'Kalabasa and Corned Beef Nuggets are savory bite-sized patties made with grated squash (kalabasa), corned beef, breadcrumbs, and seasonings, then pan-fried until golden.',
  ARRAY[
    '12 ounces corned beef',
    '2 cups kalabasa',
    '1 piece egg',
    '1 teaspoon garlic powder',
    '1/2 teaspoon ground black pepper',
    '1 teaspoon salt',
    '1 cup breadcrumbs for the mixture',
    '1/2 cup breadcrumbs for coating',
    '2 1/2 cups cooking oil'
  ],
  ARRAY[
    'Grate the kalabasa or butternut squash using a cheese grater. You can also use a food processor.',
    'Combine grated kalabasa and corned beef in a bowl. Mix the ingredients together.',
    'Add garlic powder, pepper, salt, egg, and breadcrumbs. Continue to mix until all ingredients are well blended. Note: If the texture of the mixture is still sticky, you can add more breadcrumbs.',
    'Heat oil in a cooking pot.',
    'Scoop around 2 tablespoons of mixture and mold it into nuggets. Dredge in breadcrumbs.',
    'Fry one side until golden brown. Turn over and continue to fry the opposite side until the same color is achieved. Remove from the cooking pot and let excess oil drip.',
    'Transfer to a serving plate. Serve with your favorite dipping sauce.'
  ],
  'Eggs, Wheat/Gluten',
  ARRAY['Balance Diet', 'Dairy Free', 'Flexitarian'],
  65.0
),

-- 11. Seared Okra and Tomato
(
  'Seared Okra and Tomato',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/seared_okra_and_tomato.png',
  'Seared Okra and Tomato is a simple and healthy dish made by sautéing sliced okra with fresh tomatoes, garlic, and seasonings. The quick searing brings out the natural sweetness of the tomato while balancing the earthy flavor of okra.',
  ARRAY[
    '6 to 7.5 pieces okra sliced crosswise',
    '1 medium tomato cubed',
    '1 teaspoon garlic powder',
    'Salt and ground black pepper to taste',
    '1 tablespoon cooking oil'
  ],
  ARRAY[
    'Arrange sliced okra in a bowl. Add vinegar. Toss until coated.',
    'Heat a pan or a skillet. Pour cooking oil.',
    'Add okra when the oil is hot. Sear one side for 30 seconds. Stir and continue to cook the opposite side for another 30 seconds.',
    'Add tomatoes. Stir and cook for 5 to 7 minutes in medium heat while stirring every minute.',
    'Season with salt and ground black pepper.',
    'Transfer to a serving plate. Serve.'
  ],
  'None',
  ARRAY['Vegan', 'Vegetarian', 'Balance Diet', 'Keto/Low Carbs', 'Dairy Free'],
  25.0
),

-- 12. Ginisang Upo with Ground Pork and Shrimp
(
  'Ginisang Upo with Ground Pork and Shrimp',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginisang_upo_with_ground_pork_and_shrimp.png',
  'Ginisang Upo with Ground Pork and Shrimp is a dish that can be cooked on regular days. It is delicious, nutritious, and easy to make. It only takes less than 20 to complete the entire dish. This is best served with rice.',
  ARRAY[
    '1 small opo squash upo, sliced into thin pieces',
    '4 ounces ground pork',
    '6 pieces medium shrimp chopped',
    '1 medium ripe tomato cubed',
    '1 medium yellow onion sliced',
    '1 tablespoon chopped parsley optional',
    '4 cloves garlic crushed and pounded',
    '3 tablespoons fish sauce patis',
    '1/8 teaspoon ground black pepper',
    '½ cup water',
    '3 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat oil in cooking pot',
    'Saute garlic until light brown',
    'Add onion and tomato. Continue to cook until soft',
    'Put the ground pork into the pot. Cook until light brown',
    'Add shrimp. Cook for 2 minutes',
    'Add the opo squash (upo) into the pot. Cook for 2 minutes.',
    'Add water. Cover the pot and continue to cook between low to medium heat for 7 minutes.',
    'Add patis, ground black pepper, and parsley. Stir.',
    'Transfer to serving plate. Serve.'
  ],
  'Shellfish, Fish',
  ARRAY['Balance Diet', 'Dairy Free', 'Flexitarian'],
  75.0
),

-- 13. Sweet Pepper Relyeno
(
  'Sweet Pepper Relyeno',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sweet_pepper_relyeno.png',
  'Sweet Pepper Relyeno or Stuffed Sweet Peppers is an appetizer or main dish consisting of mini sweet peppers and ground pork. The ground pork was combined with spices and seasonings (which is somewhat similar to the mix in Lumpiang Shanghai), topped over the sweet pepper, pan-fried, and finished-up by baking.',
  ARRAY[
    '5 pieces sweet peppers sliced into half lengthwise and seeds removed',
    '0.5 lb. ground pork',
    '0.25 cup plain breadcrumbs',
    '1.5 pieces eggs',
    '0.38 cup Panko breadcrumbs',
    '0.5 medium yellow onion minced',
    '0.25 cup minced carrot',
    '0.5 teaspoon garlic powder',
    'Salt and ground black pepper to taste',
    '0.13 cup cooking oil'
  ],
  ARRAY[
    'Prepare the stuffing by combining the ground pork, 1 piece egg, minced onion and carrot, salt, ground black pepper, and garlic powder in a bowl. Mix well.',
    'Scoop around 1 1/2 tablespoons (or more) of the mixture and arrange it over the sliced sweet pepper. Gently press the mixture to keep it intact.',
    'Meanwhile, heat the cooking oil in a pan.',
    'While the oil is heating, beat the remaining 2 eggs. Dip the sweet pepper with ground pork in the egg and roll it over the Panko bread crumbs. Make sure that the top is fully coated with the bread crumbs.',
    'Pan fry the sweet pepper with breadcrumbs in medium heat until the breadcrumbs turns light to medium brown. Turn it over and cook the other side (side without the stuffing) for 2 minutes. Remove from the pan. Arrange in a baking tray lined with Aluminum foil.',
    'Preheat the oven to 350F.',
    'Bake the pan fried sweet peppers for 25 minutes.',
    'Remove from the oven. Arrange in a plate lined with paper towels.',
    'Serve with ketchup.'
  ],
  'Eggs, Wheat/Gluten',
  ARRAY['Balance Diet', 'Flexitarian'],
  80.0
),

-- 14. Ginisang Repolyo with Egg
(
  'Ginisang Repolyo with Egg',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginisang_repolyo_with_egg.jpeg',
  'A simple yet hearty Filipino stir-fry made with tender cabbage, carrots, and aromatics sautéed in savory seasonings, then finished with scrambled egg for added flavor and protein. Light, nutritious, and budget-friendly, this classic home-style dish is perfect as a standalone meal or a side to rice.',
  ARRAY[
    '¼ head cabbage, chopped',
    '1 egg',
    '½ small carrot, julienned',
    '¼ small onion, chopped',
    '2 stalks green onions, chopped',
    '1 clove garlic, minced',
    '1 teaspoon soy sauce',
    '½ teaspoon oyster sauce',
    '¼ teaspoon sesame oil (optional)',
    '1 pinch salt adjust to taste',
    '1 pinch ground black pepper',
    '1 small pinch sugar (optional)',
    '1 teaspoon cooking oil'
  ],
  ARRAY[
    'Combine chopped cabbage and salt. Mix it altogether. Let it stay for 10 minutes and then rinse with water. Set the cabbage aside.',
    'Beat the eggs and add a bit of salt and ground black pepper.',
    'Heat 2 tablespoons of cooking oil in a pan. Once the oil gets hot, pour beaten eggs. Cook it until firm and then cut into small pieces using the tip of your spatula or cooking spoon. Remove the egg from the pan. Set it aside.',
    'Heat the remaining oil. Sauté the onion and garlic.',
    'Once the onion softens. Add the carrots. Sauté for 30 seconds.',
    'Add the cabbage. Continue sautéing for 2 minutes.',
    'Add the soy sauce, oyster sauce, and sesame oil. Cook for 1 minute. Note: this is also the time to add sugar if you want.',
    'Put the scrambled eggs into the pan and then add the chopped green onions and sesame oil.',
    'Season it with ground black pepper and then serve.'
  ],
  'Eggs, Soy, Shellfish',
  ARRAY['Balance Diet', 'Dairy Free', 'Flexitarian'],
  35.0
),

-- 15. Egg Fried Rice
(
  'Egg Fried Rice',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/egg_fried_rice.jpeg',
  'A hearty and flavorful dish made by stir-frying leftover rice with egg, fresh vegetables, and savory seasonings. Enhanced with a touch of soy sauce and sesame oil, this simple recipe turns basic ingredients into a satisfying, budget-friendly meal that''s perfect for breakfast or any time of the day.',
  ARRAY[
    '2 eggs',
    '370 g leftover rice see note',
    '0.5 onion chopped',
    '0.25 bell pepper chopped',
    '1.5 sweet peppers chopped',
    '1 tablespoons soy sauce',
    '0.5 teaspoon sesame oil',
    '37.5 g green onion chopped',
    '0.13 teaspoon salt',
    '2 tablespoons cooking oil'
  ],
  ARRAY[
    'Crack the eggs and place in a bowl.',
    'Heat oil in a wok. Once the oil gets hot, pour the eggs into the wok. Cook until the bottom part turns brown and somewhat crispy. Turn the eggs over and do the same to the other side.',
    'Add the peppers and onion. Sauté the ingredients for 1 minute while breaking the eggs apart.',
    'Add half of the leftover rice. Stir fry for 2 minutes.',
    'Add the remaining rice. Continue cooking until all the ingredients are well blended.',
    'Pour the sesame oil and soy sauce. Continue stir frying for 2 minutes.',
    'Season with salt and sugar and add the green onions. Toss until well blended.',
    'Transfer to a serving plate. Serve with your favorite main dish and Enjoy!'
  ],
  'Eggs, Soy, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein Diet', 'Flexitarian'],
  40.0
),

-- 16. Sotanghon And Egg Noodle Soup
(
  'Sotanghon And Egg Noodle Soup',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sotanghon_and_egg_noodle_soup.jpg',
  'A warm and comforting noodle soup made with tender vermicelli, fresh cabbage, and savory seasonings, topped with a boiled egg and fragrant toasted garlic. Light yet satisfying, this budget-friendly dish is perfect for a hearty breakfast, quick lunch, or cozy dinner.',
  ARRAY[
    '2 eggs boiled and peeled',
    '64 grams vermicelli',
    '0.1 head cabbage shredded',
    '0.5 quarts water',
    '1 teaspoons chicken powder',
    '0.4 teaspoon annatto powder',
    '2 cloves garlic crushed',
    '0.4 onion chopped',
    '0.8 stalks of spring onion chopped',
    '0.4 teaspoon toasted garlic',
    '1.2 tablespoons cooking oil',
    'fish sauce and ground black pepper to taste'
  ],
  ARRAY[
    'Heat oil in a cooking pot.',
    'Sauté the garlic until it starts to brown. Add the onion and continue sautéing until it softens.',
    'Stir in the annatto powder and 2 teaspoons of fish sauce.',
    'Pour in the water and bring it to a boil.',
    'Add the vermicelli and chicken powder. Cover and let it re-boil, then reduce the heat to a simmer and cook for 3 minutes.',
    'Toss the noodles, then add the cabbage.',
    'Cover and cook for an additional 2 minutes.',
    'Add the boiled eggs and green onions, and season with fish sauce and ground black pepper.',
    'Transfer to a serving plate and top with toasted garlic. Serve hot, share, and enjoy!'
  ],
  'Eggs, Soy, Fish/Shellfish',
  ARRAY['High Carbohydrate', 'Budget Friendly', 'Flexitarian'],
  30.0
),

-- 17. Spinach Tomato and Cheese Omelette
(
  'Spinach Tomato and Cheese Omelette',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/spinach_tomato_and_cheese_omelette.jpg',
  'A creamy, savory dish made with fresh spinach and ripe tomato cooked with egg, then topped with melted cheddar cheese and rich butter. Nutritious, filling, and packed with flavor, perfect as a quick breakfast or light meal.',
  ARRAY[
    '2 eggs',
    '3/4 cups fresh baby spinach',
    '1 small ripe roma tomato chopped',
    '1/2 cup shredded cheddar cheese',
    '1/4 cup salted butter'
  ],
  ARRAY[
    'Melt half of the butter in a pan.',
    'Once the butter starts to bubble, add tomato. Saute for 1 minute.',
    'Put the spinach in the pan. Cook for 30 seconds. Transfer everything in a clean plate.',
    'Wipe the pan clean using a paper towel. Heat the pan in a stovetop using low to medium heat. Melt the remaining butter in the pan.',
    'Beat the eggs in a bowl. Pour into the pan. Tilt the pan to distribute the beaten eggs equally.',
    'Once the eggs starts to form, pour the cooked tomato and spinach over the egg. Top with shredded cheese. Continue to cook until the eggs are done.',
    'Fold the omelet halfway to secure the filling. You can top the omelet with more cheese.',
    'Transfer to a serving plate. Serve.'
  ],
  'Eggs, Dairy',
  ARRAY['Keto/Low Carb', 'High Protein', 'Light Meal', 'Flexitarian'],
  45.0
),

-- 18. Crab Meat Omelette
(
  'Crab Meat Omelette',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/crab_meat_omelette.jpg',
  'Crabmeat Omelette is a type of beaten egg preparation with crab meat. This is lightly fried using butter or oil. In the Philippines, this type of dish is referred to as "torta" and several different ingredients can be added with the egg. The more traditional method of preparation is adding the crabmeat (or any ingredient that takes a short time to cook) with the eggs while whisking. The eggs and crabmeat will then be poured in the pan and be cooked at the same time.',
  ARRAY[
    '3/4 cup crab meat fresh or canned',
    '1 small onion thinly sliced lengthwise',
    '3 pieces raw eggs',
    '4 tbsp. butter',
    '2 tbsp. green onions minced (optional)',
    'Salt and pepper to taste'
  ],
  ARRAY[
    'Heat the frying pan and put-in 2 tbsp of butter then allow to melt.',
    'Add the onion, crab meat, and green onions then cook until half done',
    'Add salt and pepper to taste then set aside.',
    'Heat the same frying pan (apply low heat) and put-in the remaining butter then allow to melt.',
    'Crack the eggs and place in a bowl then add some salt',
    'Whisk the eggs and pour on the frying pan',
    'Tilt the frying pan to allow the uncooked portions of the eggs (liquid form) to occupy the whole surface of the pan. You can also pull from the middle part of the pan to allow uncooked portions of the egg to occupy the space.',
    'Put the cooked crab meat and onions on top of the half side of the omelette.',
    'Cover the crab meat and onions by folding the other side of the omelette.',
    'Place in a serving plate.',
    'Serve hot with bread or rice. Share and Enjoy!'
  ],
  'Eggs, Dairy, Shellfish',
  ARRAY['Keto/Low Carb', 'Pescatarian', 'High Protein', 'Flexitarian'],
  85.0
),

-- 19. Sinangag
(
  'Sinangag',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sinangag_(Filipino%20Fried%20Frice).png',
  'Sinangag is a popular Filipino rice recipe that involves stir-frying rice with garlic. It is a simple way to cook your leftover rice, but it can do wonders for your meals with its simple savory flavor',
  ARRAY[
    '1 cups cooked white rice',
    '1.67 cloves crushed garlic',
    '0.17 teaspoon salt',
    '0.83 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat the cooking oil in a wide pan.',
    'While the cooking oil is being heated, add the crushed garlic. Note: make sure that the oil is not hot when you add the garlic. Let the garlic slowly cook while the oil gets heated until it becomes golden brown and crisp.',
    'Sprinkle the salt over the rice. Toss until the salt gets distributed evenly.',
    'Gradually add the the rice into the pan. Stir to distribute the ingredients. Continue to stir fry for 3 to 5 minutes.',
    'Transfer to a serving plate. Serve with your favorite dish.'
  ],
  'None',
  ARRAY['Vegan', 'Vegetarian', 'Balance Diet', 'Dairy Free', 'Gluten Free'],
  15.0
),

-- 20. Chicken Bistek
(
  'Chicken Bistek',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_bistek.png',
  'Chicken Bistek is a lighter take on the classic Filipino beef bistek. Made with chicken simmered in a savory soy sauce and calamansi (or lemon) marinade, then topped with sautéed onions, it''s a flavorful, tangy, and budget-friendly dish that pairs perfectly with rice.',
  ARRAY[
    '1 lbs boneless chicken breast',
    '1.5 cloves garlic',
    '1.5 pieces onion sliced into rings',
    '0.25 teaspoon sugar',
    '0.5 cup water',
    '0.13 cup cooking oil',
    'Salt and ground black pepper to taste',
    '0.38 cup soy sauce marinade ingredients',
    '0.5 piece lemon marinade ingredients',
    '0.13 teaspoon salt marinade ingredients',
    '1 cloves garlic crushed marinade ingredients'
  ],
  ARRAY[
    'Combine the marinade ingredients in a large bowl. Mix well.',
    'Add the chicken. Make sure that the chicken is completely coated with the marinade. Cover the bowl. Refrigerate overnight.',
    'Heat 2 tablespoons of cooking oil in a wok. Fry the chicken for 2 minutes per side. Remove from the wok. Set it aside.',
    'Heat the remaining cooking oil. Sauté the garlic and around ½ of the total amount of onions.',
    'Add the chicken once the onion softens. Continue cooking for 30 seconds.',
    'Pour the remaining marinade and 1 cup water. Let it boil. Adjust the heat to a simmer, cover the wok, and continue cooking for 35 minutes. Note: add more water as needed.',
    'Add the remaining onions. Cook for 2 minutes.',
    'Add the sugar and season with salt and ground black pepper.',
    'Transfer to a serving bowl. Serve.'
  ],
  'Soy, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Dairy Free', 'Flexitarian'],
  90.0
),

-- 21. Ginisang Repolyo (Sauteed Cabbage)
(
  'Ginisang Repolyo (Sauteed Cabbage)',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginisang_repolyo.png',
  'Ginisang Repolyo, or Sauteed Cabbage, is a simple yet flavorful Filipino dish that''s ideal for a quick and nutritious lunch or dinner. While this recipe is made with green cabbage, it can also be prepared with napa or savoy cabbage. This dish is a staple in many Filipino households because of its affordability and ease of preparation—a convenient choice for busy weekdays!',
  ARRAY[
    '1 head cabbage chopped',
    '4 ounces pork sliced',
    '1 onion sliced',
    '1 red bell pepper sliced',
    '4 cloves garlic crushed and minced',
    '3 tablespoons cooking oil',
    '1 cup beef broth',
    'Salt and pepper to taste'
  ],
  ARRAY[
    'Heat the cooking oil in a pan.',
    'Once the oil becomes hot, saute the garlic and onion.',
    'Put-in the pork and then cook for 5 minutes or until color turns medium brown.',
    'Pour-in half of the beef broth. Let boil and simmer until the liquid totally evaporate.',
    'Put-in the cabbage. Cook for 1 to 2 minutes.',
    'Add the red bell pepper. Stir and cook for 1 minute more.',
    'Add salt and pepper to taste.',
    'Pour-in remaining beef broth. Let boil. Stir.',
    'Transfer to a serving bowl and serve.'
  ],
  'None',
  ARRAY['Balance Diet', 'Dairy Free', 'Flexitarian'],
  40.0
),

-- 22. Chicken Giniling with Green Peas
(
  'Chicken Giniling with Green Peas',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_giniling_with_green_peas.png',
  'Chicken Giniling with Green Peas is a Filipino stew that makes use of ground chicken meat. This dish is usually made using ground pork (the dish using pork is called pork giniling), but it is a good idea to use other meat to see which is better.',
  ARRAY[
    '0.67 lbs ground chicken',
    '0.33 15 oz. can tomato sauce',
    '0.33 large potato cut into small cubes',
    '0.33 large carrot cut into small cubes',
    '0.5 cups frozen green peas',
    '0.33 medium yellow onion chopped',
    '0.67 teaspoons minced garlic',
    '0.33 cup chicken broth',
    '0.67 pieces dried bay leaves',
    'Salt and pepper to taste',
    '0.67 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat the cooking oil in a wide pan.',
    'When the oil is hot, sauté the garlic and onion until the onion softens.',
    'Add the ground chicken. Cook for 5 minutes in medium heat.',
    'Pour-in the tomato sauce and chicken broth. Let boil.',
    'Add the dried bay leaves. Simmer for 35 minutes covered. Note: add water or chicken broth as needed.',
    'Put-in the carrots and potato. Stir and cook for 8 to 10 minutes.',
    'Add the green peas. Cook for 3 to 5 minutes.',
    'Add salt and pepper to taste. Stir and turn-off heat',
    'Transfer to a serving plate and then serve.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy Free', 'Flexitarian'],
  70.0
),

-- 23. Sinigang na Hipon
(
  'Sinigang na Hipon',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sinigang_na_hipon.jpeg',
  'Sinigang na Hipon is a Filipino main dish having shrimp as the main ingredient. This dish also includes a variety of vegetables such as daikon radish, snake beans, okra, and eggplant. This dish is best served during cold weather. It is best enjoyed hot with a cup of white rice.',
  ARRAY[
    '0.5 lb. shrimp cleaned',
    '22 grams Knorr Sinigang sa Sampaloc Mix',
    '0.5 bunch kangkong',
    '7.5 pieces snake beans',
    '2.5 pieces okra',
    '0.5 piece eggplant',
    '0.5 cup daikon radish sliced',
    '0.5 piece tomato sliced',
    '1.5 pieces long green pepper',
    '0.5 piece onion',
    '1 quarts water',
    'Fish sauce and ground black pepper to taste'
  ],
  ARRAY[
    'Boil water in a cooking pot. Add onion, tomato, and radish. Cover and continue to boil for 8 minutes.',
    'Add shrimp. Cook for 1 minute.',
    'Add Knorr Sinigang sa Sampaloc Recipe Mix. Stir until it dilutes completely. Cover and cook for 3 minutes.',
    'Add long green pepper, snake beans, okra, and eggplant. Stir. Cook for 5 minutes.',
    'Put the kangkong stalks into the pot. Season with fish salt and ground black pepper.',
    'Add kangkong leaves. Cook for 1 minute.',
    'Transfer to a serving bowl. Serve warm with rice.'
  ],
  'Shellfish, Fish',
  ARRAY['Balance Diet', 'Dairy Free', 'Pescatarian', 'Flexitarian'],
  95.0
),

-- 24. Ginisang Ampalaya (Sauteed Bitter Melon)
(
  'Ginisang Ampalaya (Sauteed Bitter Melon)',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginisang_ampalaya.jpeg',
  'Ginisang Ampalaya is a classic Filipino sautéed dish made with bitter melon (ampalaya), garlic, onion, and tomato. This healthy, fiber-rich dish is budget-friendly and widely enjoyed in Filipino households.',
  ARRAY[
    '1 pieces ampalaya cleaned and cut into thin slices',
    '0.5 tbsp garlic minced',
    '0.25 tsp ground black pepper',
    'salt to taste',
    '1 egg',
    '9 ounces luke warm water',
    '0.5 tomato sliced',
    '0.5 onion sliced',
    '1.5 tbsp cooking oil'
  ],
  ARRAY[
    'Place the ampalaya in a large bowl',
    'Add salt and lukewarm water then leave for 5 minutes',
    'Place the ampalaya in a cheesecloth then squeeze tightly until all liquid drips',
    'Heat the pan and place the cooking oil',
    'Saute the garlic, onion, and tomato',
    'Add the ampalaya mix well with the other ingredients',
    'Put-in salt and pepper to taste',
    'Beat the eggs and pour over the ampalaya then let the eggs cook partially',
    'Mix the egg with the other ingredients',
    'Serve hot.'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'Dairy Free', 'Flexitarian'],
  30.0
);
