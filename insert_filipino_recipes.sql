-- Insert Filipino Recipes into Supabase
-- This SQL statement inserts 16 authentic Filipino recipes with proper diet classifications and allergy warnings

INSERT INTO recipes (title, image_url, short_description, ingredients, instructions, allergy_warning, diet_types, cost) VALUES

-- 1. Ampalaya (Bitter Melon) With Pork
(
  'Ampalaya (Bitter Melon) With Pork',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ampalaya_(Bitter%20Melon)_with_pork.jpeg',
  'Ampalaya with Pork is a Filipino dish of sautéed bitter melon with lean ground pork, garlic, onion, and soy sauce, known for its savory taste and health benefits.',
  ARRAY[
    '1 cup onion, chopped',
    '6 cloves garlic, crushed',
    '1 tablespoon olive oil',
    '½ pound (0.2 kg) lean ground pork',
    '2 cups Ampalaya*, sliced',
    '2 teaspoons light soy sauce',
    '½ teaspoon black pepper'
  ],
  ARRAY[
    'Using a large skillet, lightly sauté onions and garlic in hot olive oil.',
    'Add the ground pork and cook until almost done.',
    'Add the sliced bitter melon.',
    'Cover and simmer until bitter melon turns green. Do not overcook.',
    'Season with light soy sauce and black pepper.'
  ],
  'Soy, Pork Meat',
  ARRAY['Balance Diet', 'Dairy Free', 'High Protein', 'Gluten Free', 'Flexitarian'],
  80.0
),

-- 2. Fish Cardillo
(
  'Fish Cardillo',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/fish_cardillo.jpg',
  'Fish Cardillo is a Filipino dish made of fried fish simmered with tomatoes, onions, and beaten egg whites, then topped with green onions for a savory, hearty meal.',
  ARRAY[
    '1 pound (½ kg) trevally(talakitok)',
    '4 teaspoons corn oil for sauté',
    '¼ cup flour',
    '1 large onion, sliced',
    '3 or 4 medium-sized tomatoes, chopped',
    '½ cup egg whites, beaten',
    '½ cup water',
    'A dash ground pepper',
    '15 stalks green onions, chopped'
  ],
  ARRAY[
    'Thoroughly clean fish. Remove scale and gills, and wash thoroughly. Drain and set aside.',
    'Slice the raw fish into six pieces.',
    'Heat corn oil in frying pan.',
    'Place the flour into a bowl or plastic bag. Place the raw fish in the flour and cover the outside of each fish with flour.',
    'Sauté fish until golden brown. Set aside on top of a paper towel.',
    'Sauté onion and tomatoes. Add ½ cup of water.',
    'Add the beaten egg whites and fish. Cover and let it simmer for 5–10 minutes.',
    'Season with ground pepper.',
    'Sprinkle with chopped green onions.'
  ],
  'Fish, Eggs, Wheat/Gluten',
  ARRAY['Balance Diet', 'Dairy Free', 'High Protein', 'Pescatarian', 'Flexitarian'],
  90.0
),

-- 3. Filipino Style Escabeche
(
  'Filipino Style Escabeche',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/escabetche.jpeg',
  'Fish Escabeche is a well-loved Filipino dish often served during special occasions and family gatherings.',
  ARRAY[
    '1.2 lbs fish (large) sliced into serving pieces',
    '0.45 cup cooking oil',
    '1.2 tablespoons salt',
    '0.6 onion thinly sliced',
    '1.8 cloves garlic chopped',
    '1.2 thumbs ginger Julienne',
    '0.6 red bell pepper Julienne',
    '0.6 green bell pepper Julienne',
    '0.6 carrot Julienne',
    '1.8 tablespoons white vinegar',
    '2.4 tablespoons banana ketchup',
    '1.8 tablespoons white sugar',
    '0.6 cup water',
    '0.6 tablespoon cornstarch',
    '1.2 tablespoons cooking oil',
    'Salt and ground black pepper to taste'
  ],
  ARRAY[
    'Rub salt all over the fish slices. Let it stand for 5 minutes.',
    'Heat cooking oil. Fry both sides of the fish until it turns golden brown in color. Remove the fish from the pan and arrange on a serving plate.',
    'Make the escabeche sauce by heating 2 tablespoons of oil in a pan. Sauté garlic, ginger, and onion until the latter softens.',
    'Add banana ketchup, vinegar, sugar, and water. Stir and let boil.',
    'Put the bell peppers and carrots into the pan. Cook for 3 minutes.',
    'Season with salt and pepper.',
    'Combine cornstarch with 2 tablespoons of water. Mix well. Pour the mixture into the pan. Stir until the sauce thickens to your desired consistency.',
    'Pour the escabeche sauce over the fried fish. Serve warm.',
    'Share and enjoy.'
  ],
  'Fish',
  ARRAY['Balance Diet', 'Dairy Free', 'High Protein', 'Gluten Free', 'Pescatarian', 'Flexitarian'],
  120.0
),

