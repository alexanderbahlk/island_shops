#!/bin/bash

# This script will precompile assets and start the Rails server.

# Step 1: Start Redis
echo "Starting Redis..."
redis-server --daemonize yes

if [ $? -eq 0 ]; then
  echo "Redis started successfully."
else
  echo "Failed to start Redis. Ensure Redis is installed and configured correctly."
  exit 1
fi

# Step 2: Precompile assets
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
