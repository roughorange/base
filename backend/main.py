import sys
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello from Tactu lalala backend!", "python_version": sys.version}
