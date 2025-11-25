-- Insert Filipino Recipes into Supabase
-- This SQL statement inserts 17 authentic Filipino recipes with notes

INSERT INTO recipes (title, image_url, short_description, ingredients, instructions, allergy_warning, tags, cost, notes) VALUES

(
  'Filipino Spaghetti',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/filipino_spaghetti.png',
  'Filipino Spaghetti is a sweet version of the beloved pasta dish. This popular Filipino favorite is usually served during holidays and special occasions.',
  ARRAY[
    '0.67 lbs. Spaghetti noodles',
    '0.33 lb. ground pork',
    '2 ounces luncheon meat minced',
    '1.33 pieces hotdogs or beef franks',
    '11.67 ounces Filipino Style Spaghetti Sauce',
    '0.17 cup shredded cheddar cheese',
    '0.33 cup beef broth',
    '0.33 medium onion minced',
    '0.33 teaspoon minced garlic',
    'Salt and pepper to taste',
    '1 tablespoons cooking oil'
  ],
  ARRAY[
    'Cook the Spaghetti noodles according to package instructions. Once cooked, transfer to a bowl. Set aside.',
    'Heat the oil in a Pan.',
    'Saute the onion and garlic.',
    'Once the onions becomes soft, add the ground pork. Cook until the color turns light brown.',
    'Add the luncheon meat and hotdog. Stir and cook for 2 to 3 minutes.',
    'Pour-in the Spaghetti sauce and beef broth. Stir and let boil. Cover and simmer for 30 minutes.',
    'Try to taste the sauce and add salt and pepper if needed.',
    'Pour the Filipino Style Spaghetti sauce over the Spaghetti. Top with shredded cheese.',
    'Serve.'
  ],
  'Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Flexitarian'],
  150,
  ''
),

(
  'Monggo Pinakbet',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/monggo_pinakbet.png',
  'Monggo Pinakbet is a combinaion of Ginisang monggo and pinakbet combination, a healthy dish is practically synonymous to a comforting one when it comes to Filipino cuisine. We love to bring a sense of warmth through various stews when we deal with our vegetables.',
  ARRAY[
    '2 ounces mung beans',
    '0.17 Knorr Pork Cube',
    '0.5 tablespoons shrimp paste',
    '2 string beans cut into 2-inch pieces',
    '0.17 Chinese eggplant sliced lengthwise',
    '0.17 bitter melon cored and sliced',
    '1.67 ounces Calabaza squash cubed',
    '1.33 pieces okra',
    '0.33 tomatoes cubed',
    '0.33 thumbs ginger crushed',
    '0.83 cloves garlic chopped',
    '0.17 onion chopped',
    '0.5 cups water',
    'Salt and ground black pepper to taste'
  ],
  ARRAY[
    'Soak the mung beans in water overnight. Drain the water and set the mung beans aside.',
    'Heat 2 tablespoons of cooking oil in a pan. Saute half of the total amount of garlic, onion, and tomatoes. Once the onion and tomato soften, add the mung beans. Saute for 2 minutes.',
    'Pour the water into the pot. Let boil.',
    'Add the Knorr Pork Cube. Stir. Cover the pot and boil the mung beans using low to medium heat for 45 minutes. Note: Add water as needed. Set this aside.',
    'On a separate pan, sauté the remaining garlic, onion, and tomato. Add the ginger. Continue sautéing until the onion and tomato softens.',
    'Add the sliced pork. Saute until the color of the pork turns light brown.',
    'Pour ¾ cup water. Let it boil. Cover the pot and continue boiling the pork until the water evaporates completely.',
    'Add the shrimp paste. Saute for 1 minute.',
    'Add calabaza squash. Cook for 2 minutes.',
    'Add eggplant, bitter melon, okra, and string beans. Saute for 2 minutes.',
    'Add ½ cup water. Let it boil.',
    'Pour the cooked mung beans into the pot. Stir and continue cooking for 3 to minutes.',
    'Season with salt and ground black pepper.',
    'Transfer to a serving bowl. Serve with rice.'
  ],
  'Shellfish',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  120,
  ''
),

