# app/schemas/patient.py
from pydantic import BaseModel, field_validator
from typing import Optional, List
from datetime import date, datetime


class PatientBase(BaseModel):
    mrn: str
    first_name: str
    middle_name: Optional[str] = None
    last_name: str
    date_of_birth: date
    gender: str
    biological_sex: str
    blood_type: Optional[str] = None
    ethnicity: Optional[str] = None
    race: Optional[str] = None
    preferred_language: Optional[str] = None
    marital_status: Optional[str] = None
    occupation: Optional[str] = None
    is_deceased: Optional[bool] = False
    deceased_date: Optional[date] = None


class PatientCreate(PatientBase):
    pass


class PatientUpdate(PatientBase):
    pass


class Patient(BaseModel):
    patient_id: str
    first_name: str
    last_name: str
    email: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    @field_validator('patient_id', mode='before')
    def validate_patient_id(cls, v):
        return str(v)

    class Config:
        from_attributes = True


class PatientQuery(BaseModel):
    age_min: Optional[int] = None
    age_max: Optional[int] = None
    gender: Optional[str] = None
    risk_factors: Optional[List[str]] = None
    diagnoses: Optional[List[str]] = None
    ethnicity: Optional[str] = None
    race: Optional[str] = None
    is_deceased: Optional[bool] = None


# Define other schemas similarly
