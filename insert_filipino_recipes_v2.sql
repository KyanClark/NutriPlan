-- Insert Filipino Recipes into Supabase
-- This SQL statement inserts 20 authentic Filipino recipes with proper diet classifications and allergy warnings

INSERT INTO recipes (title, image_url, short_description, ingredients, instructions, allergy_warning, diet_types, cost) VALUES

-- 1. Chicken and Corn Soup
(
  'Chicken and Corn Soup',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_and_corn_soup.jpg',
  'Chicken and Corn soup is a simple yet nutritious soup recipe that requires boneless chicken and shredded corn kernels. This is an easy to follow budget friendly recipe that you will surely love.',
  ARRAY[
    '2 cups liquid chicken stock',
    '0.5 can creamed corn (400 grams)',
    '0.75 cups corn kernels (fresh, frozen or canned)',
    '0.5 teaspoon fresh ginger (finely grated)',
    '1 tablespoons light soy sauce (or adjust, to taste)',
    '0.5 tablespoon Shaoxing Chinese cooking wine (or substitute for mirin)',
    '1 teaspoons cornflour (corn starch)',
    '1.5 egg whites (lightly beaten)',
    '1-1.5 cups shredded cooked chicken (or use raw chicken breast, thigh or mince)',
    '0.25 - 0.5 teaspoon sesame oil (or adjust, to taste)',
    'salt and white pepper to taste',
    '1.5 spring onions (shredded)'
  ],
  ARRAY[
    'Mix the cornflour with a little chicken stock (approx. 75 ml) to make a thickening agent.',
    'Heat the oil on a medium heat in a non-stick pan and gently soften the garlic, ginger and spring onions for a couple of minutes.',
    'Add the remaining chicken stock and soy sauce to the pan and bring to the boil.',
    'Take the cornflour and slowly add to the stock, stirring thoroughly to ensure there are no lumps.',
    'Add the chicken and sweetcorn to the soup base bringing it back up to the boil and simmer for 5 minutes.',
    'Remove the soup from the heat and stir in the egg using a fork to make egg strands.',
    'Add the coriander, salt and pepper to taste, and garnish with spring onions.'
  ],
  'Eggs, Soy',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  45
),

-- 2. Adobong Talong
(
  'Adobong Talong',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/adobong_talong.jpg',
  'Enjoy classic adobo flavors with this super easy and tasty Adobong Talong recipe! Eggplant Adobo is easy to make and so flavorful. Pan-fried talong are simmered in a tangy and savory marinade for the ultimate side dish! Delicious with steamed rice!',
  ARRAY[
    '1 tablespoons canola oil',
    '1 medium Filipino eggplant, stems trimmed and cut into 2-inch chunks',
    '1.25 cloves garlic, peeled and minced',
    '0.13 cup vinegar',
    '0.13 cup water',
    '0.06 cup soy sauce',
    '0.5 Thai chili peppers',
    'salt and pepper to taste'
  ],
  ARRAY[
    'In a wide pan over medium heat, heat about 3 tablespoons of the oil. Add eggplant and cook until lightly browned. Remove from pan and drain on paper towels.',
    'In the pan, heat the remaining 1 tablespoon oil. Add garlic and cook, stirring regularly, until lightly browned.',
    'Add vinegar, water, and soy sauce and bring to a boil, uncovered and without stirring, for about 2 to 3 minutes until slightly reduced.',
    'Add eggplant and chili peppers. Cook, covered, for about 4 to 5 minutes or until tender.',
    'Season with salt and pepper to taste. Serve hot.'
  ],
  'Soy',
  ARRAY['Balance Diet', 'Vegan', 'Vegetarian', 'Dairy-Free', 'Gluten-Free', 'Low-Fat', 'Low-Calorie'],
  25
),

