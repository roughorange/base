# Stage 1: Build Stage
FROM node:18 as build

# Set working directory
WORKDIR /app

# Copy package.json and yarn.lock to install dependencies
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install

# Copy the rest of the app files (src, index.html, etc.)
COPY . .

# Build the frontend (Vite outputs to the dist/ directory)
RUN yarn build

# Stage 2: Final Stage (Serve with Nginx)
FROM nginx:alpine

# Copy the build artifacts from the build stage (use dist/ instead of build/)
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80 for the Nginx server
EXPOSE 80

# Start the Nginx server
CMD ["nginx", "-g", "daemon off;"]
