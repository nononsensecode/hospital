# app/main.py
from fastapi import FastAPI
from app.api.endpoints import patients

app = FastAPI(title="Hospital API", version="1.0.0")

app.include_router(patients.router, prefix="/patients", tags=["patients"])