-- 3. Ampalaya with Chicken Feet
(
  'Ampalaya with Chicken Feet',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ampalaya_with_chicken_feet.jpg',
  'Ampalaya with Chicken Feet is a delicious dish that pairs perfectly with steamed rice. It''s a budget-friendly and nutritious meal you''ll feel good serving the whole family.',
  ARRAY[
    '0.5 pounds chicken feet',
    'water',
    '1 slices ginger',
    '0.5 stalks green onions, tied into a knot',
    'oil',
    '0.25 onion, peeled and chopped',
    '0.75 cloves garlic, peeled and minced',
    '0.25 thumb-sized ginger, peeled and julienned',
    '0.5 tablespoons fish sauce',
    '0.75 medium ampalaya',
    '0.25 teaspoon sugar',
    'salt and pepper to taste'
  ],
  ARRAY[
    'Trim chicken feet of nails and any dark, callused areas. Scrub with rock salt, rinse, and drain well.',
    'In a pot over medium heat, combine chicken feet, enough water to cover, ginger slices, and green onions knot. Boil for about 7 to 10 minutes, skimming scum that floats on top. Drain well and pat dry with paper towels.',
    'Heat about 3-inches deep of oil in a deep pot or wok. Carefully add chicken feet and fry until lightly golden, stirring regularly for even cooking.',
    'Remove chicken feet and soak in a bowl of ice water for about 1 hour or until skin is wrinkled. Drain well and pat dry with paper towels.',
    'In a wide pan, heat oil. Add onions, garlic, and julienned ginger and cook, stirring regularly, until softened.',
    'Add chicken feet. Add fish sauce and continue to cook for 1 to 2 minutes.',
    'Add about 1 cup water and bring to a boil skimming any scum that may float on the top. Lower heat, cover, and cook for about 50 minutes to 1 hour or until chicken feet are very tender. Add additional water in ½ cup increments as needed to maintain about 1 cup broth.',
    'Meanwhile, cut ampalaya lengthwise and scrape off seeds and white pith. Slice thinly and place in a bowl, covered in cold water until needed.',
    'Add ampalaya and gently stir to combine. Cook for about 3 to 5 minutes or until tender yet crisp.',
    'Add sugar. Season with salt and pepper to taste. Serve hot.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  35
),

-- 4. Honey Bagoong Chicken Wings
(
  'Honey Bagoong Chicken Wings',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/honey_bagoong_chicken_wings.jpg',
  'These honey bagoong chicken wings are a culinary adventure you shouldn''t miss. They''re super easy to make and a delicious blend of sweet and savory flavors that are like a party in your mouth!',
  ARRAY[
    '0.75 pounds chicken wings, cut into flats and drummettes',
    '0.13 cup sauteed shrimp paste',
    '0.06 cup honey',
    'salt and pepper to taste'
  ],
  ARRAY[
    'Rinse chicken wings in cold water and drain well. Pat dry. Season with salt and pepper.',
    'In a large bowl, combine bagoong and honey until blended. Add chicken and massage with mixture. Marinate for at least 4 hours for best flavor.',
    'Preheat oven to 375 F. Line a baking sheet with foil and spray it with non-stick cooking spray.',
    'Drain chicken from marinade. Reserve marinade.',
    'In a small sauce pan over medium heat, heat honey-bagoong marinade for about 5 to 10 minutes or until thick and syrupy.',
    'Arrange chicken in a single layer on prepared baking sheet. Bake in the oven for about 30 to 35 minutes or until chicken is cooked through and skin is caramelized. Halfway through cooking, turn and baste chicken with marinade.'
  ],
  'Shellfish',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  65
),

-- 5. Beef Potato and Pechay Soup
(
  'Beef Potato and Pechay Soup',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/beef_potato_pechay_soup.jpg',
  'Beef Potato and Pechay Soup is the ultimate comfort food inspired by the beloved Filipino Picadillo Soup. This soup will warm you up with tender beef ribs, hearty potatoes, nutritious pechay, and a rich and flavorful tomato-beef broth.',
  ARRAY[
    '0.25 tablespoon oil',
    '0.25 onion, peeled and chopped',
    '0.75 cloves garlic, peeled and minced',
    '0.5 pounds beef short ribs',
    '1.25 ripe Roma tomatoes, chopped',
    '0.25 tablespoon fish sauce',
    '1.25 cups water',
    '0.5 medium potatoes, peeled and diced',
    '0.25 bunch pechay, chopped',
    'salt and pepper to taste'
  ],
  ARRAY[
    'Rinse beef ribs and drain well.',
    'In a large pot over medium heat, heat oil. Add onions and garlic and cook until softened.',
    'Add beef spare ribs and cook, stirring occasionally, until lightly browned.',
    'Add tomatoes and cook, mashing with the back of spoon, until softened and release juice.',
    'Add fish sauce and continue to cook for about 1 to 2 minutes.',
    'Add water and bring to a boil, skimming scum that floats on top. Lower heat, cover, and cook for about 50 to 60 minutes or until meat is fork-tender. Add more water in ½ cup increments as needed to maintain about 5 cups.',
    'Add potatoes and cook for about 7 to 10 minutes or until tender.',
    'Add pechay and cook for about 2 to 3 minutes or until tender yet crisp.',
    'Season with salt and pepper to taste. Serve hot.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  70
),

-- 6. Picadillo Soup
(
  'Picadillo Soup',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/picadillo_soup.jpg',
  'Picadillo Soup with tender beef and chayote in a flavorful tomato broth is delicious on its own or with steamed rice. Hearty and tasty, it''s the ultimate comfort food! There are two forms of Picadillo in the Filipino cuisine. One is a dry stew version, also known as giniling, traditionally made of ground or minced beef, potatoes, carrots, and green peas cooked in tomato sauce. The other is this soup version, usually made of ground or diced beef and potatoes or chayote cooked in a tomato-based broth.',
  ARRAY[
    '0.25 tablespoon canola oil',
    '0.25 small onion, peeled and chopped',
    '0.5 cloves garlic, peeled and minced',
    '0.5 pounds chuck roast, cut into 1 inch cubes',
    '0.25 tablespoon fish sauce',
    '0.5 large tomatoes, chopped',
    '0.75 cups water',
    '0.5 pieces chayote, peeled and cut into 1-inch cubes',
    'salt and pepper to taste'
  ],
  ARRAY[
    'Cut the ingredients into uniform sizes to ensure even cooking.',
    'In a pot over medium heat, heat oil. Add onions and garlic and cook until softened.',
    'Add beef and cook, stirring occasionally, until no longer pink.',
    'Add fish sauce and continue to cook for about 1 to 2 minutes.',
    'Add tomatoes and cook until softened and begins to release juice.',
    'Add water and bring to a boil. Lower heat, cover and cook for about 1 to 1 ½ hours or until tender.',
    'Add chayote and cook for about 7 to 10 minutes or until tender.',
    'Season with salt and pepper to taste. Serve hot.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  60
),

-- 7. La Paz Batchoy
(
  'La Paz Batchoy',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/la_paz_batchoy.jpg',
  'Nothing beats a comforting bowl of hot La Paz Batchoy, especially on a cold rainy day. It''s loaded with fresh egg noodles, flavorful broth, pork meat, chicharon, and raw egg for a hearty and tasty soup to warm you up! It''s hearty and tasty with fresh egg noodles, a rich, flavorful broth, pork meat, chicharron, and raw egg. Delicious as a filling snack or main meal!',
  ARRAY[
    '0.38 pounds pork bones',
    '0.25 pounds beef bones, with marrow',
    'water',
    '0.06 pound pork shoulder',
    '0.06 pound pork intestines, cleaned',
    '0.06 pound pork liver',
    '0.13 red onion, peeled and minced',
    '0.25 cloves garlic, peeled and minced',
    '0.13 tablespoon sauteed shrimp paste',
    '0.25 tablespoons sugar',
    '0.03 teaspoon MSG',
    'rock salt and pepper',
    '0.25 package (16 ounces each) fresh miki noodles',
    'pork cracklings (chicharon), crushed',
    'fried garlic bits',
    'green onions',
    '1 whole raw eggs, optional'
  ],
  ARRAY[
    'In a deep pot, bring enough water to cover bones to a boil. Add bones and boil, skimming scum that floats on top, for about 10 minutes. Drain bones and discard liquid.',
    'Under cold running water, rinse bones to rid of any scum. Rinse pot. Return the bones to the pot and enough cold water (about 10 to 12 cups) to cover. Bring to a boil, skimming scum that floats on top. Lower heat, cover, and simmer for about 2 hours.',
    'Using a colander, strain broth. Scrape off any attached meat from the bones and set aside. Using a small spoon, scoop out marrow from beef bones and set aside. Discard the bones.',
    'Return broth to the pot and bring to a boil. Add pork shoulder and pork intestines. Cook for about 30 to 40 minutes or until tender. With a slotted spoon, remove from pot and allow to slightly cool to touch. Slice into strips and set aside.',
    'Add liver to pot and cook for about 7 to 10 minutes. With a slotted spoon, remove from pot and allow to slight cool to touch. Slice into strips and set aside.',
    'Add onions and garlic to the pot of hot broth. Cook for about 2 to 3 minutes or until onions and garlic are softened.',
    'Add shrimp paste and stir until dispersed. Add sugar and MSG. Season with rock salt and pepper to taste.',
    'In a saucepot, bring about 3 quarts of water to a boil. Using a strainer basket, submerge noodles for about 30 to 40 seconds. Drain well and divide into serving bowls.',
    'Ladle hot broth over the noodles. Top with sliced pork, intestines, liver, and any scrap meat from bones. Divide bone marrow into each bowl, if desired.',
    'Garnish with chicharon, fried garlic bits, and green onions.',
    'Crack a raw egg into each bowl, if desired. Serve hot.'
  ],
  'Eggs, Shellfish, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Flexitarian'],
  85
),

-- 8. Creamy Palabok
(
  'Creamy Palabok',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/creampy_palabok.jpg',
  'Pancit Palabok is a hearty Filipino noodle dish that is flavorful and saucy! This recipe is made easy by using simpler ingredients without sacrificing the flavors at all! Notes: Different brands of annatto powder can have varying effects. Some can have stronger coloring effects even with just a tablespoon. Start with a small amount first and add more as needed.',
  ARRAY[
    '85 g rice noodles (about 1 ½ cups cooked)',
    '½ tbsp oil',
    '½ garlic clove – minced',
    '1 medium onion chopped',
    '50 g ground pork',
    '½ tbsp fish sauce',
    '¼ tbsp (about ½ tsp) annatto powder (or just a pinch if using food color)',
    '165 ml water (including shrimp stock)',
    '⅙ shrimp bouillon cube (or a small pinch if using pork cube)',
    '10 g flour (~1 tbsp)',
    '2 ½ tbsp water (to dissolve flour)',
    'A small pinch ground pepper',
    '1 hard-boiled egg (so about 2 slices)',
    '20 g shrimp (about 2–3 pieces) – boiled or steamed',
    '40 g chicharon – crushed (about 2 tbsp)',
    '4 g spring onions – chopped (about 1 tsp)',
    '20 g smoked fish (tinapa) (if available)',
    '⅓ calamansi (or a small lemon wedge)'
  ],
  ARRAY[
    'Soak the rice noodles in water for 15 minutes. Meanwhile, boil enough water in a pot. Once the noodles are done soaking, drain them from the cold water and then submerge in boiling water for a few minutes just until they are cooked but still firm, about 3-5 minutes. Once cooked, drain the water and transfer to a container or large bowl and set aside.',
    'In a saucepan over medium heat, saute garlic and onion in oil until tender. Add the ground pork and fish sauce and cook for 5-10 minutes or until all bits are cooked. Stir often to get rid of big lumps.',
    'Dilute the annatto powder in the 4 cups of water and add this to the pork. Add the shrimp bouillon and let simmer for some minutes until it starts to boil.',
    'In a small bowl combine flour and 1 cup of water to make a slurry. Add this to the pot and stir until the sauce becomes thick. Season with ground pepper and then turn off the heat.',
    'Pour three-quarters of the sauce into the noodles and mix until all noodles are covered with sauce. Transfer the noodles to a serving dish. Pour remaining sauce on top. Arrange toppings on top, finishing with the crushed chicharon and spring onions. Place the calamansi or lemon wedges on the sides or in another smaller bowl for squeezing. Serve while warm.'
  ],
  'Eggs, Shellfish, Fish, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Flexitarian'],
  75
),

-- 9. Creamy Pork Steak
(
  'Creamy Pork Steak',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/creamy_pork_steak.jpg',
  'Creamy Pork Steak is a delicious reinvention of the classic Filipino dish, the pork bistek. It''s easy to make but delivers a hearty, luscious taste. Thinly sliced pork shoulder is cooked in a citrus-soy sauce mixture until fork-tender, sautéed until lightly browned, and then finished with all-purpose cream.',
  ARRAY[
    '0.5 pounds pork shoulder, sliced thinly',
    '0.08 cups calamansi juice',
    '0.04 cup soy sauce',
    '0.04 cup water',
    '0.17 teaspoon brown sugar',
    '0.17 tablespoon oil',
    '0.17 onion, peeled and sliced thinly',
    '0.5 cloves garlic, peeled and minced',
    '0.08 cup Nestle All-Purpose Cream',
    'salt and pepper to taste'
  ],
  ARRAY[
    'In a pot, combine pork shoulder, calamansi juice, soy sauce, water, brown sugar, and pepper. Stir to distribute. Cover with the lid and bring to a boil. Occasionally skim the scum that floats on top.',
    'Lower heat and simmer for about 40 to 60 minutes until tender. Drain pork well and reserve the cooking liquid.',
    'In a wide pan over medium heat, heat oil. Add onions and garlic and cook until softened.',
    'Add pork and cook until lightly browned. Add reserved liquid and all-purpose cream. Stir to distribute.',
    'Add salt and pepper to taste. Simmer until heated through and slightly thickened.'
  ],
  'Dairy, Soy',
  ARRAY['Balance Diet', 'High Protein', 'Gluten-Free', 'Flexitarian'],
  80
),

-- 10. Beef Tapa
(
  'Beef Tapa',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/beef_tapa.jpg',
  'Beef Tapa is dried cured beef similar to "Beef Jerky". This is traditionally prepared by curing the meat with sea salt and letting it dry directly under the sun for the purpose of preserving the meat. Tapa is usually fried and is best served with vinegar. A popular combination called "Tapsilog" is commonly served in eateries called tapsihan and gotohan.',
  ARRAY[
    '0.38 lb beef sirloin thinly sliced',
    '1.25 tablespoons soy sauce',
    '0.75 tbsp minced garlic or 1 tablespoon garlic powder',
    '0.5 tbsp sugar',
    '0.06 teaspoon salt',
    '0.06 teaspoon ground black pepper'
  ],
  ARRAY[
    'In a container, combine soy sauce, garlic, salt, pepper, and sugar and mix well. Set aside',
    'Place the beef in the clear plastic bag',
    'Pour-in the the mixed seasonings in the clear plastic bag with meat and mix well',
    'Place inside the refrigerator and marinate for a minimum of 12 hours',
    'In a pan, place 1 cup water and bring to a boil',
    'Add 3 tbsp of cooking oil',
    'Put-in the marinated beef tapa and cook until the water evaporates.'
  ],
  'Soy',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian', 'Low-Carb'],
  55
),

-- 11. Beef in Creamy Mushroom Sauce
(
  'Beef in Creamy Mushroom Sauce',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/beef_in_creamy_mushroom_sauce.jpg',
  'Beef in Creamy Mushroom Sauce features fork-tender beef and a delectable mushroom gravy that''s delicious over steamed rice, mashed potatoes, or egg noodles. Easy to make and cooks in one pan! Notes: For a more tender chew, slice the beef across the grain. You can freeze the meat for about 20 minutes or until partially firm to make slicing easier.',
  ARRAY[
    '0.5 pounds beef sirloin',
    'salt and pepper to taste',
    'canola oil',
    '0.17 can (8 ounces) whole mushrooms, drained',
    '0.17 tablespoon butter',
    '0.17 onion, peeled and chopped',
    '0.5 cloves garlic, peeled and minced',
    '0.04 cup flour',
    '0.5 cups beef broth',
    '0.17 cup all-purpose cream'
  ],
  ARRAY[
    'Cut the beef across the grain into ¼-inch thick slices and season with salt and pepper to taste.',
    'In a wide pan over medium-high heat, heat about 1 tablespoon oil. Add mushrooms and cook for about 30 seconds. Remove from pan and keep warm.',
    'Add another tablespoon of oil to the pan if needed. Add beef in a single layer and sear for about 2 to 3 minutes per side or until lightly browned. Do not overcrowd pan, cook beef in batches as needed. Remove meat from the pan and keep warm.',
    'In the pan, add the butter.',
    'When melted, add onions and garlic and cook until softened.',
    'Add flour and continue to cook, stirring regularly, for about 1 to 2 minutes.',
    'Gradually add broth, whisking regularly to prevent lumps.',
    'Add beef. Bring to a boil, skimming scum that floats on top.',
    'Lower heat, cover, and simmer for 1 to 1 ½ hours or until meat is fork-tender. Add more broth or water in ½ cup increments if the liquid is getting too thick before the meat is fully tender.',
    'Add all-purpose cream and stir to distribute. Season with salt and pepper to taste.',
    'Add mushrooms. Continue to cook for another 1 to 2 minutes or until mushrooms are heated through. Serve hot.'
  ],
  'Dairy, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Flexitarian'],
  90
),

