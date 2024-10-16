from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
import os

app = FastAPI()

# Serve the static files (CSS, JS, etc.)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Serve the HTML file as the root route
@app.get("/", response_class=HTMLResponse)
async def read_index():
    with open("static/index.html", "r") as file:
        return file.read()
