from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

app = FastAPI()

@app.get("/api/health")
async def health_check():
    return {"status": "ok"}

# Serve the React build directory
app.mount("/", StaticFiles(directory="frontend/build", html=True), name="frontend")
