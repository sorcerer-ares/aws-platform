from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Welcome to the AWS Developer Platform"}

@app.get("/health")
def health_check():
    return {"status": "OK"}

@app.get("/version")
def get_version():
    return {"version": "1.0.0"}

@app.get("/info")
def get_info():
    return {"app": "demo-service", "description": "Ephemeral environment preview app"}