-- 4. Chicken Halang-Halang
(
  'Chicken Halang-Halang',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_halang_halang.jpeg',
  'Chicken Halang-Halang is a comforting Visayan stew similar to tinola but with coconut milk and chili for a rich, spicy kick. This hearty dish combines chicken, vegetables, and malunggay (moringa leaves) for a nutritious and flavorful meal perfect with steamed rice.',
  ARRAY[
    '2 lbs. chicken cut into serving pieces',
    '1 can 2 cups coconut milk',
    '1 medium yellow onion diced',
    '1 teaspoon minced garlic',
    '1 thumb ginger julienne',
    '2 teaspoons chili flakes',
    '6 to 8 lemongrass blades',
    '1 small green papaya wedged',
    '3/4 to 1 cup hot pepper leaves or malunggay',
    '2 tablespoons fish sauce',
    '1/4 teaspoon ground black pepper',
    '3 tablespoons cooking oil'
  ],
  ARRAY[
    'In a wide pot, heat oil over medium heat. Add ginger, onion, garlic, and green chilis. Saute until limp and aromatic, about 2-3 minutes.',
    'Add the chicken, fish sauce, ground pepper, and lemongrass. Stir to coat the chicken with oil. Cover with lid to let the juices from the chicken out. Cook for 3-8 minutes until the sides of chicken are a bit browned.',
    'Pour in water, cover and cook for 15 minutes.',
    'Add the green papaya and mix. Pour in the coconut milk and add the labuyo. Cover again and let it simmer over low heat for 10-15 minutes or until the papaya and chicken are tender. Add water if needed.',
    'Season with salt and pepper if needed. Lastly add the chili leaves and stir. Cook for another 2 minutes then turn off the heat.',
    'Transfer to individual serving bowls and enjoy with rice.'
  ],
  'Fish (fish sauce), Coconut',
  ARRAY['Balance Diet', 'High Protein', 'Dairy Free', 'Gluten Free', 'Flexitarian'],
  85.0
),

-- 5. Beef Bulalo
(
  'Beef Bulalo',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/beef_bulalo.jpeg',
  'Beef Bulalo is a classic Filipino comfort food known for its rich, savory broth and tender beef shanks with bone marrow. It''s often enjoyed during rainy or cold weather, served with vegetables like corn, cabbage, and potatoes for a hearty, filling meal.',
  ARRAY[
    '2 pounds meaty beef bone marrow',
    '1 pound beef brisket or shank',
    '8-10 cups water',
    '1 tablespoon peppercorns',
    '¼ cup fish sauce',
    '1 medium onion quartered',
    '3 medium potatoes cut in halves',
    '2 ears sweet corn shucked and cut into 3 or 4 each',
    '1 small cabbage quartered',
    '2 stalks onion leeks white part and green part separated',
    'Salt as needed'
  ],
  ARRAY[
    'In a bowl, soak the brisket in water to draw out blood. Refrigerate until ready to use.',
    'Rinse the beef bone marrow and then place in a pot and fill with enough water to cover. Bring to a boil over high heat then lower the heat to let it simmer for 5 minutes to let the scums out.',
    'Drain and discard the water and clean the pot. Rinse the bones again to make sure no scum is left.',
    'Return the beef marrow to the clean pot and fill with 8-10 cups of water to cover. Bring to a boil over high heat. Once it boils cover the pot and reduce heat to achieve a medium boil. Let it boil for an hour or 30 minutes if using pressure cooker.',
    'Add the soaked brisket (water drained), fish sauce, onion, the white part of onion leek, and peppercorns. Boil until meat is fork-tender, about 1.5 to 2 hours more or 30 minutes if using a pressure cooker. Add more water if needed to cover the meat. Then turn the heat back on and bring to a gentle boil.',
    'Add the potatoes and cook for 10 minutes or until tender. Then add the corn and cabbage and cook for 3-5 minutes.',
    'Lastly, add the green part of the onion leeks and salt if still needed then turn off the heat.',
    'Transfer to serving bowls.'
  ],
  'Fish (fish sauce)',
  ARRAY['Balance Diet', 'High Protein', 'Low Carb', 'Gluten Free', 'Flexitarian'],
  150.0
),

