import os
from fastapi import FastAPI
root_path = os.getenv("ROOT_PATH", "")
app = FastAPI(root_path=root_path	)

@app.get("/")
def read_root():
    return {"message": "Version 2.0 - PR Preview Test"}

@app.get("/health")
def health_check():
    return {"status": "OK"}

@app.get("/version")
def get_version():
    return {"version": "1.0.0"}

@app.get("/info")
def get_info():
    return {"app": "demo-service", "description": "Ephemeral environment preview app"}