(
  'Crispy Fried Chicken',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/crispy_fried_chicken.png',
  'Fried chicken is a dish of chicken pieces, often brined and coated in a seasoned flour or batter, which is then deep-fried or pan-fried until golden brown and crispy. The result is tender, juicy meat on the inside with a flavorful, crunchy crust on the outside, making it a popular and beloved comfort food known for its satisfying texture and savory taste.',
  ARRAY[
    '1 lbs. chicken cut into individual pieces',
    '0.33 tablespoon salt',
    '1 cups cooking oil',
    '0.33 cup all-purpose flour',
    '0.25 cup evaporated milk',
    '0.33 Knorr Chicken Cube',
    '1 egg',
    '0.25 cups all-purpose flour',
    '0.33 teaspoon baking powder',
    '0.67 teaspoons garlic powder',
    '0.17 teaspoon salt',
    '0.08 teaspoon ground black pepper'
  ],
  ARRAY[
    'Rub salt all over the chicken. Let it stay for 15 minutes.',
    'Heat the oil in a cooking pot.',
    'Prepare the batter. Start by pressing a fork on the chicken cube until it is completely squashed. Combine it with warm milk. Stir until well blended. Set aside.',
    'Combine flour, baking powder, garlic powder, salt, and ground black pepper. Mix well using a fork or a wire whisk. Set aside.',
    'Beat the eggs in a large mixing bowl. Add the milk mixture. Continue to beat until all the ingredients are all incorporated. Add half of flour mixture. Whisk. Add the remaining half and whisk until the texture of the batter becomes smooth.',
    'Dredge the chicken in flour and then dip in batter. Roll it again in flour until completely covered. Fry in medium heat for 7 minutes per side.',
    'Remove from the pot and put in a plate lined with paper towel. This will absorb the oil.',
    'Serve with ketchup or gravy.'
  ],
  'Eggs, Dairy',
  ARRAY['Balance Diet', 'High Protein', 'Gluten-Free', 'Flexitarian'],
  180,
  ''
),