-- 6. Pritong Tilapia
(
  'Pritong Tilapia',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/pritong_tilapia.jpeg',
  'Pritong Tilapia is one of the simplest and most affordable Filipino ulam. This dish highlights the natural flavor of fresh tilapia, seasoned lightly with salt and pepper, then fried until golden and crispy. Best enjoyed with steamed rice and sawsawan (dipping sauce) like vinegar with garlic and chili.',
  ARRAY[
    '2 pieces tilapia cleaned and scales removed',
    '2 teaspoons salt',
    '1 cup cooking oil'
  ],
  ARRAY[
    'Rub salt all over the fish including the insides.',
    'Heat oil in a wide frying pan.',
    'When the oil is hot, put-in the tilapia. Cover the frying pan, but make sure to open it a little so that steam can come out. Fry each side in medium heat for about 6 to 10 minutes. Note: I usually wait until I don''t hear any sound. This means that the liquid is gone and the fish is crisp.',
    'Remove from the pan and arrange in a serving plate.',
    'Serve with your favorite condiments and side dish.',
    'Share and enjoy!'
  ],
  'Fish',
  ARRAY['Balance Diet', 'Dairy Free', 'Pescatarian', 'Flexitarian'],
  55.0
),

-- 7. Tokwa''t Baboy
(
  'Tokwa''t Baboy',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/tokwa''t_baboy.jpeg',
  'Tokwa''t Baboy is a popular Filipino appetizer and pulutan made with tender boiled pork and crispy fried tofu, tossed in a savory-sour soy-vinegar sauce with onions and chili. It''s usually served as a side dish for lugaw (rice porridge) or enjoyed with steamed rice.',
  ARRAY[
    '1 lb pig ears',
    '1 lb pork belly liempo',
    '1 lb tofu extra firm tofu',
    '1 tablespoon whole peppercorn',
    '1 piece onion sliced',
    '3 Thai chili pepper chopped',
    '2 stalks scallions cut in 1/2 inch length',
    '5 cups water',
    '2 cups cooking oil',
    'Vinegar sauce ingredients: 1 1/2 cup white vinegar',
    '1/4 cup soy sauce',
    '1 1/2 teaspoons sugar',
    '1/2 teaspoon salt',
    '1/8 teaspoon ground black pepper'
  ],
  ARRAY[
    'Pour-in water in a pot and bring to a boil.',
    'Add salt and whole peppercorn.',
    'Put-in the pig''s ears and pork belly then simmer until tender (about 30 mins to 1 hour).',
    'Pour cooking oil on a separate pan and allow to heat.',
    'When the oil is hot enough, deep-fry the tofu until color turns golden brown and outer texture is somewhat crispy.',
    'Cut pig''s ears and pork belly into bite-sized pieces then set aside.',
    'Combine the vinegar sauce ingredients starting with sugar, salt, soy sauce, and vinegar. Stir.',
    'Microwave for 1 minute.',
    'Add the ground black pepper, onions, green onions, and chili pepper. Transfer the sauce in a serving bowl.',
    'Place the sliced meat and tofu in a serving plate with the bowl of sauce by the side.',
    'Serve hot and Enjoy!'
  ],
  'Soy, Wheat/Gluten',
  ARRAY['Balance Diet', 'Dairy Free', 'Flexitarian'],
  65.0
),

