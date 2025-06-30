import pandas as pd
import re

# Load mapping CSV
mapping_csv = '/Volumes/dummy_catalog/dummy_schema/ad/Category,Redshift_function,Databricks_function,Us... - Category,Redshift_function,Databricks_function,Us....csv'  # your mapping file
mapping = pd.read_csv(mapping_csv)

# Build a replacement dictionary: Redshift function pattern -> Databricks replacement
replacements = []
for _, row in mapping.iterrows():
    redshift_func = str(row['Redshift_function']).strip()
    databricks_func = str(row['Databricks_function']).strip()
    redshift_usage = str(row['Use in Redshift']).strip()
    databricks_usage = str(row['Use in Databricks']).strip()
    if redshift_func and databricks_func and redshift_usage and databricks_usage:
        # Build a regex pattern for the function usage
        pattern = re.escape(redshift_usage).replace(r'\(', r'\(').replace(r'\)', r'\)').replace(r'\\', r'\\')
        replacements.append((pattern, databricks_usage))

# Read Redshift SQL file
with open('/Volumes/dummy_catalog/dummy_schema/ad/redhshift_mapping.sql', 'r') as f:
    redshift_sql = f.read()

databricks_sql = redshift_sql

# Function-level replacements (simple and robust for most cases)
for pattern, replacement in replacements:
    # Use regex to replace function usage, case-insensitive
    databricks_sql = re.sub(pattern, replacement, databricks_sql, flags=re.IGNORECASE)

# Manual adjustments for array and CASE/DECODE, if needed
databricks_sql = databricks_sql.replace('ARRAY[', 'array(').replace(']', ')')
databricks_sql = re.sub(r'ARRAY_FLATTEN\s*\(', 'flatten(', databricks_sql, flags=re.IGNORECASE)
databricks_sql = re.sub(r'SPLIT_TO_ARRAY\s*\(', 'split(', databricks_sql, flags=re.IGNORECASE)
databricks_sql = re.sub(r'NVL\s*\(', 'nvl(', databricks_sql, flags=re.IGNORECASE)
databricks_sql = re.sub(r'LISTAGG\s*\(', 'listagg(', databricks_sql, flags=re.IGNORECASE)
databricks_sql = re.sub(r'GREATEST\s*\(', 'greatest(', databricks_sql, flags=re.IGNORECASE)
databricks_sql = re.sub(r'DECODE\s*\(', 'decode(', databricks_sql, flags=re.IGNORECASE)
databricks_sql = re.sub(r'CASE\s+WHEN', 'CASE WHEN', databricks_sql, flags=re.IGNORECASE)  # CASE is compatible

# Clean up any lingering Redshift-specific array syntax
databricks_sql = re.sub(r'array\(([^)]+)\)', lambda m: 'array({})'.format(','.join(x.strip() for x in m.group(1).split(','))), databricks_sql)

# Output the Databricks SQL
with open('databricks_transpiled.sql', 'w') as f:
    f.write(databricks_sql)

print("Transpilation complete! See 'databricks_transpiled.sql' for the converted SQL.")
