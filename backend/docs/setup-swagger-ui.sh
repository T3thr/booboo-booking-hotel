#!/bin/bash

# Setup Swagger UI for Hotel Booking System API Documentation

echo "Setting up Swagger UI..."

# Create swagger-ui directory
mkdir -p backend/docs/swagger-ui

# Download Swagger UI
echo "Downloading Swagger UI..."
SWAGGER_UI_VERSION="5.10.0"
curl -L "https://github.com/swagger-api/swagger-ui/archive/refs/tags/v${SWAGGER_UI_VERSION}.tar.gz" -o swagger-ui.tar.gz

# Extract only the dist folder
echo "Extracting Swagger UI..."
tar -xzf swagger-ui.tar.gz "swagger-ui-${SWAGGER_UI_VERSION}/dist" --strip-components=2 -C backend/docs/swagger-ui

# Clean up
rm swagger-ui.tar.gz

# Update swagger-initializer.js to point to our spec
cat > backend/docs/swagger-ui/swagger-initializer.js << 'EOF'
window.onload = function() {
  window.ui = SwaggerUIBundle({
    url: "/docs/swagger.yaml",
    dom_id: '#swagger-ui',
    deepLinking: true,
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    plugins: [
      SwaggerUIBundle.plugins.DownloadUrl
    ],
    layout: "StandaloneLayout"
  });
};
EOF

echo "Swagger UI setup complete!"
echo "To view the documentation:"
echo "1. Start the backend server: cd backend && go run cmd/server/main.go"
echo "2. Open your browser to: http://localhost:8080/docs"
