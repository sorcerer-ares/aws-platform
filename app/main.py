import os
from fastapi import FastAPI, APIRouter

app = FastAPI()
api_router = APIRouter()

# Universal health check (never affected by ROUTE_PREFIX)
@app.get("/health")
def health_check():
    return {"status": "OK"}

# PR-specific routes
@api_router.get("/")
def read_root():
    return {"message": "Hello from ephemeral environment!"}

@api_router.get("/health")
def pr_health_check():
    return {"status": "OK"}

route_prefix = os.getenv("ROUTE_PREFIX", "")
if route_prefix:
    app.include_router(api_router, prefix=route_prefix)
else:
    app.include_router(api_router)