-- 8. Sardines with Misua
(
  'Sardines with Misua',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sardines_with_misua.jpg',
  'Sardinas with Misua is a comforting and budget-friendly Filipino dish made with canned sardines and thin wheat noodles (misua). It''s quick to prepare, hearty, and perfect for busy days or cold weather. The dish pairs well with rice or can be eaten on its own as a light yet filling meal.',
  ARRAY[
    '5 oz sardines canned with tomato sauce',
    '2 ounces misua thin flour noodles',
    '2 tablespoons fish sauce',
    '1/4 teaspoon ground black pepper',
    '2 cloves garlic minced',
    '1 onion minced',
    '1 1/2 cups water',
    '1 tablespoon toasted garlic',
    '1 teaspoon scallion chopped',
    '2 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat a cooking pot and pour-in oil.',
    'When the oil is hot enough, sauté garlic and onions.',
    'Add the sardines including the sauce and cook for 2 minutes.',
    'Put-in fish sauce and ground black pepper then stir.',
    'Add water and let boil.',
    'Put-in the misua and cook for 3 to 5 minutes under medium heat.',
    'Turn-off the heat and transfer to a serving bowl.',
    'Garnish with toasted garlic and chopped scallions on top.',
    'Serve hot. Share and enjoy!'
  ],
  'Fish, Wheat/Gluten',
  ARRAY['Balance Diet', 'Dairy Free', 'Pescatarian', 'Flexitarian'],
  35.0
),

-- 9. Adobong Pusit
(
  'Adobong Pusit',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/adobong_pusit.jpeg',
  'Adobong Pusit is a savory and slightly tangy Filipino squid dish cooked in soy sauce and vinegar, with a touch of sweetness and spice. The squid is simmered until tender, creating a flavorful sauce that pairs perfectly with steamed rice.',
  ARRAY[
    '1 lbs. medium-sized squid',
    '0.5 piece onion',
    '1 pieces tomatoes',
    '0.25 cup soy sauce',
    '0.25 cup vinegar',
    '0.5 cup water',
    '2.5 cloves crushed garlic',
    '0.5 teaspoon sugar',
    'Salt and pepper to taste',
    '1 tbsp cooking oil'
  ],
  ARRAY[
    'Heat a wok or cooking pot them pour-in soy sauce, vinegar, and water then bring to a boil.',
    'Add the squid and wait for the liquid to re-boil. Simmer for 5 minutes.',
    'Turn off the heat then separate the squid from the liquid. Set aside.',
    'Pour-in cooking oil on a separate wok of cooking pot then apply heat.',
    'When the oil is hot enough, sauté the garlic, onions, and tomatoes.',
    'Put-in the squid then cook for a few seconds.',
    'Pour-in the soy sauce-vinegar-water mixture that was used to cook the squid a while back. Bring to a boil and simmer for 3 minutes.',
    'Add the ink, salt, ground black pepper, and sugar then stir. Simmer for 3 minutes.',
    'Transfer to a serving bowl then serve.',
    'Share and enjoy! Note: If you want a thicker sauce, remove the squid from the wok or cooking pot and let the sauce boil until enough liquid evaporates. Once done, you may top the squid with the sauce.'
  ],
  'Shellfish, Soy',
  ARRAY['Balance Diet', 'Dairy Free', 'Pescatarian', 'Flexitarian'],
  70.0
),

