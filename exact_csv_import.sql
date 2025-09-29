-- Create table with EXACT CSV column names
-- This will match your CSV headers perfectly

DROP TABLE IF EXISTS nutrition_data_import;

CREATE TABLE nutrition_data_import (
  "Food_ID" TEXT,
  "Food_name_and_Description" TEXT,
  "Scientific_name" TEXT,
  "Alternate_Common_names" TEXT,
  "Edible_portion" TEXT,
  "Option" TEXT,
  "Proximates_Water_g" TEXT,
  "Proximates_Energy_calculated_kcal" TEXT,
  "Proximates_Protein_g" TEXT,
  "Proximates_Total_Fat_g" TEXT,
  "Proximates_Carbohydrate_total_g" TEXT,
  "Proximates_Carbohydrate_available_g" TEXT,
  "Proximates_Ash_total_g" TEXT,
  "Other_Carbohydrate_Fiber_total_dietary_g" TEXT,
  "Other_Carbohydrate_Sugars_total_g" TEXT,
  "Minerals_Calcium_Ca_mg" TEXT,
  "Minerals_Phosphorus_P_mg" TEXT,
  "Minerals_Iron_Fe_mg" TEXT,
  "Minerals_Sodium_Na_mg" TEXT,
  "Vitamins_Retinol_Vitamin_A_µg" TEXT,
  "Vitamins_beta-Carotene_µg" TEXT,
  "Vitamins_Retinol_Activity_Equivalent_RAE_µg" TEXT,
  "Vitamins_Thiamin_Vitamin_B1_mg" TEXT,
  "Vitamins_Riboflavin_Vitamin_B2_mg" TEXT,
  "Vitamins_Niacin_mg" TEXT,
  "Vitamins_Ascorbic_Acid_Vitamin_C_mg" TEXT,
  "Lipids_Fatty_acids_saturated_total_g" TEXT,
  "Lipids_Fatty_acids_monounsaturated_total_g" TEXT,
  "Lipids_Fatty_acids_polyunsaturated_totalg" TEXT,
  "Lipids_Cholesterol_mg" TEXT,
  "Minerals_Potassium_K_mg" TEXT,
  "Minerals_Zinc_Zn_mg" TEXT,
  "Lipids_Caproic_C6_g" TEXT,
  "Lipids_Caprylic_C8_g" TEXT,
  "Lipids_Capric_C10_g" TEXT,
  "Lipids_Lauric_C12_g" TEXT,
  "Lipids_Myristic_C14_g" TEXT,
  "Lipids_Palmitic_C16_g" TEXT,
  "Lipids_Stearic_C18_g" TEXT,
  "Lipids_Arachidic_C20_g" TEXT,
  "Lipids_Behenic_C22_g" TEXT,
  "Lipids_Lignoceric_C24_g" TEXT,
  "Lipids_Oleic__C181_g" TEXT,
  "Lipids_Linoleic_C182_g" TEXT,
  "Lipids_Linolenic_C183_g" TEXT,
  "Vitamins_Niacin_from_Trytophan_mg" TEXT,
  "Proximates_Energy_calculated_kJ" TEXT
);

-- Enable RLS
ALTER TABLE nutrition_data_import ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Allow public read access" ON nutrition_data_import
    FOR SELECT USING (true);

SELECT 'Table created with exact CSV headers! Now import your CSV.' as message;
