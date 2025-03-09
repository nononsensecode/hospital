# app/models/patient.py
from sqlalchemy import (
    Column,
    String,
    Date,
    Boolean,
    ForeignKey,
    Integer,
    DECIMAL,
    TIMESTAMP,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import uuid


class Patient(Base):
    __tablename__ = "patients"

    patient_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    mrn = Column(String, unique=True, nullable=False)
    first_name = Column(String, nullable=False)
    middle_name = Column(String)
    last_name = Column(String, nullable=False)
    date_of_birth = Column(Date, nullable=False)
    gender = Column(String, nullable=False)
    biological_sex = Column(String, nullable=False)
    blood_type = Column(String)
    ethnicity = Column(String)
    race = Column(String)
    preferred_language = Column(String)
    marital_status = Column(String)
    occupation = Column(String)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    is_deceased = Column(Boolean, default=False)
    deceased_date = Column(Date)

    contact_info = relationship("PatientContactInfo", back_populates="patient")
    addresses = relationship("PatientAddress", back_populates="patient")
    risk_factors = relationship("PatientRiskFactor", back_populates="patient")
    diagnoses = relationship("Diagnosis", back_populates="patient")
    encounters = relationship("PatientEncounter", back_populates="patient")
    medications = relationship("PatientMedication", back_populates="patient")
    allergies = relationship("PatientAllergy", back_populates="patient")
    immunizations = relationship("PatientImmunization", back_populates="patient")
    family_history = relationship("FamilyMedicalHistory", back_populates="patient")
    cohorts = relationship("CohortMember", back_populates="patient")


class PatientRiskFactor(Base):
    __tablename__ = "patient_risk_factors"

    risk_factor_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    patient_id = Column(
        UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False
    )
    factor_name = Column(String, nullable=False)
    factor_value = Column(String)
    factor_type = Column(String, nullable=False)
    severity = Column(String)
    onset_date = Column(Date)
    end_date = Column(Date)
    is_current = Column(Boolean, default=True)
    notes = Column(String)

    patient = relationship("Patient", back_populates="risk_factors")


class Diagnosis(Base):
    __tablename__ = "diagnoses"

    diagnosis_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    patient_id = Column(
        UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False
    )
    encounter_id = Column(
        UUID(as_uuid=True), ForeignKey("patient_encounters.encounter_id")
    )
    icd_code_id = Column(
        UUID(as_uuid=True), ForeignKey("icd_codes.icd_code_id"), nullable=False
    )
    provider_id = Column(
        UUID(as_uuid=True), ForeignKey("healthcare_providers.provider_id")
    )
    diagnosis_date = Column(TIMESTAMP(timezone=True), server_default=func.now())
    diagnosis_type = Column(String, nullable=False)
    diagnosis_status = Column(String, nullable=False)
    notes = Column(String)

    patient = relationship("Patient", back_populates="diagnoses")
    icd_code = relationship("ICDCode")


class ICDCode(Base):
    __tablename__ = "icd_codes"

    icd_code_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    code = Column(String, nullable=False, unique=True)
    description = Column(String, nullable=False)
    icd_version = Column(String, nullable=False)
    category = Column(String)
    is_billable = Column(Boolean, default=True)

    diagnoses = relationship("Diagnosis", back_populates="icd_code")