(
  'Sinabawang Corned Beef',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sinabawang_corned_beef.png',
  'Sinabawang corned beef or corned beef soup is a perfect dish to make using your canned corned beef. Instead of preparing corned beef as a sautéed dish with onions and garlic or guisado, you can simply add some water and seasoning this time to turn it into a comforting soup.',
  ARRAY[
    '3.83 ounces corned beef Canned',
    '0.33 yellow onion',
    '0.33 potato',
    '0.08 cup parsley chopped',
    '0.67 cups water',
    '0.67 cloves garlic crushed and minced',
    '1 tablespoons cooking oil',
    'Salt and pepper to taste'
  ],
  ARRAY[
    'Heat oil in a pan',
    'Sauté garlic and onion until the texture gets soft',
    'Add the corned beef. Stir and continue to cook for 3 minutes.',
    'Slide the potato into the pan. Cook for 5 minutes while stirring once in a while.',
    'Pour water. Let boil. Adjust the heat to low and then continue cooking until the liquid reduces to half.',
    'Stir-in half the parsley. Note: you can add more water if you want your dish to be soupy.',
    'Add salt and pepper to taste.',
    'Transfer to a serving bowl. Top with remaining parsley.',
    'Serve.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  75,
  ''
),

(
  'Dinakdakan',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/dinakdakan.png',
  'Dinakdakan, or warek-warek, is rooted in Ilocano cuisine from the Ilocos region in the Philippines. Its name comes from the Ilocano term "dakad," meaning "to shake" or "to mix." Traditionally, this refers to the method of mixing grilled pig parts with various seasonings and ingredients, which are vigorously tossed together.',
  ARRAY[
    '0.17 lb. pig ears',
    '0.17 lb. pig face maskara',
    '1 ounces pig liver',
    '0.17 teaspoon ginger powder',
    '0.17 red onion sliced',
    '1 chili peppers chopped',
    '0.67 tablespoons white vinegar',
    '0.17 teaspoon garlic powder optional',
    '0.17 teaspoon ginger minced (optional)',
    '0.5 pieces bay leaves optional',
    '0.17 tablespoon whole peppercorn optional',
    '0.08 cup mayonnaise',
    '1.33 cups water',
    'Salt and pepper to taste'
  ],
  ARRAY[
    'Pour 6 to 8 cups water in a cooking pot. Let boil.',
    'Once the water starts to boil, you have the option to add dried bay leaves and whole peppercorn. Add-in the pig ears and face. Set the heat to low and continue to boil for 50 to 60 minutes.',
    'Discard the water and let the excess water drip. Rub a little bit of salt all over the boiled ears and face. Rub the ginger powder on the liver.',
    'Heat-up the grill. Grill the ears and face for 4 to 6 minutes per side or until it turns a bit crisp, but not burnt. Grill the liver for 5 to 8 minutes depending on the thickness.',
    'Remove the grilled pig parts from the grill. Let it cool down and start chopping into bite-size pieces.',
    'Meanwhile, combine mayonnaise and vinegar in mixing bowl. Stir.',
    'Add some ground black pepper. Continue to stir until the ingredients are well blended.',
    'Add the ginger, chili, onion, and garlic powder (optional). Toss.',
    'Transfer to a serving bowl. Serve.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  150,
  ''
),

(
  'Tortang Dulong',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/tortang_dulong.jpg',
  'Tortang Dulong or silverfish omelet is simple yet tasty fish omelet dish. This omelet dish is as simple as the other omelet dishes that we have except that we are now using fish as part of the ingredient.',
  ARRAY[
    '0.75 tablespoons canola oil',
    '0.5 cloves garlic. peeled and minced',
    '0.25 small onion, peeled and chopped',
    '0.25 Roma tomato, chopped',
    '0.5 cups silverfish, drained well',
    '1 eggs',
    'salt and pepper to taste',
    '0.5 tablespoons flour',
    '0.5 tablespoons green onions, chopped'
  ],
  ARRAY[
    'In a pan over medium heat, heat about 1 tablespoon oil. Add onions and garlic and cook until softened.',
    'Add tomatoes and cook for about 1 to 2 minutes or until slightly softened.',
    'Add silverfish and cook for about 1 to 2 minutes or until heated through. Drain mixture VERY well.',
    'In a bowl, add eggs and whisk until well beaten. Season with salt and pepper to taste.',
    'Add flour and stir until smooth.',
    'Add fish mixture and green onions. Stir until just combined.',
    'In a wide, nonstick skillet over medium heat, heat another 2 tablespoons oil and swirl around to fully coat bottom of the pan.',
    'Add about ½ cup of egg mixture and cook for about 1 to 2 minutes or until eggs begin to set and lightly brown. Using a spatula, gently flip to the other side. Continue to cook for another 1 minute or until both sides are lightly browned.',
    'Remove from pan. Repeat with the remaining egg mixture. Serve hot.'
  ],
  'Eggs, Fish',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Low-Fat', 'Pescatarian'],
  90,
  ''
),

(
  'Ginataang Tulingan',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/ginataang_tulingan.png',
  'Ginataang Tulingan is a Filipino dish wherein fish is cooked in coconut milk along with eggplant and other ingredients. The fish used in this recipe is locally referred to as tulingan. It is also known as bullet tuna or bonito.',
  ARRAY[
    '1 tulingan',
    '0.75 ounces pork fat sliced',
    '0.5 cups coconut milk',
    '2.5 pieces kamias (bilimbi)',
    '0.75 thumbs ginger julienne',
    '1.25 pieces Thai chili pepper',
    '0.25 piece eggplant sliced',
    '0.25 piece onion sliced',
    '1.25 cloves garlic crushed and minced',
    '0.25 teaspoon patis',
    '0.44 cups water',
    'Salt and ground black pepper to taste'
  ],
  ARRAY[
    'Clean the fish thoroughly. Create a slit on both sides and rub salt all over. Let it stay for 10 to 15 minutes.',
    'Arrange pork fat, kamias, fish, and ginger. Pour water. Cover and let boil. Continue to cook in medium heat for 40 minutes.',
    'Pour coconut milk into the pot. Add garlic, onion, and chili. Cover and continue to boil for another 40 minutes using between low to medium heat.',
    'Add eggplant. Cook for 5 to 7 minutes. Season with patis and ground black pepper.',
    'Transfer to a serving plate and serve.'
  ],
  'Fish',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Low-Fat', 'Pescatarian'],
  180,
  ''
),

(
  'Pork Kilawin',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/pork_kilawin.png',
  'It''s no secret that vinegar can make for a magical addition to most recipes including meat. That sharpness in flavor is something we can count on from this essential component. Of course, us Filipinos have learned to take advantage of this. And we can see that clearly in the simply delicious Pork Kilawin dish!',
  ARRAY[
    '0.25 lb pork belly',
    '0.5 cucumbers sliced',
    '0.5 tomatoes (optional)',
    '0.25 red onion sliced',
    '0.75 pieces chili pepper chopped',
    '0.19 cup white vinegar (sauce ingredients)',
    '0.5 teaspoons soy sauce (sauce ingredients)',
    '0.5 teaspoons white sugar (sauce ingredients)',
    '0.06 teaspoon salt (sauce ingredients)',
    '0.06 teaspoon ground black pepper (sauce ingredients)',
    '0.13 cup soy sauce (marinade ingredients)',
    '0.06 cup banana ketchup (marinade ingredients)',
    '0.25 head garlic (marinade ingredients)',
    '0.13 lemon (marinade ingredients)',
    '0.25 teaspoon onion powder (marinade ingredients)',
    '0.13 teaspoon salt (marinade ingredients)',
    '0.06 teaspoon ground black pepper (marinade ingredients)'
  ],
  ARRAY[
    'Combine all the marinade ingredients in a bowl. Mix well. Add the pork belly. Marinate for at least 3 hours.',
    'Grill the pork belly until fully cooked. Slice it into serving pieces. Set aside.',
    'Combine all the sauce ingredients in a large mixing bowl. Add the sliced pork, cucumber, tomato, onion, and chili pepper. Toss until well blended.',
    'Transfer to a serving plate. Serve.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  200,
  ''
),

(
  'Balbacua',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/balbacua.png',
  'Mindanao. Balbacua is a delightful Filipino dish that is most popular in those areas of the Philippines. And so if you are not familiar with this, just imagine a warm, truly delicious mix of Pochero and Kare Kare. Our savory Balbacua also has a bit of a milder flavor that is not too salty, but counts on the richness of the tomato sauce to give it depth.',
  ARRAY[
    '0.83 lbs. cow trotters',
    '0.17 Knorr Beef Cube',
    '0.17 bunch lemongrass (white part) cut in 4-inch pieces',
    '0.17 bell pepper sliced',
    '0.5 tablespoons salted black beans',
    '0.17 bunch green onions cut in 2-inch pieces',
    '0.5 Jalapeno pepper',
    '0.17 teaspoon ground black pepper',
    '1.33 ounces tomato sauce',
    '1.67 cups water',
    '0.33 teaspoons annatto powder',
    '0.83 cloves garlic crushed',
    '0.17 onion chopped',
    '0.33 knobs ginger crushed',
    'Fish sauce to taste',
    '0.5 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat oil in a pan. Sauté garlic, onion, and ginger until the onion softens. Set aside.',
    'Combine trotters, 10 cups water, ground black pepper, and lemongrass in a cooking pot. Let it boil. Adjust the stove to the lowest heat setting and then simmer for 3 hours or until the meat and fibers on the trotters soften.',
    'Remove the lemongrass. Add the annatto powder, sauteed aromatics (onion, garlic, and ginger), salted black beans, and Knorr Beef Cube. Continue cooking for 30 minutes.',
    'Add jalapeno, bell pepper, and green onions. Cook for 10 minutes and then serve.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  250,
  ''
),

(
  'Humba',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/humba.jpg',
  'Pork Humba with pineapple, tausi, and dried banana blossoms is a delicious medley of sweet and savory flavors you''ll love with steamed rice! This Visayan version of adobo is easy to make and sure to be a family favorite.',
  ARRAY[
    '0.34 kg pork belly, cut into 1-½ inch cubes',
    '14.79 ml vinegar',
    '29.57 ml soy sauce',
    '59.15 ml pineapple juice',
    '3.7 ml oil',
    '0.25 small onion, peeled and sliced thinly',
    '1.5 cloves garlic, peeled and minced',
    '1.1 g peppercorns',
    '0.5 bay leaves',
    '0.25 can (6 ounces) tausi (salted black beans), drained and rinsed',
    '59.15 g pineapple chunks',
    '0.25 package (1 ounce) dried banana blossoms',
    '3 g brown sugar',
    'salt to taste'
  ],
  ARRAY[
    'In a bowl, combine pork, vinegar, soy sauce, and pineapple juice. Marinate in the refrigerator for about 30 minutes. Drain meat from marinade, reserving liquid.',
    'In a wide pot over medium heat, heat oil. Add onions and garlic and cook, stirring occasionally, until limp.',
    'Add pork belly and cook, stirring occasionally, until lightly browned.',
    'Add reserved marinade and bring to a boil without stirring for about 2 to 3 minutes.',
    'Add peppercorns and bay leaf.',
    'Add tausi, pineapple chunks, and banana blossoms. Stir to combine.',
    'Lower heat, cover, and simmer until pork is tender.',
    'Add brown sugar and stir until dissolved. Season with salt to taste.',
    'Continue to cook until liquid is reduced and begins to render fat. Serve hot.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  220,
  'You''ll use the liquid in the pineapple can to braise the meat, so make sure the fruit is packed in juice and not heavy syrup.

Do not marinate the meat for an extended period, as the acidity of the vinegar and pineapple juice will break down the meat''s protein fibers, altering the texture.

Rinse the tausi and drain well; they''re usually packed in salty brine.'
),

(
  'Pork Estofado',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/pork_estufado.jpeg',
  'Pork Estofado is a stewed pork dish served with fried plantains. This pork recipe is comparable to pork adobo but, the use of carrots and fried plantains provide distinction to this dish. Filipinos, love to have our share of meaty pork with a thick, hot stew filled with a variety of vegetables and seasonings.',
  ARRAY[
    '0.5 lbs pork cubed',
    '0.5 pieces dried bay leaves',
    '0.17 tablespoon whole peppercorn',
    '0.25 cup carrot sliced',
    '0.67 plantains sliced diagonally (1 inch thick)',
    '0.08 cup vinegar',
    '0.13 cup soy sauce',
    '0.5 tablespoons brown sugar',
    '0.17 cup water',
    '0.83 tablespoons garlic minced',
    '0.17 cup cooking oil'
  ],
  ARRAY[
    'Heat a frying pan and pour 3/4 cups of cooking oil.',
    'When the oil is hot enough, fry the sliced plantains until the color of each side turns medium to dark brown. Set aside.',
    'Pour 1/4 cup of cooking oil in a separate cooking pot then apply heat.',
    'When the oil is hot enough, put-in the garlic and sauté until the color turns light brown.',
    'Add the cubed pork and cook for 7 to 10 minutes.',
    'Put-in the soy sauce, water, whole peppercorns, and dried bay leaves then bring to a boil. Simmer until pork is tender.',
    'Add vinegar and wait for the liquid to re-boil. Simmer for 5 minutes.',
    'Add brown sugar and carrots. Stir then simmer for 10 minutes more.',
    'Turn off the heat and transfer the contents of the cooking pot to a serving plate.',
    'Garnish with fried bananas then serve.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  190,
  ''
),

(
  'Adobong Puti',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/adobong_puti.jpg',
  'Adobong Puti is made of pork belly stewed in vinegar, salt, and spices. This white version of adobo is hearty, full of flavor, and pairs well with steamed rice. It''s easy to make and cooks in one pot.',
  ARRAY[
    '9.86 ml canola oil',
    '0.33 onion, peeled and sliced thinly',
    '0.33 head garlic, peeled and minced',
    '0.45 kg pork belly',
    '78.86 ml vinegar',
    '118.29 ml water',
    '6 g salt',
    '1 bay leaves',
    '1.47 g peppercorns, cracked',
    '1.33 g sugar',
    'fried garlic bits, optional'
  ],
  ARRAY[
    'In a wide, heavy-bottomed pan over medium heat, heat oil. Add onions and garlic and cook, stirring regularly, until softened.',
    'Add pork and cook until lightly browned.',
    'Add vinegar and bring to a boil, uncovered and without stirring, for about 3 to 5 minutes.',
    'Add water, salt, bay leaves, and peppercorns. Stir to combine. Continue to boil for about 3 to 5 minutes.',
    'Lower heat, cover, and continue to cook for about 40 to 50 minutes or until meat is fork-tender and liquid is reduced.',
    'Add sugar and stir. Continue to cook, uncovered, until mixture begins to render fat.',
    'Sprinkle with fried garlic bits as desired and serve hot.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  180,
  'Cut the meat in uniform size to ensure even cooking.

Sear the meat until lightly browned to enhance flavor and add color.

Allow the vinegar to boil uncovered and without stirring before adding the water to cook off the strong acid taste.

Don''t skip the sugar! The sweetness helps balance the acidity and saltiness of the dish.'
),

(
  'Sinigang Sa Miso',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sinigang_sa_miso.jpg',
  'Sinigang sa Miso is a type of Filipino sour soup dish. It is a variation of the popular Sinigang. This version features miso paste. Sinigang sa Miso typically includes fish, mixed with vegetables like tomatoes, onions, and leafy greens. The broth is flavored with souring agents, while the miso paste adds a rich taste.',
  ARRAY[
    '1 lbs. bangus milkfish cleaned and sliced',
    '12.5 g Maggi Magic Sinigang sa Sampaloc',
    '0.5 bunch fresh kangkong leaves',
    '6 string beans cut into 2 inch pieces',
    '5 okra',
    '2 pieces long green pepper',
    '1 tomatoes wedged',
    '1 tablespoons miso',
    '0.5 yellow onion wedged',
    'Fish sauce and ground black pepper to taste',
    '1 teaspoons salt',
    '1 quarts water',
    '1.5 tablespoons cooking oil'
  ],
  ARRAY[
    'Rub salt all over the fish. Let it stay for 10 minutes.',
    'Heat oil in a pot. Fry each side of the fish for 1 1/2 minutes. Remove the fish from the pot and set it aside.',
    'Using the remaining oil, add onion and half of the tomato, and miso. Saute for 2 minutes.',
    'Put the fish back into the pot and then pour water. Let it boil.',
    'Cover and cook using low to medium heat setting for 10 minutes,',
    'Add Maggi Magic Sinigang sa Sampaloc. Stir. Cook for 2 minutes.',
    'Add long green pepper, string beans, and okra. Stir. Cover and cook for 5 to 7 minutes.',
    'Add fish sauce and ground black pepper. Stir.',
    'Put the kangkong leaves into the pot. Cover the pot and turn the heat off. Let it stay for 5 minutes.',
    'Transfer to a serving bowl. Serve and enjoy the dish!'
  ],
  'Fish',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Low-Fat', 'Pescatarian'],
  160,
  ''
),

(
  'Chicken Pochero',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/chicken_pochero.jpeg',
  'Chicken Pochero is a type of stew composed of chicken, sausage, vegetables, plantains, and tomatoes. The harmonious collaboration of different flavors makes this dish extra special.',
  ARRAY[
    '181.44 g Chicken cut into serving pieces',
    '0.2 piece Knorr Chicken Cube',
    '0.4 pieces potato cubed',
    '0.4 bunches baby bok choy',
    '0.1 head cabbage sliced',
    '45.36 g tomato sauce',
    '3.6 pieces long green beans',
    '0.4 pieces Chorizo de Bilbao sliced',
    '45.36 g chick pea',
    '0.6 pieces Saba banana sliced',
    '0.4 pieces tomato diced',
    '0.2 piece onion chopped',
    '0.8 cloves garlic crushed',
    '100 g water',
    '0.6 tablespoons cooking oil',
    'Fish sauce and crushed peppercorn to taste'
  ],
  ARRAY[
    'Heat oil in a cooking pot. Pan-fry the chicken for 2 minutes per side. Set aside.',
    'Using the remaining oil, saute onion and garlic.',
    'Add chorizo. Saute for 1 minute.',
    'Add tomato. Continue to saute until onion and tomato softens.',
    'Put the pan-fried chicken back into the pot. Stir.',
    'Pour tomato sauce and water.Let boil.',
    'Add Knorr Chicken Cube. Stir and cover the pot. Cook in medium heat for 15 minutes.',
    'Put potato, saba banana, and chick pea into the pot. Cover and cook for 12 minutes.',
    'Add long green beans and cabbage. Cover and cook for 3 minutes.',
    'Add bok choy. Cook for 2 minutes. Season with crushed peppercorn and fish sauce. Stir.',
    'Transfer to a serving bowl and enjoy the meal!'
  ],
  'Wheat/Gluten',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Flexitarian'],
  200,
  ''
),

(
  'Sweet Pork Adobo',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/sprite_pork_adobo.jpeg',
  'One of my favorite adobo recipes is Sprite Pork Adobo. It is a sweet Filipino Adobong Baboy version wherein lemon or lime soda pop such as Sprite is used instead of adding sugar to add sweetness to the dish.',
  ARRAY[
    '181.44 g pork belly cubed',
    '1.4 tablespoons soy sauce',
    '0.8 tablespoons white vinegar',
    '0.2 can Sprite or similar soda pop',
    '0.2 piece onion minced',
    'dried bay leaves',
    '0.3 teaspoons whole peppercorn',
    '1 cloves garlic crushed',
    '25 g water',
    '0.6 tablespoons cooking oil'
  ],
  ARRAY[
    'In a large bowl, combine soy sauce and Sprite with the pork belly. Mix well. Cover the bowl and refrigerate. Let the pork marinate for at least 6 hours.',
    'Using a kitchen sieve, drain the marinade out of the bowl. Set it aside.',
    'Heat oil in a cooking pot',
    'Once the oil becomes hot, saute garlic until light brown',
    'Add onion. Continue to saute until soft',
    'Add pork belly. Stir and cook until light brown',
    'Pour the marinade (Sprite and soy sauce). Cover the pot and let boil.',
    'Add whole peppercorn and dried bay leaves. Cover the pot and continue to cook for 30 minutes in medium heat.',
    'Pour vinegar into the pot. Let the liquid re-boil. Stir. Cover and cook for 25 to 30 minutes. Note: add water if needed.',
    'Transfer to a serving plate. Serve with rice.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  140,
  ''
),

(
  'Pork Caldereta',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/pork_caldereta.jpeg',
  'Pork Caldereta is a Filipino tomato based stew. It is composed of cubed pork , potato, carrots, tomato sauce,and liver spread. As such, did you know that our favorite Caldereta is actually a local adaptation of a Spanish dish? But like many of the recipes we''ve grown to love and adopt in our cuisine, this dish has faced many adjustments. And not only is it fitted to our local palate, but it''s also used ingredients more accessible to us, hence the birth of Pork Caldereta.',
  ARRAY[
    '0.4 lbs. Pork sliced into cubes',
    '0.2 piece Knorr Pork cube',
    '1.6 oz. tomato sauce',
    '20.25 g green olives',
    '0.2 piece red bell pepper sliced',
    '0.2 piece green bell pepper sliced',
    '0.4 pieces potatoes cubed',
    '0.4 pieces carrot sliced',
    '0.2 piece onion chopped',
    '0.6 cloves garlic chopped',
    '70.98 g water',
    '23.66 g liver spread',
    '0.6 tablespoons cooking oil',
    'Salt and ground black pepper to taste'
  ],
  ARRAY[
    'Heat the oil in a cooking pot.',
    'Once the oil gets hot, saute the garlic and onion.',
    'Add the pork. Saute until the color turns light brown.',
    'Pour-in the tomato sauce and water. Let boil. Cover and cook in low heat for 60 minutes.',
    'Add the liver spread. Stir and cook for 3 minutes.',
    'Put-in the potato and carrot. Cover and cook for 8 to 10 minutes.',
    'Add the olives and bell peppers. Cook for 5 minutes.',
    'Season with salt and ground black pepper.',
    'Turn-off the heat. Transfer to a serving plate.'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  210,
  ''
),

(
  'Pork Kaldereta sa Gata',
  'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/recipes/pork_caldereta_sa_gata.jpeg',
  'Pork Kalderera sa Gata is a crossover between two famous Filipino dishes, kaldereta and ginataan. Pork belly that were cut into cubes are sautéed in garlic, onions, and ripe tomatoes. It is then stewed in a mixture of broth and coconut milk.',
  ARRAY[
    '226.79 g Pork belly sliced into cubes',
    '1 tablespoons liver spread',
    '1.5 pieces tomato chopped',
    '0.25 piece onion chopped',
    '1.25 cloves garlic crushed',
    '117.5 g pork broth',
    '113 g coconut milk',
    '0.5 pieces potato cubed',
    '0.5 pieces carrot cubed',
    '0.25 piece green bell pepper chopped',
    '0.25 piece red bell pepper chopped',
    '0.75 pieces Thai chili pepper',
    '0.75 pieces dried bay leaves',
    '117.5 g pork broth',
    '0.63 tablespoons fish sauce',
    '0.06 teaspoon crushed black pepper',
    '0.75 tablespoons cooking oil'
  ],
  ARRAY[
    'Heat oil in a pan.',
    'Sauté garlic until color turns light brown.',
    'Add chopped onion. Cook until soft.',
    'Add pork belly slices. Sauté until outer part turns light brown.',
    'Put the chopped ripe tomatoes into the pan. Cook until soft.',
    'Pour pork broth into the pan. Let boil.',
    'Add chopped Thai chili, liver spread, and dried bay leaves.',
    'Pour coconut milk. Stir and cover and cook between low to medium heat for 45 to 60 minutes or until tender. Note: add more broth or water if needed.',
    'Put-in carrots and potato and cook for 7 minutes.',
    'Add bell peppers. Cook for 7 to 8 minutes.',
    'Season with fish sauce and crushed whole peppercorn. Continue to cook until sauce thickens.',
    'Transfer to a serving plate. Share and enjoy!'
  ],
  'None',
  ARRAY['Balance Diet', 'High Protein', 'Dairy-Free', 'Gluten-Free', 'Flexitarian'],
  240,
  'Take your time when tenderizing the meat. There is nothing like having a melt-in-your-mouth kinda tender pork belly.

This is best enjoyed with warm white rice.'
);
