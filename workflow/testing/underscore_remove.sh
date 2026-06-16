# Loop through all files containing an underscore
for file in *_*; do
    # Check if it is a regular file
    if [ -f "$file" ]; then
        # Replace the first underscore
        new_name="${file/_/}"
        # Rename the file
        mv "$file" "$new_name"
    fi
done