-- 10. Chicken Curry
(
  'Chicken Curry',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_curry.png',
  'Chicken Curry is a flavorful Filipino dish with tender chicken pieces simmered in curry and coconut-flavored sauce. The mix of potatoes, bell peppers, celery, and spices creates a rich and comforting meal that pairs best with steamed rice.',
  ARRAY[
    '0.08 cup canola oil',
    '0.67 medium potatoes, peeled and quartered',
    '0.67 large carrots, peeled and cubed',
    '0.17 green bell pepper, cored, seeded and cut into cubes',
    '0.17 red bell pepper, cored, seeded and cut into cubes',
    '0.33 onion, peeled and cubed',
    '1 cloves garlic, peeled and minced',
    '0.33 thumb-size ginger, peeled and julienned',
    '0.33 (3 pounds) bone-in chicken, cut into serving pieces',
    '0.33 tablespoon fish sauce',
    '0.33 cup coconut milk',
    '0.33 cup water',
    '0.67 tablespoons curry powder',
    'salt and pepper to taste'
  ],
  ARRAY[
    'In a wide pan over medium heat, heat oil. Add potatoes and cook for about 2 to 3 minutes or until lightly browned and tender. Remove from pan and drain on paper towels.',
    'Add carrots and cook for about 1 to 2 minutes. Remove from pan and drain on paper towels.',
    'Remove excess oil from pan except for about 1 tablespoon. Add bell peppers and cook for about 30 to 40 seconds. Remove from pan and set aside.',
    'Add onions, garlic, and ginger and cook until softened.',
    'Add chicken and cook, stirring occasionally until lightly browned.',
    'Add fish sauce and continue to cook for about 1 minute.',
    'Add coconut milk and water. Bring to a simmer, skimming any scum that may float on top.',
    'Lower heat, cover, and simmer for about 20 to 30 minutes or until chicken is cooked.',
    'Add potatoes and carrots and cook for about 3 to 5 minutes or until tender.',
    'Add curry powder and stir to combine. Continue to cook for about 2 to 3 minutes or until sauce starts to thicken.',
    'Season with salt and pepper to taste.',
    'Add bell peppers and cook for about 1 minute or until tender yet crisp. Serve hot.'
  ],
  'Coconut, Fish (fish sauce), Soy/Wheat-Gluten',
  ARRAY['Balance Diet', 'Flexitarian', 'Dairy Free'],
  95.0
),

-- 11. Ginataang Puso ng Saging
(
  'Ginataang Puso ng Saging',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginataang_puso_ng_saging.png',
  'Ginataang Puso ng Saging is a creamy and flavorful Filipino dish made from banana blossom (puso ng saging) simmered in coconut milk with aromatics, chili, and optional shrimp or fish sauce for extra depth. It''s a delicious and budget-friendly ulam often paired with rice.',
  ARRAY[
    '1 cups banana blossom sliced and cleaned',
    '26.67 grams Knorr Ginataang Gulay Mix',
    '0.33 cup ground pork',
    '5.33 pieces shrimp shell and head removed',
    '3.33 pieces Thai chili pepper',
    '0.67 piece onion chopped',
    '2.67 cloves garlic minced',
    'Ground black pepper to taste',
    '1 cups water',
    '2 tablespoons cooking oil'
  ],
  ARRAY[
    'Slice banana blossom into thin pieces. Soak in 1/2 cup vinegar for 15 minutes. Rinse and wring tight. Set aside.',
    'Combine Knorr Ginataang Gulay Mix and water. Stir until powder dilutes completely. Set aside.',
    'Heat oil in a pot. Add garlic and cook until it starts to brown.',
    'Add onion. Saute while constantly stirring until onion softens.',
    'Add ground pork. Cook until pork turns light brown.',
    'Put the banana blossoms in the pan. Saute for 2 minutes. Pour vinegar.',
    'Cover and cook in medium heat for another 2 minutes.',
    'Pour Knorr Ginataang Gulay mixture and add chili peppers. Let boil. Cover the pot and continue cooking in low to medium heat for 7 to 10 minutes. Note: add more water as needed.',
    'Add shrimp. Cook for 2 minutes. Season with ground black pepper.',
    'Transfer to a serving bowl and serve. Share and enjoy!'
  ],
  'Shellfish (if shrimp is added), Fish (if fish sauce is used)',
  ARRAY['Balance Diet', 'Dairy Free', 'Flexitarian', 'Pescatarian'],
  60.0
),