-- 12. Ampalaya con Carne
(
  'Ampalaya con Carne',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ampalaya_con_carne.jpg',
  'Ampalaya or Bitter Gourd (sometimes called bitter melon) is a vegetable full of nutrients that are good for the body. Ampalaya con Carne is a dish composed of beef strips and ampalaya – this is also known as beef with ampalaya. This is perfect for those who wish to eat ampalaya but cannot handle the bitterness. The beef acts as a neutralizing agent; it covers the bitterness with its flavorful juices.',
  ARRAY[
    '56.7 g beef sirloin sliced into thin pieces',
    '0.25 piece ampalaya cored and sliced',
    '0.25 piece onion chopped',
    '46.88 g water',
    '0.75 tablespoons cooking oil',
    '0.5 tablespoons oyster sauce marinade ingredients',
    '0.75 tablespoons soy sauce',
    '0.38 teaspoon Sesame oil',
    '0.38 teaspoons cornstarch',
    '1 cloves garlic minced',
    '0.25 thumb ginger minced',
    '0.13 teaspoon ground black pepper'
  ],
  ARRAY[
    'Combine beef sirloin, ground black pepper, soy sauce, sesame oil, and oyster sauce. Mix well. Add cornstarch and then continue to mix until all ingredients are well distributed. Marinate for 10 minutes.',
    'Heat oil in a cooking pot. Add the marinated beef sliced. Cook both sides for 30 seconds. Stir-fy the beef for 3 minutes. Set aside.',
    'Saute the ginger and garlic using the remaing oil. Add onion and continue to cook until it softens.',
    'Put the ampalaya into the pan. Cook for 1 minute.',
    'Add the beef back into the pan. Add water. Cover and let boil. Cook in medium heat for 5 minutes.',
    'Transfer to a serving bowl. Serve!'
  ],
  'Soy',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  50
),

