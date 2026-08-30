import os
from fastapi import FastAPI, APIRouter

app = FastAPI()
api_router = APIRouter()

@api_router.get("/")
def read_root():
    return {"message": "Hello from ephemeral environment!"}

@api_router.get("/health")
def health_check():
    return {"status": "healthy"}

# Read prefix from ECS environment variable (e.g. "/pr-5"), default to ""
route_prefix = os.getenv("ROUTE_PREFIX", "")
app.include_router(api_router, prefix=route_prefix)