-- 12. Ginisang Kalabasa at Sitaw with Daing
(
  'Ginisang Kalabasa at Sitaw with Daing',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginisang_kabalasa_at_sitaw_with_daing.jpeg',
  'Ginisang Kalabasa at Sitaw with Daing is a hearty Filipino dish made by sautéing squash and string beans with garlic, onion, and tomato, then flavored with daing (dried fish). The combination of vegetables and preserved fish makes it a nutritious, savory, and budget-friendly ulam that pairs perfectly with steamed rice.',
  ARRAY[
    '0.5 lb calabasa squash kalabasa, sliced into cubes',
    '4 pieces string beans sitaw, cut into 2 inch pieces',
    '0.38 cup salted dried fish daing, shredded or chopped',
    '0.25 cup water',
    '0.5 medium yellow onion chopped',
    '2.5 cloves garlic crushed',
    '0.06 teaspoon ground black pepper',
    '1 to 1.25 tablespoons fish sauce',
    '1.5 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat the oil in a pan.',
    'Saute the garlic and onion.',
    'Once the onion starts to get soft, add the dried fish. Stir.',
    'Put-in the calabaza squash. Continue to stir fry for 1 minute.',
    'Pour-in water and bring to a boil. Cover and cook for 5 to 6 minutes or until the water evaporates.',
    'Stir in the string beans. Cook for 2 minutes in medium heat.',
    'Add fish sauce and ground black pepper. Cook for 1 to 3 minutes more.',
    'Transfer to a serving plate. Share and enjoy!'
  ],
  'Fish (from daing), Fish (fish sauce)',
  ARRAY['Balance Diet', 'Dairy Free', 'Flexitarian', 'Pescatarian'],
  45.0
),

-- 13. Pancit Lomi
(
  'Pancit Lomi',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/pancit_lomi.jpg',
  'Pancit Lomi is a hearty Filipino noodle soup made with thick egg noodles simmered in a savory broth with vegetables, chicken or pork, and sometimes fish balls or kikiam. Often topped with a beaten egg for added richness, this comfort food is a favorite during rainy days.',
  ARRAY[
    '0.75 package (14 ounces) lomi noodles',
    'Water',
    '1.5 tablespoons canola oil',
    '0.75 cup chicken liver, cut into cubes',
    '0.75 onion, peeled and chopped',
    '1.5 cloves garlic, peeled and minced',
    '0.38 pound boneless, skinless chicken breast or thigh meat, cut into thin strips',
    '0.75 tablespoon fish sauce',
    '0.75 package (1.4 ounces) crab and corn soup mix',
    'salt and pepper to taste',
    '1.5 medium carrots, peeled and julienned',
    '0.75 small napa cabbage, end trimmed and sliced into 1-inch thick strips',
    '1.5 eggs, lightly beaten',
    '0.75 tablespoon corn starch'
  ],
  ARRAY[
    'In a pot, bring enough water to cover noodles to a boil. Add noodles and blanch for about 1 minute. Drain and rinse in cold water.',
    'In a pan over medium heat, heat about 1 tablespoon oil. Add liver and cook until just about done. Remove from pan and keep warm.',
    'In a large pot over medium heat, heat remaining 1 tablespoon oil. Add onions and garlic and cook until softened.',
    'Add chicken and cook until lightly browned.',
    'Add fish sauce and cook, stirring occasionally, for another 1 minute.',
    'Add about 8 cups of water and bring to a boil.',
    'Lower heat, cover, and simmer until chicken is cooked through.',
    'Add noodles and cook for about 1 to 2 minutes or until half-cooked.',
    'Add crab and corn soup mix and stir to dissolve. Season with salt and pepper to taste.',
    'Add liver and cook for about 1 to 2 minutes.',
    'Add carrots and cook for about 1 minute. Add napa cabbage and continue to cook for about 1 minute or until vegetables are tender yet crisp.',
    'In a small bowl, combine corn starch and ¼ cup cold water and stir to dissolve. Add to the pot, stirring to combine. Continue to cook for until slightly thickened.',
    'Add eggs slowly in a thin stream and allow to slightly set before stirring. Serve hot.'
  ],
  'Eggs (from noodles and egg topping), Wheat/Gluten (from noodles, soy sauce, fish balls), Soy (from soy sauce, fish balls), Fish (if fish balls are used)',
  ARRAY['Balance Diet', 'Flexitarian'],
  50.0
),

