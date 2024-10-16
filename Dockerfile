# Stage 1: Build the React frontend
FROM node:18 AS frontend-builder

# Set working directory
WORKDIR /app/frontend

# Create a new React app
RUN npx create-react-app . --template cra-template

# Build the React app
RUN npm run build

# Stage 2: Build the FastAPI backend
FROM tiangolo/uvicorn-gunicorn-fastapi:python3.9

# Install Node.js and npm
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Set working directory
WORKDIR /app

# Copy Python requirements
COPY ./requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy FastAPI app
COPY ./app /app

# Copy the built frontend from Stage 1
COPY --from=frontend-builder /app/frontend/build /app/frontend/build

# Expose port 80
EXPOSE 80

# The base image automatically starts the app
