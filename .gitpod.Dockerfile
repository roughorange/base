# Stage 1: Build Stage
FROM node:18 as build

# Install dependencies and build the frontend
WORKDIR /app
COPY frontend/package.json frontend/yarn.lock ./
RUN yarn install
COPY frontend/ ./
RUN yarn build

# Stage 2: Final Stage
FROM gitpod/workspace-full:latest

# Install runtime dependencies
RUN sudo apt-get update && sudo apt-get install -y python3 python3-pip postgresql-client

# Copy the frontend build artifacts from the build stage (use dist/ instead of build/)
COPY --from=build /app/dist /frontend/build

USER gitpod