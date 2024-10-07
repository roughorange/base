# Stage 1: Build Stage
FROM node:18 as build

# Set working directory
WORKDIR /app

# Copy only the package files to install dependencies
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install

# Copy the rest of the app files
COPY . .

# Build the frontend
RUN yarn build

# Stage 2: Final Stage
FROM nginx:alpine

# Copy build artifacts from the build stage
COPY --from=build /app/build /usr/share/nginx/html

# Expose the port Nginx will serve on
EXPOSE 80

# Start the Nginx server
CMD ["nginx", "-g", "daemon off;"]