-- 14. Ginisang Sayote
(
  'Ginisang Sayote',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginisang_sayote.jpg',
  'Ginisang Sayote is a simple yet healthy Filipino dish made by sautéing chayote (sayote) with garlic, onion, and tomato. Sometimes cooked with a bit of pork, shrimp, or fish sauce for added flavor, but it can also be kept vegetarian. It''s light, nutritious, and budget-friendly.',
  ARRAY[
    '1.5 pieces medium chayote peeled, seed removed, and sliced',
    '2.5 cloves garlic crushed',
    '0.5 medium sized onion sliced',
    '0.5 medium sized tomatoes chopped',
    '0.13 lb ground pork',
    '1 tablespoons cooking oil',
    '0.5 teaspoon salt',
    '0.25 tsp ground black pepper'
  ],
  ARRAY[
    'Heat the cooking oil in a pan.',
    'Sauté the garlic, onion, and tomato.',
    'When the tomato becomes soft, add the ground pork and then cook for 6 to 8 minutes.',
    'Put-in the chayote. Stir.',
    'Cover. Let boil and simmer for 7 to 10 minutes.',
    'Add salt and ground black pepper. Stir.',
    'Serve with hot rice. Share and enjoy!'
  ],
  'None',
  ARRAY['Balance Diet', 'Flexitarian', 'Dairy Free'],
  30.0
),

-- 15. Utan Bisaya
(
  'Utan Bisaya',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/utan_bisaya.jpg',
  'Utan Bisaya or Law-Uy is a vegetable soup made with the freshest of vegetables boiled in water. It is similar to another popular vegetable soup, bulanglang.',
  ARRAY[
    '1 pc Knorr Shrimp Cube',
    '2 cups water',
    '1 cup kalabasa, peeled and cubed',
    '1/2 cup gabi, peeled and cubed',
    '2 pcs kamatis, seeds removed',
    '1 stalk malunggay leaves',
    '1 bundle alugbati leaves',
    '1 sml pc ginger, peeled and sliced thinly',
    '1 pc red onions, peeled and sliced thinly',
    '2 stalks leeks, sliced',
    '2 pcs tanglad, white ends only, pounded',
    '4-5 pcs okra, medium-sized, cut in half'
  ],
  ARRAY[
    'Boil water and Knorr Shrimp Cube in a pot.',
    'Add gabi, ginger, tomatoes, onions and bundled tanglad. Allow to boil then reduce heat to a simmer. Cook for 3 minutes.',
    'Add kalabasa and okra and let cook until gabi and kalabasa are tender.',
    'Add and cook alugbati, malunggay and leeks for another 1 min. Remove from heat.'
  ],
  'Shellfish (from Knorr Shrimp Cube)',
  ARRAY['Balance Diet', 'Dairy Free', 'Flexitarian', 'Pescatarian'],
  40.0
),

-- 16. Sinigang
(
  'Sinigang',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sinigang.jpeg',
  'Sinigang is a sour soup native to the Philippines. This recipe uses pork as the main ingredient. Other proteins and seafood can also be used.',
  ARRAY[
    '1 lbs. pork belly see notes',
    '0.5 lb. young tamarind see notes',
    '0.5 bunch water spinach chopped',
    '4 pieces string beans cut into 2-inch pieces',
    '1 pieces eggplants sliced',
    '0.5 piece daikon radish see notes',
    '4 pieces okras',
    '1 pieces tomatoes sliced into wedges',
    '1 pieces long green pepper',
    '0.5 piece onion sliced into wedges',
    '32 ounces water',
    'Fish sauce and ground black pepper to taste'
  ],
  ARRAY[
    'Boil the young tamarind in 2 quarts of water for 40 minutes. Filter the tamarind broth using a kitchen sieve or a strainer. Squeeze the tamarind afterwards to extract its remaining juices.',
    'Pour the tamarind broth into a cooking pot. Let it boil and then add the onion, pork belly, and half the amount of the tomatoes.',
    'Skim-off the floating scums, pour 1 tablespoon fish sauce, cover and continue to simmer for 1 hour.',
    'Add daikon radish and eggplants. Cook for 5 minutes.',
    'Add the long green pepper, string beans, remaining tomatoes, and okra. Cook for 3 minutes.',
    'Add the chopped water spinach stalks and season with fish sauce and ground black pepper. Cook for 2 minutes.',
    'Put the water spinach leaves. Cover and turn the heat off. Let the residual heat cook the leaves for 3 minutes before serving.',
    'Share and enjoy!'
  ],
  'Fish (fish sauce)',
  ARRAY['Balance Diet', 'Flexitarian'],
  70.0
);