-- 13. Poqui Poqui
(
  'Poqui Poqui',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/poqui_poqui.jpg',
  'Poqui Poqui is a scrambled egg dish made of roasted eggplant, sauteed onions, and tomatoes. It''s a healthy and tasty meatless breakfast or dinner meal you''d feel good serving the whole family. Perfect for breakfast or dinner meal!',
  ARRAY[
    '0.5 large eggplants',
    '0.5 tablespoons oil',
    '0.25 small onion, peeled and sliced thinly',
    '0.5 cloves garlic',
    '0.5 large Roma tomatoes, chopped',
    '1 eggs, beaten',
    'salt and pepper to taste'
  ],
  ARRAY[
    'Over hot coals or gas stove, grill eggplants until skins are charred. Remove from heat and under running water, peel skin and rinse well. Coarsely chop flesh.',
    'In a skillet over medium heat, heat oil. Add onions and garlic and cook until softened.',
    'Add tomatoes and continue to cook, mashing with the back of the spoon, until softened.',
    'Add eggplant. Season with salt and pepper to taste.',
    'Add beaten eggs, stirring to combine, and continue to cook until eggs are just set. Serve hot.'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'Vegetarian', 'Dairy-Free', 'Gluten-Free', 'Low-Fat', 'Low-Calorie'],
  30
),

