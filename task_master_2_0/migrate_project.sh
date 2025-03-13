#!/bin/bash

# Create a new project with the correct structure
echo "Creating new Flutter project..."
cd ..
flutter create -t app task_master_2_0_new

# Create a backup of the old project
echo "Creating backup of old project..."
cp -r task_master_2_0 task_master_2_0_backup

# Copy Dart code
echo "Copying Dart code..."
cp -r task_master_2_0/lib/* task_master_2_0_new/lib/

# Copy assets if they exist
if [ -d "task_master_2_0/assets" ]; then
  echo "Copying assets..."
  mkdir -p task_master_2_0_new/assets
  cp -r task_master_2_0/assets/* task_master_2_0_new/assets/
fi

# Transfer pubspec.yaml content
echo "Transferring pubspec.yaml configuration..."
# We'll manually merge the pubspec files to avoid overwriting Flutter's defaults

echo "Migration complete!"
echo "IMPORTANT: You need to manually merge the dependencies from the old pubspec.yaml to the new one."
echo "Old project backup is at: task_master_2_0_backup"
echo "New project is at: task_master_2_0_new"
