@echo off
REM Setup Swagger UI for Hotel Booking System API Documentation

echo Setting up Swagger UI...

REM Create swagger-ui directory
if not exist "backend\docs\swagger-ui" mkdir backend\docs\swagger-ui

REM Download Swagger UI
echo Downloading Swagger UI...
set SWAGGER_UI_VERSION=5.10.0
curl -L "https://github.com/swagger-api/swagger-ui/archive/refs/tags/v%SWAGGER_UI_VERSION%.tar.gz" -o swagger-ui.tar.gz

REM Extract (requires tar on Windows 10+)
echo Extracting Swagger UI...
tar -xzf swagger-ui.tar.gz "swagger-ui-%SWAGGER_UI_VERSION%/dist" --strip-components=2 -C backend\docs\swagger-ui

REM Clean up
del swagger-ui.tar.gz

REM Update swagger-initializer.js
echo window.onload = function() { > backend\docs\swagger-ui\swagger-initializer.js
echo   window.ui = SwaggerUIBundle({ >> backend\docs\swagger-ui\swagger-initializer.js
echo     url: "/docs/swagger.yaml", >> backend\docs\swagger-ui\swagger-initializer.js
echo     dom_id: '#swagger-ui', >> backend\docs\swagger-ui\swagger-initializer.js
echo     deepLinking: true, >> backend\docs\swagger-ui\swagger-initializer.js
echo     presets: [ >> backend\docs\swagger-ui\swagger-initializer.js
echo       SwaggerUIBundle.presets.apis, >> backend\docs\swagger-ui\swagger-initializer.js
echo       SwaggerUIStandalonePreset >> backend\docs\swagger-ui\swagger-initializer.js
echo     ], >> backend\docs\swagger-ui\swagger-initializer.js
echo     plugins: [ >> backend\docs\swagger-ui\swagger-initializer.js
echo       SwaggerUIBundle.plugins.DownloadUrl >> backend\docs\swagger-ui\swagger-initializer.js
echo     ], >> backend\docs\swagger-ui\swagger-initializer.js
echo     layout: "StandaloneLayout" >> backend\docs\swagger-ui\swagger-initializer.js
echo   }); >> backend\docs\swagger-ui\swagger-initializer.js
echo }; >> backend\docs\swagger-ui\swagger-initializer.js

echo Swagger UI setup complete!
echo To view the documentation:
echo 1. Start the backend server: cd backend ^&^& go run cmd/server/main.go
echo 2. Open your browser to: http://localhost:8080/docs
pause