-- 14. Black Pepper Chicken
(
  'Black Pepper Chicken',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/black_pepper_chicken.jpg',
  'Black Pepper Chicken is a quick and easy stir-fry that''s perfect for busy weeknights. Prepared with yummy spices and crisp bell peppers, it''s a delicious meal the whole family will enjoy! Notes: Slice the meat across the grain and into uniform thickness to ensure a tender chew and even cooking. Freeze it for a few minutes or until slightly firm to make slicing easier.',
  ARRAY[
    '0.25 pound chicken thigh meat, cut into 1 ½ inch cubes',
    '0.25 large egg white',
    '0.25 tablespoon cornstarch',
    '0.25 tablespoon Chinese rice wine',
    '0.13 teaspoon salt',
    '0.75 tablespoons canola oil',
    'water',
    '0.06 cup oyster sauce',
    '0.25 tablespoon soy sauce',
    '0.25 tablespoon honey',
    '0.25 teaspoon black pepper',
    '0.25 teaspoon sesame oil',
    '0.25 onion',
    '0.5 cloves garlic',
    '0.13 red bell pepper, seeded, cored, and cubed',
    '0.13 green bell pepper, seeded, cored, and cubed'
  ],
  ARRAY[
    'Wash chicken and drain well.',
    'In a bowl, combine egg white, cornstarch, rice wine, 1 tablespoon of the oil, and salt. Whisk together until well-blended.',
    'Add chicken and stir to fully coat. Marinate in the refrigerator for about 30 minutes. In a colander, drain chicken.',
    'In a pot over high heat, combine about 2-inch deep of water and 1 tablespoon of oil. Bring to a boil. Reduce heat to medium-low and immediately add chicken, stirring to disperse.',
    'Bring water back to a gentle simmer and once it''s barely bubbling, continue to cook chicken for about 1 minute, stirring occasionally. With a slotted spoon, remove chicken from pot and drain well. Keep warm and set aside.',
    'In a bowl, combine oyster sauce, soy sauce, honey, rice wine, black pepper, and sesame oil. Stir until well-blended and set aside.',
    'In a wok or wide pan over high heat, heat the remaining 1 tablespoon of oil. Add onions, garlic, and bell peppers and cook, stirring regularly, for about 1 to 2 minutes or until tender yet crisp.',
    'Add sauce mixture and bring to a boil.',
    'Add chicken and stir to fully coat with sauce. Continue to cook, stirring regularly, for about 1 to 2 minutes or until chicken is heated through. Serve hot.'
  ],
  'Eggs, Soy',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  65
),

