import os
from fastapi import FastAPI, APIRouter

app = FastAPI()
api_router = APIRouter()

# 1. Base health check (Matches Target Group HealthCheckPath: /health)
@app.get("/health")
def health_check():
    return {"status": "OK"}

# 2. Preview / PR routes
@api_router.get("/")
def read_root():
    return {"message": "Hello from ephemeral environment!"}

@api_router.get("/health")
def pr_health():
    return {"status": "OK"}

# Mount the router with prefix if provided by ECS
route_prefix = os.getenv("ROUTE_PREFIX", "")
if route_prefix:
    app.include_router(api_router, prefix=route_prefix)
else:
    app.include_router(api_router)
