# app/main.py

from fastapi import FastAPI

app = FastAPI(title="Speech-to-Text Prototype")

@app.get("/")
async def read_root():
    return {"message": "Welcome to the Speech-to-Text API"}
