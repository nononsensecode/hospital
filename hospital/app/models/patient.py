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


class PatientContactInfo(Base):
    __tablename__ = "patient_contact_info"

    contact_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    patient_id = Column(
        UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False
    )
    email = Column(String)
    phone_primary = Column(String)
    phone_secondary = Column(String)
    preferred_contact_method = Column(String, nullable=False)
    emergency_contact_name = Column(String)
    emergency_contact_relation = Column(String)
    emergency_contact_phone = Column(String)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    patient = relationship("Patient", back_populates="contact_info")


class PatientAddress(Base):
    __tablename__ = "patient_addresses"

    address_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    patient_id = Column(
        UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False
    )
    address_type = Column(String, nullable=False)
    is_primary = Column(Boolean, default=False)
    street_address1 = Column(String, nullable=False)
    street_address2 = Column(String)
    city = Column(String, nullable=False)
    state_province = Column(String, nullable=False)
    postal_code = Column(String, nullable=False)
    country = Column(String, default="United States")
    geo_latitude = Column(DECIMAL(9, 6))
    geo_longitude = Column(DECIMAL(9, 6))
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    patient = relationship("Patient", back_populates="addresses")


class PatientEncounter(Base):
    __tablename__ = "patient_encounters"

    encounter_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    patient_id = Column(
        UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False
    )
    encounter_type = Column(String, nullable=False)
    encounter_date = Column(TIMESTAMP(timezone=True), server_default=func.now())
    provider_id = Column(
        UUID(as_uuid=True), ForeignKey("healthcare_providers.provider_id")
    )
    notes = Column(String)

    patient = relationship("Patient", back_populates="encounters")


class PatientMedication(Base):
    __tablename__ = "patient_medications"

    patient_medication_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    patient_id = Column(
        UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False
    )
    medication_id = Column(
        UUID(as_uuid=True), ForeignKey("medications.medication_id"), nullable=False
    )
    provider_id = Column(
        UUID(as_uuid=True), ForeignKey("healthcare_providers.provider_id")
    )
    encounter_id = Column(
        UUID(as_uuid=True), ForeignKey("patient_encounters.encounter_id")
    )
    prescription_date = Column(Date, nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date)
    is_active = Column(Boolean, default=True)
    dosage = Column(String)
    frequency = Column(String)
    route = Column(String)
    instructions = Column(String)
    reason = Column(String)
    pharmacy_notes = Column(String)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    patient = relationship("Patient", back_populates="medications")
    medication = relationship("Medication", back_populates="patient_medications")


class PatientAllergy(Base):
    __tablename__ = "patient_allergies"

    allergy_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    patient_id = Column(
        UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False
    )
    allergen = Column(String, nullable=False)
    reaction = Column(String)
    severity = Column(String)
    onset_date = Column(Date)
    end_date = Column(Date)
    is_active = Column(Boolean, default=True)
    notes = Column(String)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    patient = relationship("Patient", back_populates="allergies")


class PatientImmunization(Base):
    __tablename__ = "patient_immunizations"

    immunization_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    patient_id = Column(
        UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False
    )
    vaccine_name = Column(String, nullable=False)
    administration_date = Column(Date, nullable=False)
    provider_id = Column(
        UUID(as_uuid=True), ForeignKey("healthcare_providers.provider_id")
    )
    lot_number = Column(String)
    expiration_date = Column(Date)
    site = Column(String)
    route = Column(String)
    dose = Column(String)
    notes = Column(String)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    patient = relationship("Patient", back_populates="immunizations")


class FamilyMedicalHistory(Base):
    __tablename__ = "family_medical_history"

    family_history_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    patient_id = Column(
        UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False
    )
    relation_type = Column(String, nullable=False)
    condition = Column(String, nullable=False)
    icd_code_id = Column(UUID(as_uuid=True), ForeignKey("icd_codes.icd_code_id"))
    age_at_diagnosis = Column(Integer)
    is_deceased = Column(Boolean)
    age_at_death = Column(Integer)
    notes = Column(String)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    patient = relationship("Patient", back_populates="family_history")


class CohortMember(Base):
    __tablename__ = "cohort_members"

    cohort_member_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    cohort_id = Column(
        UUID(as_uuid=True), ForeignKey("patient_cohorts.cohort_id"), nullable=False
    )
    patient_id = Column(
        UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False
    )
    added_date = Column(Date, nullable=False, default=func.current_date())
    added_by = Column(UUID(as_uuid=True), ForeignKey("healthcare_providers.provider_id"))
    removed_date = Column(Date)
    removed_by = Column(UUID(as_uuid=True), ForeignKey("healthcare_providers.provider_id"))
    is_active = Column(Boolean, default=True)
    notes = Column(String)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    patient = relationship("Patient", back_populates="cohorts")


class Medication(Base):
    __tablename__ = "medications"

    medication_id = Column(
        UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4
    )
    ndc_code = Column(String, unique=True)
    brand_name = Column(String)
    generic_name = Column(String, nullable=False)
    drug_class = Column(String)
    form = Column(String)
    strength = Column(String)
    unit = Column(String)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    patient_medications = relationship("PatientMedication", back_populates="medication")

PatientMedication.medication = relationship("Medication", back_populates="patient_medications")
