# Supabase Migration Guide for Nutritional Data

This guide will help you migrate your FNRI nutritional data from CSV files to Supabase for better performance and scalability.

## Prerequisites

- Python 3.7+ installed
- Access to your Supabase project
- Your CSV file: `assets/data/fnri_detailed_nutritional_data.csv`

## Step 1: Create the Database Table

1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of `create_nutrition_table.sql`
4. Run the SQL script to create the table and indexes

## Step 2: Install Python Dependencies

```bash
pip install -r requirements.txt
```

## Step 3: Import CSV Data to Supabase

Run the import script:

```bash
python import_nutrition_data.py
```

This script will:
- Parse your CSV file
- Upload the data to Supabase in batches
- Handle duplicates and data validation
- Provide progress updates

## Step 4: Verify the Migration

1. Check your Supabase dashboard to see the imported data
2. Run a test query to ensure data integrity:

```sql
SELECT COUNT(*) FROM nutrition_data;
SELECT food_name, protein_g, energy_kcal FROM nutrition_data LIMIT 5;
```

## Step 5: Update Your Flutter App

The `FNRINutritionService` has been updated to use Supabase instead of CSV files. The changes include:

- ✅ Direct Supabase queries for better performance
- ✅ Full-text search capabilities
- ✅ Fallback to cached search if Supabase is unavailable
- ✅ Improved error handling

## Benefits of Supabase Migration

### Performance Improvements
- **Faster Queries**: Database queries are much faster than parsing CSV files
- **Indexed Search**: Full-text search with proper indexing
- **Pagination**: Can handle large datasets efficiently

### Scalability
- **Concurrent Users**: Multiple users can access data simultaneously
- **Real-time Updates**: Can update nutritional data without app updates
- **Advanced Filtering**: Complex queries and filtering capabilities

### Data Management
- **Data Integrity**: Better validation and consistency
- **Backup & Recovery**: Automatic backups and point-in-time recovery
- **Analytics**: Built-in analytics and monitoring

## Testing the Migration

After migration, test these features:

1. **Search Functionality**: Try searching for ingredients like "pork", "rice", "chicken"
2. **Nutrition Calculation**: Test recipe nutrition calculations
3. **Performance**: Compare loading times before and after migration

## Troubleshooting

### Common Issues

1. **Connection Errors**: Verify your Supabase URL and API key
2. **Import Failures**: Check CSV file format and data types
3. **Search Issues**: Ensure indexes are created properly

### Fallback Strategy

The service includes a fallback mechanism:
- If Supabase is unavailable, it falls back to cached data
- If cache is empty, it will attempt to load from CSV (if still available)

## Next Steps

1. **Monitor Performance**: Track query performance and optimize as needed
2. **Add More Data**: Consider adding more nutritional databases
3. **Real-time Updates**: Set up webhooks for real-time data updates
4. **Analytics**: Use Supabase analytics to understand usage patterns

## Support

If you encounter any issues:
1. Check the Supabase logs in your dashboard
2. Verify your network connection
3. Ensure your Supabase project has sufficient resources
4. Check the Flutter app logs for error messages

## File Cleanup

After successful migration, you can optionally:
- Remove the CSV file from assets (keep a backup)
- Remove the `csv` dependency from `pubspec.yaml`
- Clean up the import scripts

Remember to test thoroughly before removing any files!
