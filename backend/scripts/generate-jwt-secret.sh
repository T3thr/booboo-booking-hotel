#!/bin/bash

# Generate JWT Secret Script
# This script generates a secure random JWT secret

echo "🔐 Generating JWT Secret..."
echo ""

# Generate a 32-byte random string encoded in base64
SECRET=$(openssl rand -base64 32)

echo "✅ Your JWT Secret:"
echo ""
echo "$SECRET"
echo ""
echo "📝 Add this to your .env file:"
echo "JWT_SECRET=$SECRET"
echo ""
echo "⚠️  Keep this secret safe and never commit it to git!"
