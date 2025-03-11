# app/services/patient_service.py
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from app.models.patient import Patient, PatientRiskFactor, Diagnosis, ICDCode
from app.schemas.patient import PatientCreate, PatientUpdate, PatientQuery


class PatientService:
    @staticmethod
    def get_patient(db: Session, patient_id: str):
        return db.query(Patient).filter(Patient.patient_id == patient_id).first()

    @staticmethod
    def get_patients(db: Session, skip: int = 0, limit: int = 10):
        return db.query(Patient).offset(skip).limit(limit).all()

    @staticmethod
    def create_patient(db: Session, patient: PatientCreate):
        db_patient = Patient(**patient.dict())
        db.add(db_patient)
        db.commit()
        db.refresh(db_patient)
        return db_patient

    @staticmethod
    def update_patient(db: Session, patient_id: str, patient: PatientUpdate):
        db_patient = db.query(Patient).filter(Patient.patient_id == patient_id).first()
        if db_patient:
            for key, value in patient.dict().items():
                setattr(db_patient, key, value)
            db.commit()
            db.refresh(db_patient)
        return db_patient

    @staticmethod
    def delete_patient(db: Session, patient_id: str):
        db_patient = db.query(Patient).filter(Patient.patient_id == patient_id).first()
        if db_patient:
            db.delete(db_patient)
            db.commit()
        return db_patient

    @staticmethod
    def search_patients(db: Session, query: PatientQuery):
        patients_query = db.query(Patient).options(joinedload(Patient.contact_info))

        if query.age_min is not None:
            patients_query = patients_query.filter(
                func.date_part("year", func.age(Patient.date_of_birth)) >= query.age_min
            )
        if query.age_max is not None:
            patients_query = patients_query.filter(
                func.date_part("year", func.age(Patient.date_of_birth)) <= query.age_max
            )
        if query.gender is not None:
            patients_query = patients_query.filter(Patient.gender == query.gender)
        if query.ethnicity is not None:
            patients_query = patients_query.filter(Patient.ethnicity == query.ethnicity)
        if query.race is not None:
            patients_query = patients_query.filter(Patient.race == query.race)
        if query.is_deceased is not None:
            patients_query = patients_query.filter(
                Patient.is_deceased == query.is_deceased
            )
        if query.risk_factors:
            patients_query = patients_query.join(PatientRiskFactor).filter(
                PatientRiskFactor.factor_name.in_(query.risk_factors)
            )
        if query.diagnoses:
            patients_query = (
                patients_query.join(Diagnosis)
                .join(ICDCode)
                .filter(ICDCode.code.in_(query.diagnoses))
            )

        return [
            {
                "patient_id": patient.patient_id,
                "first_name": patient.first_name,
                "last_name": patient.last_name,
                "email": (
                    patient.contact_info[0].email if patient.contact_info else None
                ),
                "created_at": patient.created_at,
                "updated_at": patient.updated_at,
            }
            for patient in patients_query.all()
        ]
