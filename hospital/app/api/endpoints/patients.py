# app/api/endpoints/patients.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.schemas.patient import Patient, PatientCreate, PatientUpdate, PatientQuery
from app.services.patient_service import PatientService
from app.database import get_db
from typing import List

router = APIRouter()


@router.get("/", response_model=List[Patient])
def read_patients(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    patients = PatientService.get_patients(db, skip=skip, limit=limit)
    return patients


@router.post("/", response_model=Patient)
def create_patient(patient: PatientCreate, db: Session = Depends(get_db)):
    return PatientService.create_patient(db, patient)


@router.get("/{patient_id}", response_model=Patient)
def read_patient(patient_id: str, db: Session = Depends(get_db)):
    db_patient = PatientService.get_patient(db, patient_id)
    if db_patient is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return db_patient


@router.put("/{patient_id}", response_model=Patient)
def update_patient(
    patient_id: str, patient: PatientUpdate, db: Session = Depends(get_db)
):
    db_patient = PatientService.update_patient(db, patient_id, patient)
    if db_patient is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return db_patient


@router.delete("/{patient_id}", response_model=Patient)
def delete_patient(patient_id: str, db: Session = Depends(get_db)):
    db_patient = PatientService.delete_patient(db, patient_id)
    if db_patient is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return db_patient


@router.post("/search", response_model=List[Patient])
def search_patients(query: PatientQuery, db: Session = Depends(get_db)):
    patients = PatientService.search_patients(db, query)
    return patients
