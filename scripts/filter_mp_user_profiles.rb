import json

# Load the exported data from a JSON file
with open('exported_data.json', 'r') as file:
    data = json.load(file)

# Filter out user profiles with email as distinct_id
filtered_data = [profile for profile in data if 'email' not in profile.get('distinct_id', '')]

# Save the filtered data to a new JSON file
with open('filtered_data.json', 'w') as file:
    json.dump(filtered_data, file)