-- Insert Filipino Recipes into Supabase
-- This SQL statement inserts 22 authentic Filipino recipes with proper diet classifications and allergy warnings

INSERT INTO recipes (title, image_url, short_description, ingredients, instructions, allergy_warning, diet_types, cost) VALUES

-- 1. Paklay
(
  'Paklay',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/paklay.png',
  'Paklay is a Filipino dish made from various animal innards including pig liver, kidney, heart, ox tripe, and pig stomach. It is orange in color and looks like Kare-Kare without the vegetables and thick pork fat. The mixture of pig and cow innards creates a satisfying dish that can be eaten without rice or as pulutan in drinking sessions.',
  ARRAY[
    '1 cup julienned Bamboo shoots',
    '1 lb. pig liver, sliced into thin strips',
    '1 (20 oz.) can Pineapple chunks, drained',
    '5 pieces dried bay leaves',
    '½ lb. pig kidney, cleaned',
    '½ lb. pig heart',
    '1 lb. ox tripe',
    '½ lb. pig stomach',
    '1 large red onion, minced',
    '1 head garlic, minced',
    '2½ teaspoons Annatto powder',
    '2 thumbs ginger, minced',
    '1 large red bell pepper, julienned',
    '1 piece beef cube (or 2 teaspoons beef powder)',
    '2 cups water (for cooking)',
    '5 cups water (for boiling)',
    'Salt and pepper to taste',
    '3 tablespoons olive oil'
  ],
  ARRAY[
    'Boil 6 cups of water in a pot.',
    'Once water is boiling, add 1 tbsp. salt, pig stomach, and ox tripe.',
    'Boil over a medium heat for 1 hr.',
    'Add the kidney and heart.',
    'Continue to boil for another 1 hr or until all the innards are tender.',
    'Discard the water and let the innards cool down.',
    'Chop the innards and set aside.',
    'Meanwhile, heat the cooking oil in a large clean cooking pot.',
    'Sauté the onion, garlic, and ginger.',
    'Once the onion gets soft, add the chopped innards, bay leaves, and liver.',
    'Cook for 3 minutes.',
    'Add the pineapple chunks, bell pepper, and beef cube.',
    'Pour in 2 cups of water and add the annatto powder. Stir and let boil.',
    'Add the bamboo shoots. Cover and simmer for 25 minutes.',
    'Add more water if needed.',
    'Add salt and pepper to taste.',
    'Transfer to a serving bowl.',
    'Serve while hot.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  120.0
),

-- 2. Bopis
(
  'Bopis',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/bopis.png',
  'Bopis is a spicy Filipino dish made from minced pigs lungs and heart. This can be served as an appetizer for beer and alcoholic beverages; it is also considered as a main dish and is best served with steamed white rice.',
  ARRAY[
    '0.75 lbs pork lungs',
    '0.25 Knorr Pork Cube',
    '1.25 dried bay leaves',
    '0.5 carrots diced',
    '0.75 thumbs ginger minced',
    '0.25 tablespoon annatto powder',
    '0.75 Thai chili pepper chopped',
    '0.25 onion diced',
    '1.25 cloves garlic minced',
    '1.25 tablespoons vinegar',
    '0.63 cups water',
    '0.06 teaspoon ground black pepper',
    '1 tablespoons cooking oil',
    'Fish sauce to taste',
    '2 cups water boiling ingredients',
    '1.25 dried bay leaves boiling ingredients',
    '6.25 g sibot boiling ingredients'
  ],
  ARRAY[
    'In a large pot, boil 8 cups of water and then add the rest of the boiling ingredients. Put the pig''s lungs into the pot and continue boiling for 1 hours. Remove the lungs, let it cool down, and then dice into small pieces. Set aside.',
    'Heat oil on a clean pot. Sauté garlic, onion, and ginger.',
    'Add the diced lungs once the onion softens. Cook for 3 minutes while stirring.',
    'Add vinegar. Cook for 2 minutes.',
    'Pour 2 ½ cups of water into the pot. Let it boil.',
    'Add Knorr Pork cube and bay leaves. Stir. Cover the pot and adjust the heat between low to medium setting. Continue cooking until the liquid reduces to half.',
    'Add the carrot, chili pepper, and annatto powder. Cook for 3 minutes.',
    'Season with ground black pepper and fish sauce.',
    'Transfer to a serving plate and enjoy!'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  95.0
),

-- 3. Tapsilog
(
  'Tapsilog',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/tapsilog.png',
  'Tapsilog is one of my favorite breakfast meal options during big days. These are days wherein I need to complete several tasks. Having this meal gives me the needed energy to perform work and it keeps me full longer.',
  ARRAY[
    '0.33 lb. beef sirloin sliced thinly',
    '1 pieces eggs',
    '2 tablespoons cooking oil',
    '1 tablespoons Knorr Liquid Seasoning Tapa marinade',
    '2 cloves crushed garlic',
    '0.25 cups pineapple juice',
    '0.67 tablespoons brown sugar',
    '0.08 teaspoon ground white pepper',
    '1.67 cups leftover rice Sinangag',
    '0.33 teaspoon salt',
    '1.67 cloves garlic crushed'
  ],
  ARRAY[
    'Prepare the tapa by placing the beef in a large bowl. Combine with all the tapa marinade ingredients. Mix well and cover the bowl. Place inside the fridge and marinate overnight.',
    'Cook the garlic fried rice (sinangag na kanin) by heating 3 tablespoons cooking oil in a pan. Add crushed garlic. Cook until garlic turns light brown. Add the leftover rice. Stir-fry for 3 minutes.',
    'Season with salt. Continue to stir-fry for 3 to 5 minutes. Set aside.',
    'Start to cook the tapa. Heat a pan and pour the marinated beef into it, including the marinade. Add ¾ cups water. Let the mixture boil. Cover the pan and continue to cook until the liquid reduces to half. Add 3 tablespoons cooking oil into the mixture. Continue to cook until the liquid completely evaporates. Fry the beef tapa in remaining oil until medium brown. Set aside.',
    'Fry the egg by pouring 1 tablespoon oil on a pan. Crack a piece of egg and sprinkle enough salt on top. Cook for 30 seconds. Pour 2 tablespoons water on the side of the pan. Cover and let the water boil. Continue to cook until the egg yolks gets completely cooked by the steam.',
    'Arrange the beef tapa, sinangag, and fried egg on a large plate to form Tapsilog. Serve with vinegar as dipping sauce for tapa.'
  ],
  'Eggs, Soy',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  110.0
),

-- 4. Longsilog
(
  'Longsilog',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/longsilog.jpg',
  'Longsilog is a breakfast that consists of sweet pork (longanisa), savory eggs, and umami garlic rice! Without even laying eyes on it, longsilog''s smell wafting through your home is enough to drag even the sleepiest out of bed. Its tantalizing aroma and humble yet comforting appearance, however, aren''t what make this dish special. In fact, it''s longsilog''s simple yet flavorful taste that is the star of the show!',
  ARRAY[
    '0.25 lb. skinless longanisa',
    '1 pieces eggs',
    '2 cups rice leftover',
    '2.5 cloves garlic crushed',
    '0.25 cup water',
    '2 tablespoons cooking oil',
    'Salt and ground black pepper to taste'
  ],
  ARRAY[
    'Heat 2 tablespoons of oil in a pan. Once the oil gets hot, fry the eggs. Remove from the pan. Set aside.',
    'Add remaining oil in the pan. Fry the longanisa until the outer part turns light brown (around 1 1/2 minutes).',
    'Pour-in water. Let boil. Continue boiling until the water evaporates. Fry the longanisa in remaining oil until fully cooked. Remove from the pan and set aside.',
    'Using the remaining oil, cook garlic until it starts to turn light brown.',
    'Add rice. Stir-fry for 3 minutes. Season with salt and ground black pepper.',
    'Assemble the fried eggs, longanisa, and sinangag on a plate. Serve with spicy vinegar as a dipping sauce for the longanisa.',
    'Share and enjoy!'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  85.0
),

-- 5. Pancit Canton
(
  'Pancit Canton',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/pancit_canton.png',
  'Pancit Canton is a type of Lo Mein or tossed noodles known as flour sticks. This dish is often served during birthdays and special occasions to symbolize long life. It is prepared using a variety of ingredients, which makes it look festive.',
  ARRAY[
    '125 grams flour stick noodles',
    '2 ounces pork thinly sliced',
    '0.5 piece Chinese sausage sliced',
    '0.5 piece onion sliced',
    '0.5 teaspoon garlic minced',
    '4 to 5 pieces shrimp shell removed',
    '5 to 6 pieces snap peas',
    '0.38 cup carrot julienne',
    '0.5 piece cabbage small, chopped',
    '0.75 cups chicken broth',
    '0.5 tablespoon oyster sauce opional',
    '1.5 tablespoons soy sauce',
    '0.38 cup water',
    '0.25 cup flat leaf parsley chopped',
    '1.5 tablespoons cooking oil',
    'Salt and pepper to taste'
  ],
  ARRAY[
    'Place 2 cups of ice and 3 cups water in a large bowl. Set aside.',
    'Boil 6 cups of water in a cooking pot.',
    'Once the water starts to boil, blanch the snap peas, carrots, and cabbage for 35 to 50 seconds. Quickly remove the vegetables and immerse in bowl with ice cold water. Drain the water after 2 minutes and set aside.',
    'Heat a large wok or cooking pot and pour-in the cooking oil.',
    'Saute the onion and garlic.',
    'Add the pork and sausage slices and continue to cook for 2 minutes.',
    'Add-in soy sauce and oyster sauce. Stir.',
    'Pour-in chicken broth and water. Add salt and pepper. Let boil. continue to cook for 5 to 10 minutes.',
    'Put-in the shrimp and parsley. Cook for 3 minutes. Add more water if needed.',
    'Put-in the flour noodles. Gently toss until the noodles absorb the liquid.',
    'Add-in the blanched vegetables. Toss and cook for 1 to 2 minutes.',
    'Transfer to a serving plate. Serve.'
  ],
  'Shellfish, Soy, Wheat/Gluten',
  ARRAY['Balance Diet', 'Flexitarian', 'Pescatarian'],
  90.0
),

-- 6. Creamy Chicken Pastel
(
  'Creamy Chicken Pastel',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/creamy_chicken_pastel.png',
  'Chicken pastel, also known as pastel de pollo, is a traditional stew or pie from the Philippines made with chicken, sausages, mushrooms, peas, carrots, potatoes, soy sauce, and various spices in a creamy sauce.',
  ARRAY[
    '1 lbs chicken breast cut into cubes',
    '0.5 piece Knorr Chicken Cube',
    '0.5 piece Chorizo de Bilbao sliced',
    '2 pieces hotdogs sliced',
    '0.5 piece potato cubed',
    '0.5 piece carrot sliced',
    '0.5 piece red bell pepper sliced',
    '0.5 piece green bell pepper sliced',
    '0.38 cup button mushroom sliced',
    '7.5 ounces all-purpose cream',
    '0.13 cup soy sauce',
    '0.5 piece lime',
    '0.5 piece onion chopped',
    '2 cloves garlic minced',
    '0.38 cup water',
    'Salt and ground black pepper to taste'
  ],
  ARRAY[
    'Combine chicken, soy sauce, and lime in a large bowl. Mix well. Marinate chicken for at least 30 minutes.',
    'Heat oil in a cooking pot. Saute onion and garlic.',
    'Once the onion softens, add the chorizo. Saute for 1 minute.',
    'Put chicken into the pot. Saute until the color turns light brown.',
    'Add water. Let boil.',
    'Add Knorr Chicken Cube. Stir. Cover and continue to cook for 20 minutes.',
    'Put the sliced hotdogs into the pot. Cook in medium heat until the liquid reduces to half.',
    'Add potato and carrot. Pour-in all-purpose cream. Cover and cook for 8 minutes.',
    'Stir-in the mushroom and bell peppers. Stir. Cook for 3 minutes.',
    'Season with ground black pepper and salt.',
    'Transfer to a serving plate. Serve with warm rice.'
  ],
  'Dairy, Soy',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  105.0
),

-- 7. Chicken Macaroni Soup (Sopas)
(
  'Chicken Macaroni Soup (Sopas)',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_Macaroni_soup_(Sopas).jpg',
  '"Sopas" as commonly know in the Philippines is a kind of soup with macaroni pasta, vegetables, chicken and milk. The addition of milk is what makes this soup different from other soup. This can also be made vegan but replacing regular milk with non dairy milk and removing the chicken.',
  ARRAY[
    '1/4 cup cooked Macaroni Pasta',
    '1/2 teaspoon Olive Oil',
    '2 cloves Garlic – minced',
    '1/4 cup chopped white or yellow Onion',
    '2 tablespoon chopped Green Onion',
    '1 small size Chicken Breast – shredded or cut int cubes',
    '1/4 cup Carrots – diced',
    '1/2 cup shredded Cabbage',
    '1-2 tsp Chicken Soup Powder (available in spices bulk section in the grocery)',
    '1/4 teaspoon Black Pepper',
    '1/2 cup Milk (Any milk)',
    '3 1/2 cups Broth'
  ],
  ARRAY[
    'Cook the Macaroni Pasta as per package instruction. Set aside while you make the soup.',
    'Make the Soup – On a heated pan, add garlic, onion and green onion. Sauté for 1 minute.',
    'Add shredded chicken, and diced carrots. Cook until chicken is no longer raw.',
    'Add chicken powder, black pepper, chicken or vegetable broth and cooked macaroni pasta. Simmer until vegetables are cook to your liking.',
    'Add milk and shredded cabbage. Taste and adjust seasoning as desired. Cook for 2 more minutes.'
  ],
  'Dairy, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  75.0
),

-- 8. Beef Mechado
(
  'Beef Mechado',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/beef_mechado.png',
  'Beef Mechado is a delicious tomato-based stew that pairs perfectly with a warm cup of rice. It is hearty and filling, and its taste can bring back the comfort of home. The sauce can be made from chopped ripe tomato or canned tomato sauce. This dish is prepared mostly during weekends or special occasions.',
  ARRAY[
    '0.67 lbs beef chuck cubed',
    '1 cloves garlic crushed',
    '0.33 piece large onion sliced',
    '2.67 ounces tomato sauce',
    '0.33 cup water',
    '1 tbsp cooking oil',
    '0.33 slice lemon with rind',
    '0.33 piece large potato sliced',
    '0.08 cup soy sauce',
    '0.17 tsp. ground black pepper',
    '0.67 pieces bay leaves laurel',
    'Salt to taste'
  ],
  ARRAY[
    'Heat cooking oil in a pan then saute the garlic and onion.',
    'Put-in the beef and saute for about 3 minutes or until color turns light brown',
    'Add the tomato sauce and water then simmer until the meat is tender. Add water as needed. Note this can take 60 to 120 minutes depending on the quality of the beef.',
    'Add the soy sauce, ground black pepper, lemon rind, laurel leaves, and salt then simmer until excess liquid evaporates',
    'Put-in the potatoes and cook until the potatoes are soft',
    'Place in a serving plate then serve hot with rice.'
  ],
  'Soy',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  100.0
),

-- 9. Hotsilog (Hotdog Sinangang at Itlog)
(
  'Hotsilog (Hotdog Sinangang at Itlog)',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/hotsilog_(hotdog_%20sinangang_at_%20Itlog).png',
  'Hotsilog is a meal composed of hotdogs, garlic fried rice, and fried egg. In a Filipino household, this is commonly eaten for breakfast with a condiment of banana ketchup and some pickled shredded papaya (atchara) on the side. Red juicy hotdogs are used to make hotsilog.',
  ARRAY[
    '3 pieces red hotdogs',
    '2 eggs',
    '1 cup garlic fried rice',
    '1 medium tomato sliced',
    '3/4 cup water',
    '6 tablespoons cooking oil'
  ],
  ARRAY[
    'Pour water in a small cooking pot. Let boil.',
    'Add hotdogs and then pour 2 tablespoons cooking oil. Continue to cook until the water evaporates.',
    'Once the water is gone, fry the hotdogs in the remaining oil for 1 to 2 minutes while slowly rolling it back and forth to prevent it from getting burnt. Set aside.',
    'Prepare the eggs by heating 4 tablespoons of cooking oil in a pan.',
    'Once the oil gets hot, crack a piece of egg and start to fry it. As the egg is frying, grab a spoon and scoop the oil from the bottom of the pot. Pour the oil over the egg. Do this until the yolk gets a white covering. Remove the egg and set aside. Do the same step on the other piece of egg.',
    'Arrange the garlic fried rice, hotdogs, and fried eggs in a plate. Put the slices of tomato on the side.',
    'Serve with ketchup.'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  70.0
),

-- 10. Sinigang na Sardinas
(
  'Sinigang na Sardinas',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sinigang_na_sardinas.png',
  'Sinigang na Sardinas is a budget-friendly soup built on sharp tamarind tang and the soft bite of canned sardines or mackerel. It''s loaded with vegetables and easy to cook, especially for weeknight meals.',
  ARRAY[
    '7.5 oz mackerel canned',
    '12.5 grams Maggi Magic Sinigang with Gabi',
    '2 pieces okra',
    '2.5 pieces string beans',
    '1 ounces daikon radish',
    '0.5 pieces eggplant',
    '0.67 pieces long green peppers',
    '0.17 bunch water spinach',
    '0.33 pieces onions',
    '1.33 cloves garlic',
    '0.67 thumbs ginger crushed',
    '0.83 pieces tomatoes',
    '0.04 cup miso paste',
    '0.33 quarts water',
    'Fish sauce and ground black pepper to taste',
    '0.5 tablespoons cooking oil'
  ],
  ARRAY[
    'Separate the mackerel from the oil using a kitchen strainer. Set both aside.',
    'Heat cooking oil and then sauté the onions until the layers separate.',
    'Add ginger and garlic. Continue to sauté until the garlic starts to brown.',
    'Add the tomatoes. Sauté for 1 minute.',
    'Pour the oil from the canned mackerel into the cooking pot. Add 1 tablespoon of fish sauce and ½ teaspoon of ground black pepper. Stir.',
    'Add miso paste and pour 1 ½ quarts of water. Let it boil.',
    'Add the daikon radish. Continue cooking in medium heat setting for 5 minutes.',
    'Add Maggi Magic Sinigang with Gabi. Stir.',
    'Add the eggplant. Boil for 2 minutes.',
    'Add the okra, long green peppers, and string beans.',
    'Pour the remaining water, cover the pot, and let it re-boil. Continue cooking for 2 minutes.',
    'Put the mackerel into the pot. Gently stir.',
    'Add the water spinach (kangkong). Cook for 2 to 3 minutes.',
    'Season with more fish sauce and ground black pepper as needed.',
    'Transfer to a serving bowl. Serve hot.'
  ],
  'Fish',
  ARRAY['Balance Diet', 'High Protein', 'Pescatarian', 'Dairy-Free'],
  65.0
),

-- 11. Kalderetang Kambing (Goat Stew)
(
  'Kalderetang Kambing (Goat Stew)',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/kalderetang_kambing_(Goat%20Stew).png',
  'When you pair the unique flavors of liver with vinegar, tomato sauce, onions and carrots, you get the ever so lovely taste of Kaldereta. This orange stew is a Filipino recipe that locals truly love for its rich texture and powerful savory taste.',
  ARRAY[
    '0.5 lb goat meat chevon, cubed',
    '0.5 tablespoon garlic minced',
    '0.5 onion minced',
    '1.5 tomatoes diced',
    '2 Thai chili optional',
    '0.5 cup tomato sauce',
    '0.38 cup bell pepper sliced',
    '3 tablespoon liver spread',
    '0.38 cup green olives optional',
    '0.25 cup vinegar',
    '0.5 carrot cubed',
    '0.5 potato cubed',
    '1.5 tablespoons cooking oil',
    '1 cups water',
    'Salt and pepper to taste'
  ],
  ARRAY[
    'Combine the vinegar, salt, and ground black pepper in a large bowl then marinate the goat meat for at least an hour (This should eliminate the gamey smell and taste of the meat) then separate the meat from the marinade.',
    'Pour the cooking oil in a cooking pot or casserole and apply heat.',
    'Sauté the garlic, onion, and tomatoes',
    'Add the marinated goat meat then cook until the color of the outer part turns light brown',
    'Put-in the tomato sauce and crushed chili then allow to cook for 2 minutes',
    'Add the water and allow to boil. Simmer for at least 45 minutes or until the meat is tender.',
    'Add the liver spread and cook for 5 minutes (You may add water if the sauce seems to dry up)',
    'Put-in the potatoes and carrots then simmer for 8 minutes.',
    'Add the olives and bell pepper then simmer for another 5 minutes.',
    'Add salt and pepper to taste.',
    'Serve hot.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  130.0
),

-- 12. Pork Giniling
(
  'Pork Giniling',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/pork_giniling.png',
  'Pork Giniling is a pork dish that makes use of ground pork as the primary ingredient. Ground pork is stewed in tomato sauce and water to bring out the taste while vegetables such as carrots and potatoes (some also like this with raisins and green peas) are added for additional flavor and nutrition.',
  ARRAY[
    '0.5 lb ground pork',
    '0.5 cups potatoes diced',
    '0.33 cup carrots diced',
    '2.67 ounces tomato sauce',
    '2 cloves garlic crushed',
    '0.33 medium-sized onion minced',
    '0.33 teaspoon granulated sugar',
    '0.33 piece beef or pork cube',
    '1.33 boiled eggs shelled (optional)',
    'Salt and pepper to taste',
    '1 tablespoons cooking oil',
    '0.33 cup water'
  ],
  ARRAY[
    'Heat a cooking pot and pour-in the cooking oil.',
    'When the oil is hot enough, put-in the garlic and sauté until the color turns light brown.',
    'Add the onions and sauté until the texture becomes soft.',
    'Put-in the ground pork and cook for 5 minutes.',
    'Add the beef or pork cube, tomato sauce, and water and let boil. Simmer for 20 minutes.',
    'Put the carrots and potatoes in then stir until every ingredient is properly distributed. Simmer for 10 to 12 minutes.',
    'Add salt, ground black pepper, and sugar then stir.',
    'Put in the boiled eggs and turn off the heat.',
    'Transfer to a serving bowl and serve.'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  80.0
),

-- 13. Pininyahang Manok (Pineapple Chicken)
(
  'Pininyahang Manok (Pineapple Chicken)',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/pininyahang_%20manok_(Pineapple%20Chicken).jpeg',
  'Pininyahang manok, commonly anglicized as pineapple chicken, is a Philippine dish consisting of chicken braised in a milk or coconut milk-based sauce with pineapples, carrots, potatoes, and bell peppers. Some variants of the dish use a chicken stock base instead of milk.',
  ARRAY[
    '151.2 g chicken cut into serving pieces',
    '56.7 g pineapple chunks canned',
    '0.33 pieces tomato chopped',
    '24.83 g bell pepper cut into thick strips',
    '0.17 piece carrot wedged',
    '0.42 tablespoon fish sauce patis',
    '20.33 g fresh milk',
    '0.33 tablespoon garlic minced',
    '0.17 piece onion sliced',
    '0.33 tablespoon cooking oil'
  ],
  ARRAY[
    'Marinate the chicken in pineapple juice/concentrate (derived from the can of pineapple chunks) for 20 to 30 minutes',
    'Pour the cooking oil in a cooking pot / casserole then apply heat',
    'Sauté the garlic, onion, and tomatoes',
    'Put-in the chicken and cook until color of the outer part turns light brown',
    'Add the pineapple juice/concentrate marinade and fresh milk then bring to a boil',
    'Add the pineapple chunks and simmer until the chicken is tender and half of the liquid evaporates (about 20 to 30 minutes).',
    'Put-in the carrots and simmer for 5 minutes',
    'Add the bell pepper and fish sauce then simmer for 3 minutes',
    'Remove from the cooking pot / casserole and transfer to a serving dish.',
    'Serve hot.'
  ],
  'Dairy',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  95.0
),

-- 14. Pancit Palabok
(
  'Pancit Palabok',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/pancit_palabok.jpg',
  'Pancit Palabok is a noodle dish with shrimp sauce and topped with several ingredients such as cooked shrimp, boiled pork, crushed chicharon, tinapa flakes, fried tofu, scallions, and fried garlic. A very tasty treat that is sure to relieve your hunger. If you love Jollibee''s Palabok, I''m sure that you will love this recipe even more.',
  ARRAY[
    '83.33 grams rice noodles bihon',
    '0.33 tbsp cooking oil Sauce ingredients',
    '37.8 g ground pork Sauce ingredients',
    '0.17 tbsp anatto powder Sauce ingredients',
    '117.5 g pork broth Sauce ingredients',
    '0.17 piece shrimp bouillon Sauce ingredients',
    '1 tablespoons all-purpose flour Sauce ingredients',
    '0.33 tbsp fish sauce Sauce ingredients',
    '0.08 tsp ground black pepper Sauce ingredients',
    '22.5 g pork belly boiled and sliced thinly into small pieces Topping ingredients',
    '18.9 g firm tofu fried and sliced into cubes Topping ingredients',
    '7.5 g tinapa flakes smoked fish Topping ingredients',
    '19.71 g chicharon pounded Topping ingredients',
    '0.33 hard boiled eggs sliced Topping ingredients',
    '19.71 g cooked shrimps boiled or steamed Topping ingredients',
    '4.17 g green onion or scallions finely chopped Topping ingredients',
    '0.5 Tablespoons toasted garlic Topping ingredients',
    '0.33 lemons sliced (or 6 pieces calamansi) Topping ingredients'
  ],
  ARRAY[
    'Soak the rice noodles in water for about 15 minutes. Drain and set aside.',
    'Cook the sauce by heating a saucepan. Pour-in the cooking oil.',
    'When the oil is hot enough, put-in the ground pork and cook for about 5 to 7 minutes',
    'Dilute the annato powder in pork broth then pour the mixture in the saucepan. Bring to a boil (If you are using anatto seeds, soak them first in 3 tbsp water to bring-out the color)',
    'Add the shrimp cube and stir and simmer for 3 minutes',
    'Add the flour gradually while stirring.',
    'Add the fish sauce and ground black pepper then simmer until sauce becomes thick. Set aside.',
    'Meanwhile, boil enough water in a pot.',
    'Place the soaked noodles in a strainer (use metal or bamboo strainer) then submerge the strainer in the boiling water for about a minute or until the noodles are cooked. (make sure that the noodles are still firm)',
    'Remove the strainer from the pot and drain the liquid from the noodles.',
    'Place the noodles in the serving plate.',
    'Pour the sauce on top of the noodles then arrange the toppings over the sauce.',
    'Serve with a slice of lemon or calamansi.'
  ],
  'Shellfish, Fish, Eggs',
  ARRAY['Balance Diet', 'Flexitarian', 'Pescatarian'],
  85.0
),

-- 15. Adobong Manok sa Gata
(
  'Adobong Manok sa Gata',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/adobong_manok_sa_gata.jpeg',
  'Adobong Manok sa Gata is a version of Filipino Chicken Adobo that includes coconut milk. It is simply cooked similar to regular adobo, except that coconut milk is added in the middle of the process. The additional ingredient makes this dish different from traditional adobo.',
  ARRAY[
    '170.1 g chicken cut into serving pieces',
    '113 g coconut milk',
    '0.25 piece Knorr Chicken Cube',
    '31.88 g white vinegar',
    '14.5 g soy sauce',
    '1.5 cloves garlic',
    '1.25 pieces bay leaves dried',
    '0.5 teaspoons whole peppercorn',
    '0.75 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat oil in a pan.',
    'Crush the garlic, and then saute until it starts to brown.',
    'Fry the chicken for 1 to 1 ½ minutes per side.',
    'Pour soy sauce and vinegar. Cover the pan. Let boil. Flip the chicken pieces afterwards. Continue cooking for 5 minutes.',
    'Add whole peppercorn and bay leaves. Pour coconut milk. Stir and then let the mixture boil.',
    'Add Knorr Chicken Cube. Stir and cover the pan. Adjust heat to low. Cook for 20 minutes.',
    'Remove the cover and continue to cook until sauce reduces to desired amount.',
    'Serve with warm rice.'
  ],
  'Soy',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian', 'Dairy-Free'],
  90.0
),

-- 16. Inihaw na Bangus (Grilled Milkfish)
(
  'Inihaw na Bangus (Grilled Milkfish)',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/inihaw_na_bangus_(Grilled%20MilkFish).jpeg',
  'Inihaw na Bangus or grilled milkfish is a perfect dish to make during warm weather. I like it best when grilled over charcoal because it gives the fish a nice smoky flavor. This recipe will give you a simple yet delicious dish that is quick and easy to make.',
  ARRAY[
    '0.5 piece milkfish bangus, with scales but guts removed',
    '0.5 piece tomato ripe, diced',
    '0.5 piece red onion diced',
    '0.5 piece lemon or 3 pieces calamansi (optional)',
    '0.5 tablespoon ginger minced',
    '1 teaspoons salt',
    '0.25 teaspoon ground black pepper'
  ],
  ARRAY[
    'Wash the fish first. After that, pat it dry using a paper towel.',
    'Open the incision and then rub the salt on the inside of the dish. The fish should have an incision either above or below the belly area.',
    'Meanwhile, combine tomato, onion, and ginger in a large bowl. Squeeze some lemon juice in and add the ground black pepper. Gently stir.',
    'Stuff the mixture inside the milkfish.',
    'Grill the fish in medium heat for about 10 to 12 minutes per side.',
    'Serve with toyomansi and steamed rice.'
  ],
  'Fish',
  ARRAY['Balance Diet', 'High Protein', 'Pescatarian', 'Dairy-Free', 'Gluten-Free'],
  110.0
),

-- 17. Bistek Tagalog (Beef Steak)
(
  'Bistek Tagalog (Beef Steak)',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/bistek_tagalog(Beef%20Steak).jpeg',
  'Bistek Tagalog is a type of Filipino beef stew. This is also known as beef steak to some people. It is comprised of thin slices of beef and a generous amount of onions. These are stewed in a soy sauce and lemon juice mixture until the beef gets very tender. It is best enjoyed with warm rice.',
  ARRAY[
    '136.08 g beef sirloin thinly sliced',
    '1 tablespoons soy sauce',
    '0.8 pieces calamansi or 1-piece lemon',
    '0.1 tsp ground black pepper',
    '0.6 cloves garlic minced',
    '0.6 pieces onion sliced into rings',
    '0.8 tablespoons cooking oil',
    '50 g water',
    '0.2 pinch salt'
  ],
  ARRAY[
    'Marinate beef in soy sauce, lemon (or calamansi), and ground black pepper for at least 1 hour. Note: marinate overnight for best result',
    'Heat the cooking oil in a pan then pan-fry half of the onions until the texture becomes soft. Set aside',
    'Drain the marinade from the beef. Set it aside. Pan-fry the beef on the same pan where the onions were fried for 1 minute per side. Remove from the pan. Set aside',
    'Add more oil if needed. Saute garlic and remaining raw onions until onion softens.',
    'Pour the remaining marinade and water. Bring to a boil.',
    'Add beef. Cover the pan and simmer until meat is tender. Note: Add water as needed.',
    'Season with ground black pepper and salt as needed. Top with pan-fried onions.',
    'Transfer to a serving plate. Serve hot.'
  ],
  'Soy',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian', 'Dairy-Free', 'Gluten-Free'],
  125.0
),

-- 18. Binagoongan
(
  'Binagoongan',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/binagoongan.jpeg',
  'Pork in shrimp paste is the best translation for this recipe. Tenderized pork is cooked in shrimp paste to enrich the flavor then garnished with chili to add some kick. This is considered as Filipino a main dish and is often eaten with lots of rice.',
  ARRAY[
    '170.1 g pork belly cut into cubes',
    '0.5 pieces tomato cubed',
    '0.25 piece Chinese eggplant sliced',
    '210 g pork stock',
    '0.75 tablespoons white vinegar',
    '1 tablespoons bagoong alamang',
    '0.25 piece onion chopped',
    '0.75 cloves garlic chopped',
    '0.5 teaspoons granulated white sugar',
    '0.03 teaspoon ground black pepper',
    '0.75 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat oil in a cooking pot.',
    'Saute onion, garlic, and tomato. Once the onion becomes soft, add the pork belly. Cook until the belly turns light brown.',
    'Add shrimp paste (bagoong alamang). Stir. Cook for 5 minutes.',
    'Pour vinegar. Let the mixture boil. Stir and cook for 2 minutes.',
    'Pour the pork stock into the pot. Cover and let boil. Adjust the heat to medium and continue to cook for 40 minutes or until the pork gets tender. Note: add water or pork stock as needed.',
    'Add eggplant. Stir. Cover the pot and cook for 3 minutes.',
    'Season with sugar and ground black pepper.',
    'Transfer to a serving plate. Serve.'
  ],
  'Shellfish',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian', 'Dairy-Free', 'Gluten-Free'],
  85.0
),

-- 19. Sigarilyas Gising Gising
(
  'Sigarilyas Gising Gising',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sigarilyas_gising_gising.jpg',
  'Sigarilyas Gising gising is a Filipino vegetable stew composed of winged beans, ground pork, and long green chillies.',
  ARRAY[
    '2.5 pieces winged bean sigarilyas, sliced crosswise',
    '0.5 cups coconut milk',
    '0.25 medium red onion sliced',
    '1.25 cloves garlic crushed and chopped',
    '0.13 lb. ground pork',
    '1.5 pieces long green peppers siling pansigang',
    '0.75 tablespoons fish sauce',
    '0.03 teaspoon ground black pepper',
    '0.75 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat the oil in a deep pan.',
    'Once the oil is hot, saute the garlic and onion. Continue to cook until the onion starts to soften.',
    'Add the ground pork. Saute for 5 minutes or until the pork turns brown.',
    'Pour the coconut milk in the pan and let boil. Stir and add the sigarilyas and long green peppers. Cover and adjust the heat to low. cook for 30 to 35 minutes or until the liquid reduces in half.',
    'Remove the cover and add fish sauce and ground black pepper. Stir and cook for a few more minutes until the coconut milk reduces, but do not let the liquid evaporate totally.',
    'Transfer to a serving plate. Serve!'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian', 'Dairy-Free', 'Gluten-Free'],
  70.0
),

-- 20. Chicken Embutido
(
  'Chicken Embutido',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_embutido.jpg',
  'Embutido is a type of Filipino steamed meatloaf. Today, we are featuring Chicken Embutido, which is a meatloaf made from ground chicken.',
  ARRAY[
    '1 lbs. ground chicken',
    '0.33 red bell pepper minced',
    '0.33 green bell pepper minced',
    '0.33 yellow onion minced',
    '1 egg',
    '2.67 oz tomato sauce',
    '0.33 cup raisins',
    '0.33 cup carrots minced',
    '0.25 cups sharp cheddar cheese grated',
    '0.5 cups bread crumbs',
    '0.08 cup olive oil',
    '0.08 cup sweet pickle relish',
    '0.17 teaspoon ground black pepper',
    '0.33 teaspoon salt'
  ],
  ARRAY[
    'In a large mixing bowl, combine the ground chicken, carrots, bell peppers, onion, raisins, sweet relish, cheese, and tomato sauce. Mix well.',
    'Pour-in the olive oil. Add the salt and pepper. Continue to stir until all the ingredients are well blended.',
    'Put the eggs and bread crumbs in the mixing bowl. Continue to mix with the other ingredients.',
    'Wrap the mixture (around 1 to 1 1/4 cup) in aluminum foil. Do this step until all the mixture are consumed.',
    'Arranged the chicken embutido in a steamer. Steam for 45 to 60 minutes.',
    'Remove the steamed embutido from the steamer. Let it cool down. You can also place it in the fridge.',
    'Slice the embutido and arrange in a serving plate.',
    'Serve chilled.'
  ],
  'Eggs, Dairy, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  95.0
),

-- 21. Paksiw na Bangus
(
  'Paksiw na Bangus',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/paksiw_na_bangus.jpg',
  'Bangus Filipino Recipe known as Paksiw na Bangus is a classic dish that highlights the country''s love for bold and tangy flavors. It is made by stewing milkfish, or bangus, in vinegar along with garlic, ginger, onions, and a mix of spices. This bangus Filipino recipe is simple to make and requires just one pot, making it perfect for a quick but satisfying meal. The vinegar serves as the main flavoring, so it gives the dish a tangy punch that is balanced by the warmth of the garlic and ginger.',
  ARRAY[
    '0.58 lbs. milkfish cleaned and sliced crosswise into serving pieces',
    '0.5 ounces pork fat chopped',
    '0.83 thumbs ginger thinly sliced',
    '0.17 head garlic crushed',
    '0.21 cup white vinegar',
    '0.33 cups water',
    '0.33 onions sliced thinly',
    '0.33 Chinese eggplants sliced',
    '0.33 bitter melons sliced',
    '0.83 long green pepper',
    '0.33 teaspoons whole peppercorn',
    'fish sauce to taste'
  ],
  ARRAY[
    'Heat a pan and sear the pork fat until enough oil gets extracted.',
    'Turn off the heat. Arrange the garlic, ginger, onion, and whole peppercorns.',
    'Top with the milkfish slices, long green peppers, eggplant, and bitter melon.',
    'Pour the vinegar. Turn the heat on. Cover the pot, and let it boil. Cook for 2 minutes.',
    'Add water. Let the liquid re-boil. Simmer for 15 minutes.',
    'Season with fish sauce.',
    'Transfer to a serving plate. Serve with rice.'
  ],
  'Fish',
  ARRAY['Balance Diet', 'High Protein', 'Pescatarian', 'Dairy-Free', 'Gluten-Free'],
  75.0
),

-- 22. Inun unan
(
  'Inun unan',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/inun_unan.jpg',
  'Inun unan is a Filipino fish recipe that involves fish and vinegar along with some vegetables and spices Similar to paksiw this Visayan version difference Inun unan is spiced primarily with ginger and only fish can be used, paksiw can be cooked with other meats like pork',
  ARRAY[
    '0.67 lbs. fish tulingan, cleaned and innards removed',
    '0.33 medium ampalaya bitter gourd, cored and sliced',
    '0.33 medium Chinese eggplant sliced',
    '0.33 small onion chopped',
    '0.33 thumb ginger sliced',
    '1.67 pieces long green chili or Serrano pepper',
    '0.17 cup cane or white vinegar',
    '0.33 cup water',
    '0.33 teaspoon whole peppercorn'
  ],
  ARRAY[
    'Arrange the onion, fish, ginger, whole peppercorn, water, and vinegar in a cooking pot. Cover the pot and turn the heat on. Let the liquid boil.',
    'Once the liquid starts to boil, adjust the heat to low. Cook for 15 minutes.',
    'Add the eggplant, bitter gourd, and chili (or pepper). Cover the pot and continue to cook until the water completely evaporates.',
    'Transfer to a serving plate. Serve.'
  ],
  'Fish',
  ARRAY['Balance Diet', 'High Protein', 'Pescatarian', 'Dairy-Free', 'Gluten-Free'],
  60.0
);