-- 15. Lechon Paksiw
(
  'Lechon Paksiw',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/lechon_paksiw.jpg',
  'Lechon Paksiw is the perfect use of party leftovers! Made of chopped roast pork, vinegar, liver sauce, and spices, It''s a mouthwatering dish you''ll love with steamed rice; a great use of roast pork leftovers! Note: When the vinegar is added in, bring to a boil, uncovered and without stirring, for a few minutes to mellow out the strong acid taste.',
  ARRAY[
    '0.17 tablespoon oil',
    '0.17 large onion, peeled and sliced thinly',
    '0.17 head garlic, peeled and minced',
    '0.13 cup vinegar',
    '0.33 cups water',
    '0.33 cups lechon sauce, homemade or store-bought',
    '0.13 cup brown sugar',
    '0.5 pounds (about 4 cups) leftover lechon or lechon kawali, chopped into 1-inch pieces',
    '0.5 bay leaves',
    '0.08 cup liver spread',
    'salt and pepper to taste'
  ],
  ARRAY[
    'In a pot over medium heat, heat oil. Add onions and garlic and cook until softened.',
    'Add vinegar and water and bring to a boil, uncovered and without stirring, for about 3 to 5 minutes.',
    'Add lechon sauce and sugar and stir to combine.',
    'Add pork and bay leaves.',
    'Lower heat, cover and continue to cook for about 15 to 20 minutes or until meat is tender. Add more water in ½ cup increments as needed.',
    'Add liver spread and stir until well distributed.',
    'Season with salt to taste and generously with pepper.',
    'Continue to cook until sauce is slightly thickened. Serve hot.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  70
),

-- 16. Spare Ribs with Ketchup and Pineapple
(
  'Spare Ribs with Ketchup and Pineapple',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/spare_ribs_with_ketchup_and_pineapple.jpg',
  'Spare Ribs braised in ketchup are an easy weeknight dinner the whole family will love. The fork-tender pork ribs and sweet and tangy sauce make a delicious main dish with steamed rice or mashed potatoes.',
  ARRAY[
    '0.5 pounds pork spareribs, cut into 2-inch cubes',
    'salt and pepper to taste',
    '0.25 thumb-size fresh ginger, peeled and grated',
    '0.25 can (20 ounces) pineapple chunks, drained and juice reserved',
    '0.25 cup pineapple juice (from the canned pineapples)',
    '0.06 cup soy sauce',
    '0.13 cup banana ketchup',
    '0.25 tablespoon canola oil',
    '0.25 onion, peeled and chopped',
    '0.5 cloves garlic, peeled and minced',
    '0.25 cup water'
  ],
  ARRAY[
    'Season spare ribs with salt and pepper to taste.',
    'Extract juice from grated ginger and discard the pressed ginger.',
    'In a large bowl, combine pineapple juice (reserved from the canned pineapples), soy sauce, banana ketchup, and ginger juice.',
    'Add spare ribs and massage the marinade into the meat. Marinate in the refrigerator for about 30 minutes. Drain meat well and reserve liquid.',
    'In a pot over medium heat, heat oil. Add onions and garlic and cook until softened.',
    'Add spareribs and cook, turning as needed, until lightly browned.',
    'Add reserved marinade and water and bring to a boil. Lower heat, cover and cook for about 40 to 50 minutes or until meat is fork-tender and the sauce is reduced.',
    'Add pineapple chunks and cook for about 2 to 3 minutes or until heated through. Serve hot.'
  ],
  'Soy',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  75
),

-- 17. Sesame Chicken
(
  'Sesame Chicken',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sesame_chicken.jpg',
  'Sesame Chicken is a popular dish featuring bite-sized pieces of chicken that are battered and deep-fried until golden and crispy, then coated in a sticky, sweet, and savory sauce with a prominent sesame flavor from sesame oil and a generous topping of sesame seeds.',
  ARRAY[
    '0.06 cup soy sauce',
    '0.5 Tbsp water',
    '0.25 Tbsp toasted sesame oil',
    '0.75 Tbsp brown sugar',
    '0.25 Tbsp rice vinegar',
    '0.25 tsp grated fresh ginger',
    '0.5 cloves garlic, minced',
    '0.13 Tbsp cornstarch',
    '0.25 Tbsp sesame seeds',
    '0.5 Tbsp cooking oil',
    '0.25 lb boneless skinless chicken thighs',
    '0.25 large egg',
    '0.5 Tbsp cornstarch',
    '0.25 pinch each salt and pepper',
    '0.5 whole green onions'
  ],
  ARRAY[
    'First, prepare the sauce. In a small bowl stir together the soy sauce, water, sesame oil, brown sugar, rice vinegar, fresh ginger, minced garlic, cornstarch, and sesame seeds. (Grate the ginger with a small-holed cheese grater). Set the sauce aside.',
    'In a large bowl, whisk together the egg, 2 Tbsp cornstarch, and a pinch of salt and pepper. Trim any excess fat from the chicken thighs, then cut them into small 1 inch pieces. Toss the chicken in the egg and cornstarch mixture.',
    'Add the cooking oil to a large skillet and heat it over medium flame. Wait until the skillet is very hot, then swirl the skillet to make sure the oil coats the entire surface. Add the batter coated chicken and spread it out into a single layer over the surface of the skillet.',
    'Allow the chicken pieces to cook, undisturbed, until golden brown on the bottom. Then, carefully flip the chicken, breaking up the pieces into smaller clumps as you flip. Continue to cook the chicken until golden brown on the other side. Stir the chicken as little as possible to avoid breaking the egg coating from the surface of the chicken.',
    'Once the chicken is cooked through and golden brown on all sides, pour the sauce over top. Toss the chicken to coat in the sauce. As the sauce comes up to a simmer, it will begin to thicken. Continue to gently stir the chicken in the sauce until it has thickened, then turn off the heat.',
    'Serve the chicken over a bed of rice and sprinkle the sliced green onions over top.'
  ],
  'Eggs, Soy',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  85
);
