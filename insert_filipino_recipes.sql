-- Insert Filipino Recipes into Supabase
-- This SQL statement inserts 13 authentic Filipino recipes with proper diet classifications and allergy warnings

INSERT INTO recipes (title, image_url, short_description, ingredients, instructions, allergy_warning, diet_types, cost) VALUES

-- 1. Corned Beef Silog
(
  'Corned Beef Silog',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/corned_beef_silog.jpeg',
  'Corned Beef Silog is a Filipino breakfast dish that combines corned beef, garlic fried rice, and a fried egg. It is part of the popular "silog" meals, known for being filling and commonly enjoyed at home or in local eateries.',
  ARRAY[
    '4 oz. corned beef in can',
    '0.33 yellow onion',
    '1 cloves garlic crushed',
    '1 cups sinangag',
    '1 egg',
    '1.33 tablespoons cooking oil',
    '0.17 cup beef broth',
    'Salt and pepper to taste'
  ],
  ARRAY[
    'Heat oil on a pan. Once the oil gets hot, crack an egg and fry sunny-side-up. Remove the fried egg and place in a plate. Do this step until all 3 eggs are cooked.',
    'Using the remaining oil, sauté the garlic until it turns medium brown. Add the onion and sauté until it softens.',
    'Add the corned beef. Sauté for 2 minutes',
    'Pour the beef broth in the pan. Continue to cook for 2 to 3 minutes or until the liquid evaporate. Add salt and pepper to taste.',
    'Arrange a cup of sinangag (garlic fried rice) and a piece of egg on a plate. Put 1/3 of the cooked corned beef. Do this step on all 3 plates. Serve.'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  45
),

-- 2. Ham and Egg Fried Rice
(
  'Ham and Egg Fried Rice',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ham_and_egg_fried_rice.png',
  'Ham and egg fried rice is a popular variation of egg fried rice that features diced ham and scrambled eggs as key ingredients. People value this ham and egg fried rice recipe for its simplicity, quick preparation, and ability to use leftover rice, making it a convenient and flavorful meal option.',
  ARRAY[
    '1 cups cooked rice preferably a day old',
    '0.19 cups ham chopped into small pieces',
    '0.5 eggs beaten',
    '0.25 tablespoon low sodium soy sauce',
    '0.25 teaspoon salt',
    '0.25 teaspoon garlic powder optional',
    '0.5 teaspoons canola oil'
  ],
  ARRAY[
    'Combine rice, salt and garlic powder. Gently mix the ingredients using a slotted spoon or your clean hands. Set aside.',
    'Heat the oil in a pan.',
    'Add the ham and cook for 2 minutes.',
    'Put-in the rice. Stir.',
    'Add soy sauce and stir. Cook for 5 minutes.',
    'Clear one side of the pan by moving the rice on the other side to the point where you can see the bottom of the pan.',
    'Pour-in the beaten egg. Let it cook then cut it into small pieces using the tip of your spatula.',
    'Mix the egg with the rice and other ingredients. Cook for 2 to 3 minutes more.',
    'Transfer to a serving plate. Serve.'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  35
),

-- 3. Bam I (Pancit Bisaya)
(
  'Bam I',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/bam-i.png',
  'This Pancit Bisaya, or Bam I, is a prime example of how Cebuanos have taken classic Filipino dishes and truly made it their own. Throw together some sotanghon and canton noodles alongside a mix of different proteins equally tasty. Add your vegetables, sauces, and more, and you have the fantastic Pancit Bam I.',
  ARRAY[
    '0.25 lb pork sliced',
    '0.25 lb chicken boiled and shredded',
    '2 pieces Chinese sausage sliced',
    '0.5 lb shrimp shelled and heads removed',
    '4 ounces flour sticks pancit canton noodles',
    '2 to 3 ounces rice noodles sotanghon soaked in water',
    '0.75 to 1 cups chicken stock',
    '1.5 cups cabbage chopped',
    '0.38 cup carrots julienned',
    '0.25 cup dried wood ear soaked in water and chopped (also known as tenga ng daga)',
    '0.5 medium onion diced',
    '0.13 cup parsley cleaned and chopped',
    '0.25 cup shrimp juice derived by pounding the head of the shrimp',
    '0.25 cup soy sauce',
    '0.5 piece chicken cube or bouillon',
    '0.5 tablespoon garlic minced',
    'Salt and ground black pepper to taste',
    '1 to 1.5 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat a cooking pot then pour-in cooking oil.',
    'Sauté garlic and onions then add the sliced pork and cook for 3 minutes.',
    'Put-in the Chinese sausage and shredded chicken and cook for 3 to 5 minutes.',
    'Add soy sauce, shrimp juice, salt, ground black pepper, chicken bouillon, and chicken stock then let boil. Simmer for 5 to 8 minutes.',
    'Put the shrimps, cabbage, carrots, and wood ears in then cook for 2 minutes.',
    'Add the soaked noodles then stir. Cook for a minute.',
    'Put-in the flour sticks then stir well. Cook for 3 minutes or until the liquid is gone.',
    'Top with green onions and place calamansi on the side.',
    'Serve hot. Share and enjoy! Mangaon na ta!'
  ],
  'Shellfish, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Flexitarian'],
  120
),

-- 4. Seaweed Salad (Ensaladang Lato)
(
  'Seaweed Salad (Ensaladang Lato)',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/seaweed_salad_(Ensaladang%20Lato).png',
  'Seaweed Salad or Ensaladang Lato is a type of Filipino salad that makes use of edible seaweed as its main ingredient. These types of seaweeds are sometimes called sea grapes because of its grape-like appearance.',
  ARRAY[
    '0.17 lb. lato or sea grapes, rinsed',
    '0.67 large plum tomato cored and diced',
    '0.67 medium red onion minced',
    '0.17 cup white vinegar',
    '0.08 teaspoon ground black pepper',
    '0.17 teaspoon salt',
    '0.17 teaspoon granulated white sugar'
  ],
  ARRAY[
    'In a bowl, combine vinegar, salt, pepper, sugar, tomato, and onion. Stir to mix.',
    'Add the lato or sea grapes. Toss. Let it stay for at last 10 minutes.',
    'Transfer to a serving bowl. Serve.'
  ],
  'None',
  ARRAY['Balance Diet', 'Vegan', 'Vegetarian', 'Dairy-Free', 'Gluten-Free', 'Low-Calorie', 'Low-Fat'],
  25
),

-- 5. Tinolang Tahong
(
  'Tinolang Tahong',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/tinolang_tahong.png',
  'Tinolang Tahong is a mussel soup recipe with ginger and spinach. This recipe is inspired by a famous Filipino soup dish called tinolang manok or chicken tinola which uses chicken, green papaya wedges, and chili pepper leaves. This mussel soup recipe is simple, budget-friendly, and delicious. This is also quick to prepare.',
  ARRAY[
    '151.2 g mussels tahong, cleaned',
    '20 g spinach or hot pepper leaves',
    '1 thumbs ginger julienned',
    '0.33 piece onion sliced',
    '1.67 cloves garlic pounded',
    '0.5 teaspoons salt or 3 tbsp fish sauce',
    '0.17 teaspoon ground black pepper',
    '250 g water',
    '0.67 tablespoons cooking oil',
    '0.67 pieces long green pepper optional'
  ],
  ARRAY[
    'Heat a cooking pot and pour-in cooking oil.',
    'Saute garlic and onion.',
    'Add ginger and mussels, and then cook for a minute.',
    'Pour-in water. let boil. Cook for 5 minutes.',
    'Put-in the spinach or hot pepper leaves. Cook for 3 minutes.',
    'Add salt (or fish sauce) and pepper. Stir.',
    'Transfer to a serving bowl. Serve.'
  ],
  'Shellfish',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Low-Fat', 'Pescatarian'],
  40
),

-- 6. Ginataang Alimasag
(
  'Ginataang Alimasag',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginataang_alamasag.jpg',
  'Ginataang Alimasag are Crabs cooked in Coconut Milk. This recipe features the use of spinach and Thai chili as a replacement for Malunggay. Squash and string beans (kalabasa and sitaw) can also be placed instead of Spinach (or Malunggay).',
  ARRAY[
    '0.75 lbs blue crabs Alimasag',
    '0.5 tbsp shrimp paste',
    '0.25 tbsp fish sauce',
    '0.25 tsp garlic minced',
    '0.25 piece onion minced',
    '0.25 thumb ginger cut into thin strips',
    '0.75 tbsp cooking oil',
    '1 cups coconut milk',
    '0.13 tsp ground black pepper',
    '0.25 bunch fresh spinach',
    '1.5 pieces Thai chili'
  ],
  ARRAY[
    'In a large pot, sauté the garlic, onion, and ginger',
    'Add the ground black pepper and coconut milk then bring to a boil',
    'Put-in the shrimp paste and fish sauce and cook until the coconut milk''s texture is thick and natural oil comes out of it (approximately 20 ++ minutes)',
    'Add the Thai chili and simmer for 5 minutes',
    'Put the crabs in the pot and mix until evenly covered with coconut milk. Simmer for 5 to 20 minutes. (Note: If crabs were steamed prior to cooking, 5 to 8 minutes is enough)',
    'Add the spinach and simmer for 5 minutes',
    'Serve hot.'
  ],
  'Shellfish',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Pescatarian'],
  180
),

-- 7. Chicken Gising-gising
(
  'Chicken Gising-gising',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_gising_gising.png',
  'Gising-gising is a delightful Filipino dish that makes use of chili peppers, winged beans, and the flavor of coconut milk. And as the name connotes, it should wake you up for the rest of your day with a delicious energy boost because "gising" means "wake up" in English. The more well-known rendition of this recipe uses ground pork.',
  ARRAY[
    '0.5 lbs. chicken cut into serving pieces',
    '22.5 grams Knorr Ginataang Gulay Mix',
    '0.13 lb. winged bean sigarilyas, sliced',
    '0.5 long green chili pepper sliced',
    '1.25 Thai chili pepper optional',
    '0.25 tablespoon shrimp paste',
    '0.75 cups water',
    '0.25 onion chopped',
    '1.25 cloves garlic chopped',
    '0.5 thumbs ginger chopped',
    '0.75 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat oil in a pan. Sauté garlic, onion, and ginger.',
    'Add chicken pieces. Stir fry until the exterior turns light brown in color.',
    'Add 1 cup water. Let boil.',
    'Combine Knorr Ginataang Gulay Mix with 2 cups water. Mix well and then pour into the pan. Cover and continue cooking between low to medium heat setting for 20 minutes.',
    'Add shrimp paste, long green pepper, and winged beans. Cover the pan and continue cooking for 5 minutes.',
    'Add Thai chili peppers if desired. Cook for 2 minutes more.',
    'Transfer to a serving bowl. Serve hot with rice.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  85
),

-- 8. Chicken Mami
(
  'Chicken Mami',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_mami.png',
  'The soup base for this recipe is composed of chicken broth and water, along with salt. You can also do it without the chicken broth, as long as a piece of chicken cube is added to the water. The use of bone-in chicken also helped make the soup tastier. This is usually sold in noodle houses or "mamihan" along with other favorites such as Beef Mami, Pares, and Siopao.',
  ARRAY[
    '0.5 lb. chicken breasts bone-in',
    '0.5 piece carrot peeled',
    '0.25 piece Napa cabbage',
    '0.5 bunch scallions',
    '0.5 lb. egg noodles fresh',
    '0.13 cup toasted garlic',
    '2 pieces hard boiled egg sliced',
    '2 cups chicken broth',
    '2 cups water',
    '1 teaspoons salt'
  ],
  ARRAY[
    'Combine chicken broth and water in a cooking pot. Let boil.',
    'Add salt and chicken breasts. Cover and boil between low to medium heat for 30 to 35 minutes.',
    'Remove the chicken from the pot. Let it cool down. Shred the meat from the bone. Set aside. Save the broth used for boiling. It will be used later.',
    'Slice the carrot into thin strips (julienne) and then chop the Napa cabbage. Also chop the scallions. Set aside.',
    'Prepare the fresh noodles by boiling 4 cups water. Once the water starts to boil, add the noodles. Let the water boil once more, and then continue to cook the noodles for 3 minutes. Remove from the pot and arrange in a serving bowl.',
    'Top the noodles in the bowl with shredded chicken, julienne carrot, chopped cabbage, and slices of boiled eggs.',
    'Pour the hot broth into the bowl. Sprinkle with scallions and roasted or toasted garlic.',
    'Serve with a condiment composed of patis (fish sauce) and calamansi.'
  ],
  'Eggs, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Flexitarian'],
  65
),

-- 9. Sweet and Sour Chicken
(
  'Sweet and Sour Chicken',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sweet_and_sour_chicken.jpg',
  'Sweet and Sour Chicken is crispy chicken pieces coated in an easy homemade sweet and sour sauce.',
  ARRAY[
    '1 to 1 ½ bags (from 24 ounce bags) frozen Bare breaded chicken chunks (or any good quality frozen chicken nuggets)',
    '3/4 cup granulated sugar',
    '4 Tablespoons ketchup',
    '1/2 cup distilled white vinegar',
    '2 Tablespoons low-sodium soy sauce',
    '1 teaspoon garlic salt'
  ],
  ARRAY[
    'Start by heating a large pan or wok over medium heat with a small amount of oil. Add the frozen chicken nuggets in a single layer (or as close as possible) and cook them for about 8 to 10 minutes, turning occasionally, until they''re heated through and slightly crispy on the outside.',
    'While the nuggets are cooking, whisk together the sugar, ketchup, vinegar, soy sauce, and garlic salt in a bowl until fully combined. If you prefer a thicker sauce, you can dissolve a teaspoon of cornstarch in a tablespoon of water and stir it into the sauce mixture.',
    'Once the nuggets are fully cooked and crispy, reduce the heat to low and pour the sauce evenly over them in the pan. Stir gently to coat all the pieces and let everything simmer together for about 5 to 8 minutes. This allows the sauce to thicken slightly and coat the chicken well. Stir occasionally during this time to prevent sticking or burning.',
    'Serve the chicken hot, either on its own or over rice, and enjoy your stovetop version of sweet and sour chicken nuggets.'
  ],
  'Soy, Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  95
),

-- 10. Kinamunggayang Manok
(
  'Kinamunggayang Manok',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/kinamunggayang_manok.jpg',
  'For most this will look like Tinolang Manok but for the Visayans this is a totally different dish and it''s called Kinamunggayang Manok which when directly translated means Chicken and Moringa / Malunggay leaves. So, what is the difference between tinola and this dish? The most evident difference us that the Kinamunggayang Manok uses a lot malunggay leaves as well as banana blossoms which the Tagalogs usually sees only on Kare Kare. This dish also does not use green papaya which is a key ingredient in Tinola.',
  ARRAY[
    '1 kg free range chicken thighs and legs',
    '1 litre chicken stock',
    '1 1/2 cup malunggay leaves',
    '1 small banana blossom, shredded',
    '1 thumb sized ginger, thinly sliced',
    '1 large red onion, chopped',
    '6 cloves garlic, minced',
    '2 tbsp salt, for brine',
    'cooking oil',
    'fish sauce',
    'freshly ground black pepper'
  ],
  ARRAY[
    'Soak banana blossoms in 3 cups of water with 2 tbsp salt. Set is aside for 2 hours.',
    'In a pot heat oil and sauté garlic, onions and ginger. Cook until onions are soft.',
    'Add chicken and stir fry for 2 minutes in high heat browning all sides.',
    'Add chicken stock, bring to a boil and simmer for 45 minutes, if you are not using free range 20 minutes would be enough.',
    'Add banana blossom and simmer for additional 10 minutes',
    'Add malunggay leaves, cover and simmer for 5 more minutes.',
    'Season with fish sauce and freshly ground pepper.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  90
),

-- 11. Goto
(
  'Goto',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/goto.png',
  'Goto is a type of rice porridge with innards of either pig or cow. This Special Goto Recipe uses both ox tripe and pig intestine. Goto has been famous in the Philippines because it is affordable and can easily satisfy hunger. This has also been a breakfast favorite and a rainy day comfort food.',
  ARRAY[
    '0.5 cup uncooked rice',
    '0.5 lb. ox tripe cleaned',
    '0.5 lb. pig large intestine cleaned',
    '2 eggs boiled and shelled',
    '2.5 cups water for cooking',
    '3 cups water for boiling',
    '1 teaspoons beef powder or 1 beef cube',
    '0.5 teaspoon turmeric powder optional',
    '1 tablespoons minced ginger',
    '0.5 medium onion minced',
    '2.5 cloves garlic minced',
    '1 teaspoons garlic powder',
    '1.5 tablespoons cooking oil',
    '0.5 head toasted garlic',
    '0.13 cup chopped green onion',
    '0.25 cup crushed chicharon',
    'Salt and pepper to taste'
  ],
  ARRAY[
    'Boil 6 cups of water in a deep cooking pot.',
    'Add the ox tripe, pig intestine, and 1 teaspoon salt. Boil for 2 to 3 hours or until soft. Add water as needed. Remove the tripe and intestine from the pot to cool down and then slice into bite sized pieces. Set aside.',
    'Heat the cooking oil in a deep cooking pot.',
    'Saute the onion, ginger, and garlic.',
    'Once the onion is soft, add the tripe and intestine. Cook for 2 to 3 minutes.',
    'Add the beef powder( or cube), turmeric powder, and garlic powder.',
    'Pour-in the water. Stir and let boil.',
    'Add the rice. Allow the water to boil once more and then adjust the heat between low to medium. Cook for 30 to 45 minutes or until the desired texture is achieved. Add water if needed and stir every 5 minutes or so to prevent the rice from sticking on the pan.',
    'Add salt and pepper to taste.',
    'Transfer to a serving bowl. Add egg and top with green onions, toasted garlic, and crushed chicharon.',
    'Serve.'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  55
),

-- 12. Chicken Arroz Caldo
(
  'Chicken Arroz Caldo',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_arroz_caldo.png',
  'Chicken arroz caldo is a type of Filipino rice porridge with chicken slices. It is best served when topped with hard boiled eggs, some chopped scallions, and toasted or roasted garlic.',
  ARRAY[
    '0.33 lbs chicken cut into serving pieces',
    '0.13 cup Jasmine rice',
    '0.13 cup sweet rice',
    '0.33 Maggi Magic Chicken Cube',
    '5.67 ounces water',
    '1.33 cloves garlic chopped',
    '0.5 onions chopped',
    '1.33 eggs hard boiled',
    '0.17 cup green onions chopped',
    '0.5 thumbs ginger julienne',
    '0.17 tablespoon safflower kasubha',
    '0.17 teaspoon turmeric powder',
    'Fish sauce and ground black pepper to taste',
    '0.83 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat around 5 tablespoons of cooking oil in a wok. Add the garlic immediately. Slow fry it while occasionally stirring until golden brown. Remove the garlic from the wok. Set aside.',
    'Saute the onion in the remaining oil until it softens. Add ginger. Saute for 1 minute.',
    'Add the chicken and continue sautéing until the color of the exterior turns light brown. Pour 2 tablespoons of fish sauce. Stir.',
    'Add the jasmine and sweet rice. Saute for 30 seconds,',
    'Pour the water into the wok. Cover and let it boil.',
    'Add Maggi Magic Chicken Cube. Adjust the heat to the lowest setting. Simmer the chicken while occasionally stirring until the rice breaks down with a thick consistency. (note: this usually takes more than 35 minutes to achieve).',
    'Add turmeric powder and safflower. Stir.',
    'Season with ground black pepper and fish sauce as needed.',
    'Add the boiled eggs, toasted garlic, and chopped green onions.',
    'Transfer to a serving bowl and top with more toasted garlic and chopped green onions. Serve with a condiment of calamansi and fish sauce.'
  ],
  'Eggs',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  50
),

-- 13. Inihaw na Liempo (Grilled Pork Belly)
(
  'Inihaw na Liempo (Grilled Pork Belly)',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/inihaw_na_liempo.jpg',
  'Inihaw na Liempo is known as Grilled Pork Belly in Filipino. This dish needs no introduction at all because the name of the dish already introduces itself. Inihaw na Liempo is also a popular and favorite dish in the Philippines. In fact, there were several dishes that makes use of this dish as its component. Sinuglaw and Special Tokwat baboy are few of the examples.',
  ARRAY[
    '0.67 lbs. pork belly',
    '0.17 cup soy sauce',
    '0.33 piece lemon or 3 to 4 pieces calamansi',
    '0.17 tsp ground black pepper',
    '0.33 tsp salt',
    '1.33 cloves garlic crushed',
    '0.08 cup banana catsup',
    '0.33 tbsp cooking oil'
  ],
  ARRAY[
    'Combine pork belly with the soy sauce, lemon, salt, ground black pepper, garlic and mix well. Marinade the pork belly for at least 3 hours.',
    'In a bowl, pour the pork belly marinade. Add banana catsup and cooking oil. Stir well. (This will be the basting sauce)',
    'Grill the pork belly while basting the top part of the pork after flipping it over.',
    'Serve hot with spiced vinegar or toyomansi.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  110
);