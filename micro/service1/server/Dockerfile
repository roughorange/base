# Stage 1: Build Stage
FROM python:3.10-slim as build

# Set the working directory
WORKDIR /app

# Copy requirements.txt to install dependencies
COPY requirements.txt ./

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Stage 2: Runtime Stage
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Copy dependencies from the build stage
COPY --from=build /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages

# Copy the application code from the build stage
COPY --from=build /app /app

# Expose the default Django port
EXPOSE 8000

# Start the Django development server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
