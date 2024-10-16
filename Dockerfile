# Use the tiangolo/uvicorn-gunicorn-fastapi image as the base image
FROM tiangolo/uvicorn-gunicorn-fastapi:python3.9

# Set the working directory to /app
WORKDIR /app

# Copy the requirements file into the container
COPY ./requirements.txt /app/requirements.txt

# Install dependencies
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

# Copy the application code
COPY ./app /app

# Expose port 80 (default port in the base image)
EXPOSE 80

# The base image automatically starts the app using Gunicorn and Uvicorn
