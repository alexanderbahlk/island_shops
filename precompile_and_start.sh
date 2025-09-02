#!/bin/bash

# This script will precompile assets and start the Rails server.

# Step 1: Precompile assets
echo "Precompiling assets..."
rake assets:precompile

if [ $? -eq 0 ]; then
  echo "Assets precompiled successfully."
else
  echo "Failed to precompile assets."
  exit 1
fi

# Step 2: Start the Rails server
echo "Starting Rails server..."
rails s
