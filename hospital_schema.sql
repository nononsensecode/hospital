-- Enable PostGIS extension for geometry type
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =======================================
-- Core Patient Data
-- =======================================

-- Patients table - core patient information
CREATE TABLE patients (
    patient_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mrn VARCHAR(50) UNIQUE NOT NULL, -- Medical Record Number
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    biological_sex VARCHAR(10) NOT NULL,
    blood_type VARCHAR(5),
    ethnicity VARCHAR(100),
    race VARCHAR(100),
    preferred_language VARCHAR(50),
    marital_status VARCHAR(20),
    occupation VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_deceased BOOLEAN DEFAULT FALSE,
    deceased_date DATE,
    CONSTRAINT chk_dob CHECK (date_of_birth <= CURRENT_DATE)
);

-- Patient contact information
CREATE TABLE patient_contact_info (
    contact_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    email VARCHAR(255),
    phone_primary VARCHAR(20),
    phone_secondary VARCHAR(20),
    preferred_contact_method VARCHAR(20) NOT NULL,
    emergency_contact_name VARCHAR(200),
    emergency_contact_relation VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Patient addresses (can have multiple)
CREATE TABLE patient_addresses (
    address_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    address_type VARCHAR(50) NOT NULL, -- 'HOME', 'WORK', etc
    is_primary BOOLEAN DEFAULT FALSE,
    street_address1 VARCHAR(255) NOT NULL,
    street_address2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'United States',
    geo_latitude DECIMAL(9,6),
    geo_longitude DECIMAL(9,6),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================
-- Healthcare Provider Data
-- =======================================

-- Healthcare providers
CREATE TABLE healthcare_providers (
    provider_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    npi VARCHAR(20) UNIQUE, -- National Provider Identifier
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(100),
    credentials VARCHAR(100),
    provider_type VARCHAR(50) NOT NULL, -- 'PHYSICIAN', 'NURSE', 'TECHNICIAN'
    email VARCHAR(255),
    phone VARCHAR(20),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Departments
CREATE TABLE departments (
    department_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(100),
    phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Provider department assignments
CREATE TABLE provider_departments (
    provider_dept_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(provider_id) ON DELETE CASCADE,
    department_id UUID NOT NULL REFERENCES departments(department_id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE,
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT chk_provider_dept_dates CHECK (end_date IS NULL OR start_date <= end_date)
);

-- =======================================
-- Medical Record Data
-- =======================================

-- Primary Care Provider assignments
CREATE TABLE primary_care_providers (
    pcp_assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES healthcare_providers(provider_id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT chk_pcp_dates CHECK (end_date IS NULL OR start_date <= end_date)
);

-- Patient encounters/visits
CREATE TABLE patient_encounters (
    encounter_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES healthcare_providers(provider_id),
    department_id UUID REFERENCES departments(department_id),
    encounter_type VARCHAR(50) NOT NULL, -- 'OFFICE_VISIT', 'EMERGENCY', 'INPATIENT', 'VIRTUAL'
    encounter_date TIMESTAMP WITH TIME ZONE NOT NULL,
    chief_complaint TEXT,
    visit_reason TEXT,
    notes TEXT,
    discharge_disposition VARCHAR(100),
    discharge_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================
-- Diagnostic Data
-- =======================================

-- ICD codes (International Classification of Diseases)
CREATE TABLE icd_codes (
    icd_code_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    icd_version VARCHAR(10) NOT NULL, -- 'ICD-9', 'ICD-10', 'ICD-11'
    category VARCHAR(100),
    is_billable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Patient diagnoses
CREATE TABLE diagnoses (
    diagnosis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    encounter_id UUID REFERENCES patient_encounters(encounter_id),
    icd_code_id UUID NOT NULL REFERENCES icd_codes(icd_code_id),
    provider_id UUID REFERENCES healthcare_providers(provider_id),
    diagnosis_date TIMESTAMP WITH TIME ZONE NOT NULL,
    diagnosis_type VARCHAR(50) NOT NULL, -- 'PRIMARY', 'SECONDARY', 'ADMISSION', 'DISCHARGE'
    diagnosis_status VARCHAR(50) NOT NULL, -- 'ACTIVE', 'RESOLVED', 'CHRONIC', 'ACUTE'
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================
-- Risk Factor Data (for epidemiological queries)
-- =======================================

-- Patient risk factors
CREATE TABLE patient_risk_factors (
    risk_factor_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    factor_name VARCHAR(100) NOT NULL,
    factor_value VARCHAR(100),
    factor_type VARCHAR(50) NOT NULL, -- 'BEHAVIORAL', 'ENVIRONMENTAL', 'GENETIC', 'SOCIAL'
    severity VARCHAR(20), -- 'LOW', 'MODERATE', 'HIGH'
    onset_date DATE,
    end_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT chk_risk_factor_dates CHECK (end_date IS NULL OR onset_date <= end_date)
);

-- Social determinants of health
CREATE TABLE social_determinants (
    social_determinant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL, -- 'ECONOMIC_STABILITY', 'EDUCATION', 'SOCIAL_CONTEXT', 'HEALTH_CARE', 'NEIGHBORHOOD'
    description TEXT NOT NULL,
    impact_level VARCHAR(20) NOT NULL, -- 'LOW', 'MODERATE', 'HIGH'
    identified_date DATE NOT NULL,
    resolution_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================
-- Medication and Allergy Data
-- =======================================

-- Medications catalog
CREATE TABLE medications (
    medication_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ndc_code VARCHAR(20) UNIQUE, -- National Drug Code
    brand_name VARCHAR(200),
    generic_name VARCHAR(200) NOT NULL,
    drug_class VARCHAR(100),
    form VARCHAR(50), -- 'TABLET', 'CAPSULE', 'LIQUID', 'INJECTION'
    strength VARCHAR(50),
    unit VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Patient medications
CREATE TABLE patient_medications (
    patient_medication_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    medication_id UUID NOT NULL REFERENCES medications(medication_id),
    provider_id UUID REFERENCES healthcare_providers(provider_id),
    encounter_id UUID REFERENCES patient_encounters(encounter_id),
    prescription_date DATE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    dosage VARCHAR(50),
    frequency VARCHAR(50),
    route VARCHAR(50), -- 'ORAL', 'IV', 'TOPICAL', etc
    instructions TEXT,
    reason TEXT,
    pharmacy_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT chk_medication_dates CHECK (end_date IS NULL OR start_date <= end_date)
);

-- Allergies
CREATE TABLE patient_allergies (
    allergy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    allergen_type VARCHAR(50) NOT NULL, -- 'MEDICATION', 'FOOD', 'ENVIRONMENTAL'
    allergen VARCHAR(100) NOT NULL,
    reaction TEXT,
    severity VARCHAR(20) NOT NULL, -- 'MILD', 'MODERATE', 'SEVERE', 'LIFE_THREATENING'
    onset_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================
-- Lab and Test Data
-- =======================================

-- Lab tests catalog
CREATE TABLE lab_tests (
    lab_test_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_code VARCHAR(20) NOT NULL UNIQUE,
    test_name VARCHAR(200) NOT NULL,
    loinc_code VARCHAR(20), -- Logical Observation Identifiers Names and Codes
    test_category VARCHAR(100),
    description TEXT,
    sample_type VARCHAR(50), -- 'BLOOD', 'URINE', 'CULTURE', etc
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Patient lab orders
CREATE TABLE patient_lab_orders (
    lab_order_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES healthcare_providers(provider_id),
    encounter_id UUID REFERENCES patient_encounters(encounter_id),
    order_date TIMESTAMP WITH TIME ZONE NOT NULL,
    order_status VARCHAR(50) NOT NULL, -- 'ORDERED', 'COLLECTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELED'
    priority VARCHAR(20) DEFAULT 'ROUTINE', -- 'STAT', 'ROUTINE', 'URGENT'
    clinical_indication TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Lab order details (which tests are in an order)
CREATE TABLE lab_order_details (
    lab_order_detail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lab_order_id UUID NOT NULL REFERENCES patient_lab_orders(lab_order_id) ON DELETE CASCADE,
    lab_test_id UUID NOT NULL REFERENCES lab_tests(lab_test_id),
    status VARCHAR(50) NOT NULL, -- 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Lab results
CREATE TABLE lab_results (
    lab_result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lab_order_detail_id UUID NOT NULL REFERENCES lab_order_details(lab_order_detail_id) ON DELETE CASCADE,
    result_value VARCHAR(100),
    result_unit VARCHAR(50),
    reference_range VARCHAR(100),
    is_abnormal BOOLEAN,
    is_critical BOOLEAN DEFAULT FALSE,
    result_notes TEXT,
    performed_by UUID REFERENCES healthcare_providers(provider_id),
    result_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================
-- Vital Signs
-- =======================================

-- Patient vital signs
CREATE TABLE vital_signs (
    vital_sign_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    encounter_id UUID REFERENCES patient_encounters(encounter_id),
    recorded_by UUID REFERENCES healthcare_providers(provider_id),
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    temperature DECIMAL(5,2), -- in Celsius
    temperature_site VARCHAR(20), -- 'ORAL', 'TYMPANIC', 'RECTAL', 'AXILLARY'
    heart_rate INTEGER,
    respiratory_rate INTEGER,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    blood_pressure_position VARCHAR(20), -- 'SITTING', 'STANDING', 'LYING'
    oxygen_saturation DECIMAL(5,2),
    height DECIMAL(5,2), -- in cm
    weight DECIMAL(5,2), -- in kg
    bmi DECIMAL(5,2),
    pain_score INTEGER,
    pain_scale VARCHAR(20), -- 'NUMERIC', 'WONG_BAKER', 'FLACC'
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================
-- Vaccination Data
-- =======================================

-- Vaccines catalog
CREATE TABLE vaccines (
    vaccine_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cvx_code VARCHAR(20) UNIQUE, -- CDC vaccine code
    name VARCHAR(200) NOT NULL,
    manufacturer VARCHAR(100),
    disease_target VARCHAR(100),
    series_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Patient immunizations
CREATE TABLE patient_immunizations (
    immunization_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    vaccine_id UUID NOT NULL REFERENCES vaccines(vaccine_id),
    administered_by UUID REFERENCES healthcare_providers(provider_id),
    encounter_id UUID REFERENCES patient_encounters(encounter_id),
    administration_date DATE NOT NULL,
    dose_number INTEGER,
    lot_number VARCHAR(50),
    expiration_date DATE,
    administration_site VARCHAR(50), -- 'LEFT_ARM', 'RIGHT_ARM', etc
    route VARCHAR(30), -- 'INTRAMUSCULAR', 'SUBCUTANEOUS', etc
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================
-- Family Medical History
-- =======================================

-- Patient family history
CREATE TABLE family_medical_history (
    family_history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    relation_type VARCHAR(50) NOT NULL, -- 'MOTHER', 'FATHER', 'SIBLING', etc
    condition VARCHAR(200) NOT NULL,
    icd_code_id UUID REFERENCES icd_codes(icd_code_id),
    age_at_diagnosis INTEGER,
    is_deceased BOOLEAN,
    age_at_death INTEGER,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================
-- Epidemiological Query Support
-- =======================================

-- Patient cohorts for epidemiological studies
CREATE TABLE patient_cohorts (
    cohort_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cohort_name VARCHAR(200) NOT NULL,
    description TEXT,
    creation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by UUID REFERENCES healthcare_providers(provider_id),
    is_active BOOLEAN DEFAULT TRUE,
    criteria TEXT, -- Stored search criteria used to define the cohort
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Patients in cohorts
CREATE TABLE cohort_members (
    cohort_member_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cohort_id UUID NOT NULL REFERENCES patient_cohorts(cohort_id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    added_date DATE NOT NULL DEFAULT CURRENT_DATE,
    added_by UUID REFERENCES healthcare_providers(provider_id),
    removed_date DATE,
    removed_by UUID REFERENCES healthcare_providers(provider_id),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_patient_cohort UNIQUE(cohort_id, patient_id),
    CONSTRAINT chk_cohort_dates CHECK (removed_date IS NULL OR added_date <= removed_date)
);

-- =======================================
-- Geographic Information
-- =======================================

-- Geographic regions (for epidemiological analysis)
CREATE TABLE geographic_regions (
    region_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    region_name VARCHAR(100) NOT NULL,
    region_type VARCHAR(50) NOT NULL, -- 'CITY', 'COUNTY', 'STATE', 'ZIP_CODE', 'CENSUS_TRACT'
    parent_region_id UUID REFERENCES geographic_regions(region_id),
    geo_boundary GEOMETRY, -- PostGIS geometry type for mapping
    population INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================
-- Indexes for Improved Query Performance
-- =======================================

-- Patient indexes
CREATE INDEX idx_patient_name ON patients(last_name, first_name);
CREATE INDEX idx_patient_dob ON patients(date_of_birth);
CREATE INDEX idx_patient_gender ON patients(gender);
CREATE INDEX idx_patient_ethnicity ON patients(ethnicity);
CREATE INDEX idx_patient_race ON patients(race);

-- Contact info indexes
CREATE INDEX idx_patient_email ON patient_contact_info(email);
CREATE INDEX idx_patient_phone ON patient_contact_info(phone_primary);

-- Address indexes
CREATE INDEX idx_patient_address_geo ON patient_addresses(geo_latitude, geo_longitude);
CREATE INDEX idx_patient_address_zip ON patient_addresses(postal_code);

-- Diagnosis indexes
CREATE INDEX idx_diagnosis_patient ON diagnoses(patient_id);
CREATE INDEX idx_diagnosis_icd ON diagnoses(icd_code_id);
CREATE INDEX idx_diagnosis_date ON diagnoses(diagnosis_date);
CREATE INDEX idx_diagnosis_status ON diagnoses(diagnosis_status);

-- Encounter indexes
CREATE INDEX idx_encounter_patient ON patient_encounters(patient_id);
CREATE INDEX idx_encounter_date ON patient_encounters(encounter_date);
CREATE INDEX idx_encounter_type ON patient_encounters(encounter_type);

-- Risk factor indexes
CREATE INDEX idx_risk_factor_patient ON patient_risk_factors(patient_id);
CREATE INDEX idx_risk_factor_type ON patient_risk_factors(factor_type);
CREATE INDEX idx_risk_factor_name ON patient_risk_factors(factor_name);
CREATE INDEX idx_risk_factor_current ON patient_risk_factors(is_current);

-- Lab result indexes
CREATE INDEX idx_lab_result_abnormal ON lab_results(is_abnormal);
CREATE INDEX idx_lab_result_critical ON lab_results(is_critical);
CREATE INDEX idx_lab_result_date ON lab_results(result_date);

-- =======================================
-- Example Epidemiological Query Views
-- =======================================

-- View to identify patients with specific risk factors
CREATE OR REPLACE VIEW patients_with_risk_factors AS
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    p.gender,
    p.race,
    p.ethnicity,
    rf.factor_name,
    rf.factor_value,
    rf.factor_type,
    rf.severity
FROM 
    patients p
JOIN 
    patient_risk_factors rf ON p.patient_id = rf.patient_id
WHERE 
    rf.is_current = TRUE;

-- View to find patients with specific diagnoses
CREATE OR REPLACE VIEW patients_with_diagnoses AS
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    p.gender,
    p.race,
    p.ethnicity,
    d.diagnosis_date,
    d.diagnosis_status,
    ic.code AS icd_code,
    ic.description AS diagnosis_description
FROM 
    patients p
JOIN 
    diagnoses d ON p.patient_id = d.patient_id
JOIN 
    icd_codes ic ON d.icd_code_id = ic.icd_code_id;

-- View for geographic distribution of patients with specific conditions
CREATE OR REPLACE VIEW geographic_disease_distribution AS
SELECT 
    gr.region_name,
    gr.region_type,
    ic.code AS icd_code,
    ic.description AS diagnosis,
    COUNT(DISTINCT p.patient_id) AS patient_count
FROM 
    patients p
JOIN 
    patient_addresses pa ON p.patient_id = pa.patient_id
JOIN 
    geographic_regions gr ON 
        ST_Contains(gr.geo_boundary, ST_Point(pa.geo_longitude, pa.geo_latitude))
JOIN 
    diagnoses d ON p.patient_id = d.patient_id
JOIN 
    icd_codes ic ON d.icd_code_id = ic.icd_code_id
WHERE 
    pa.is_primary = TRUE
GROUP BY 
    gr.region_name, gr.region_type, ic.code, ic.description;

-- View for patients with combination of risk factors for disease outbreak monitoring
CREATE OR REPLACE VIEW high_risk_patients AS
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    p.gender,
    p.race,
    p.ethnicity,
    pc.email,
    pc.phone_primary,
    pa.street_address1,
    pa.city,
    pa.state_province,
    pa.postal_code,
    COUNT(DISTINCT rf.risk_factor_id) AS risk_factor_count,
    COUNT(DISTINCT d.diagnosis_id) AS diagnosis_count
FROM 
    patients p
JOIN 
    patient_contact_info pc ON p.patient_id = pc.patient_id
JOIN 
    patient_addresses pa ON p.patient_id = pa.patient_id AND pa.is_primary = TRUE
LEFT JOIN 
    patient_risk_factors rf ON p.patient_id = rf.patient_id AND rf.is_current = TRUE
LEFT JOIN 
    diagnoses d ON p.patient_id = d.patient_id AND d.diagnosis_status = 'ACTIVE'
GROUP BY 
    p.patient_id, p.first_name, p.last_name, p.date_of_birth, 
    p.gender, p.race, p.ethnicity, pc.email, pc.phone_primary,
    pa.street_address1, pa.city, pa.state_province, pa.postal_code;

-- Comment: The schema above includes tables for patients with comprehensive contact info,
-- medical records, diagnoses, risk factors, and epidemiological data tracking.
-- It's designed to allow sophisticated querying for disease surveillance.

-- =======================================
-- Sample Data Insertion
-- =======================================

-- Insert sample patients
INSERT INTO patients (mrn, first_name, middle_name, last_name, date_of_birth, gender, biological_sex, blood_type, ethnicity, race, preferred_language, marital_status, occupation)
VALUES
    ('MRN001', 'John', 'A', 'Doe', '1980-01-01', 'Male', 'Male', 'O+', 'Hispanic', 'White', 'English', 'Single', 'Engineer'),
    ('MRN002', 'Jane', 'B', 'Smith', '1985-02-02', 'Female', 'Female', 'A-', 'Non-Hispanic', 'Black', 'Spanish', 'Married', 'Teacher'),
    ('MRN003', 'Alice', 'C', 'Johnson', '1990-03-03', 'Female', 'Female', 'B+', 'Hispanic', 'Asian', 'English', 'Single', 'Nurse'),
    ('MRN004', 'Bob', 'D', 'Brown', '1975-04-04', 'Male', 'Male', 'AB-', 'Non-Hispanic', 'White', 'French', 'Married', 'Doctor'),
    ('MRN005', 'Charlie', 'E', 'Davis', '2000-05-05', 'Male', 'Male', 'O-', 'Hispanic', 'Black', 'English', 'Single', 'Student'),
    ('MRN006', 'David', 'F', 'Miller', '1995-06-06', 'Male', 'Male', 'A+', 'Non-Hispanic', 'White', 'English', 'Single', 'Artist'),
    ('MRN007', 'Eva', 'G', 'Garcia', '1988-07-07', 'Female', 'Female', 'B-', 'Hispanic', 'White', 'Spanish', 'Married', 'Chef'),
    ('MRN008', 'Frank', 'H', 'Martinez', '1972-08-08', 'Male', 'Male', 'AB+', 'Non-Hispanic', 'Black', 'English', 'Married', 'Lawyer'),
    ('MRN009', 'Grace', 'I', 'Hernandez', '1983-09-09', 'Female', 'Female', 'O-', 'Hispanic', 'Asian', 'English', 'Single', 'Scientist'),
    ('MRN010', 'Henry', 'J', 'Lopez', '1992-10-10', 'Male', 'Male', 'A-', 'Non-Hispanic', 'White', 'English', 'Single', 'Engineer'),
    ('MRN011', 'Ivy', 'K', 'Gonzalez', '1987-11-11', 'Female', 'Female', 'B+', 'Hispanic', 'Black', 'Spanish', 'Married', 'Teacher'),
    ('MRN012', 'Jack', 'L', 'Wilson', '1979-12-12', 'Male', 'Male', 'O+', 'Non-Hispanic', 'White', 'English', 'Single', 'Nurse'),
    ('MRN013', 'Karen', 'M', 'Anderson', '1991-01-13', 'Female', 'Female', 'AB-', 'Hispanic', 'Asian', 'English', 'Married', 'Doctor'),
    ('MRN014', 'Leo', 'N', 'Thomas', '1984-02-14', 'Male', 'Male', 'A+', 'Non-Hispanic', 'Black', 'French', 'Single', 'Student'),
    ('MRN015', 'Mia', 'O', 'Taylor', '1993-03-15', 'Female', 'Female', 'B-', 'Hispanic', 'White', 'English', 'Married', 'Artist'),
    ('MRN016', 'Noah', 'P', 'Moore', '1986-04-16', 'Male', 'Male', 'AB+', 'Non-Hispanic', 'Black', 'Spanish', 'Single', 'Chef'),
    ('MRN017', 'Olivia', 'Q', 'Jackson', '1994-05-17', 'Female', 'Female', 'O-', 'Hispanic', 'Asian', 'English', 'Married', 'Lawyer'),
    ('MRN018', 'Paul', 'R', 'White', '1981-06-18', 'Male', 'Male', 'A-', 'Non-Hispanic', 'White', 'English', 'Single', 'Scientist'),
    ('MRN019', 'Quinn', 'S', 'Harris', '1996-07-19', 'Female', 'Female', 'B+', 'Hispanic', 'Black', 'Spanish', 'Married', 'Engineer'),
    ('MRN020', 'Ryan', 'T', 'Martin', '1989-08-20', 'Male', 'Male', 'O+', 'Non-Hispanic', 'White', 'English', 'Single', 'Teacher'),
    ('MRN021', 'Sophia', 'U', 'Thompson', '1997-09-21', 'Female', 'Female', 'AB-', 'Hispanic', 'Asian', 'English', 'Married', 'Nurse'),
    ('MRN022', 'Tom', 'V', 'Martinez', '1982-10-22', 'Male', 'Male', 'A+', 'Non-Hispanic', 'Black', 'French', 'Single', 'Doctor'),
    ('MRN023', 'Uma', 'W', 'Clark', '1998-11-23', 'Female', 'Female', 'B-', 'Hispanic', 'White', 'English', 'Married', 'Student'),
    ('MRN024', 'Victor', 'X', 'Rodriguez', '1985-12-24', 'Male', 'Male', 'AB+', 'Non-Hispanic', 'Black', 'Spanish', 'Single', 'Artist'),
    ('MRN025', 'Wendy', 'Y', 'Lewis', '1999-01-25', 'Female', 'Female', 'O-', 'Hispanic', 'Asian', 'English', 'Married', 'Chef'),
    ('MRN026', 'Xander', 'Z', 'Lee', '1980-02-26', 'Male', 'Male', 'A-', 'Non-Hispanic', 'White', 'English', 'Single', 'Lawyer'),
    ('MRN027', 'Yara', 'A', 'Walker', '1995-03-27', 'Female', 'Female', 'B+', 'Hispanic', 'Black', 'Spanish', 'Married', 'Scientist'),
    ('MRN028', 'Zane', 'B', 'Hall', '1987-04-28', 'Male', 'Male', 'O+', 'Non-Hispanic', 'White', 'English', 'Single', 'Engineer'),
    ('MRN029', 'Amy', 'C', 'Allen', '1990-05-29', 'Female', 'Female', 'AB-', 'Hispanic', 'Asian', 'English', 'Married', 'Teacher'),
    ('MRN030', 'Brian', 'D', 'Young', '1983-06-30', 'Male', 'Male', 'A+', 'Non-Hispanic', 'Black', 'French', 'Single', 'Nurse'),
    ('MRN031', 'Chloe', 'E', 'King', '1992-07-31', 'Female', 'Female', 'B-', 'Hispanic', 'White', 'English', 'Married', 'Doctor'),
    ('MRN032', 'Dylan', 'F', 'Scott', '1986-08-01', 'Male', 'Male', 'AB+', 'Non-Hispanic', 'Black', 'Spanish', 'Single', 'Student'),
    ('MRN033', 'Ella', 'G', 'Green', '1994-09-02', 'Female', 'Female', 'O-', 'Hispanic', 'Asian', 'English', 'Married', 'Artist'),
    ('MRN034', 'Finn', 'H', 'Baker', '1981-10-03', 'Male', 'Male', 'A-', 'Non-Hispanic', 'White', 'English', 'Single', 'Chef'),
    ('MRN035', 'Gina', 'I', 'Adams', '1996-11-04', 'Female', 'Female', 'B+', 'Hispanic', 'Black', 'Spanish', 'Married', 'Lawyer'),
    ('MRN036', 'Hank', 'J', 'Nelson', '1984-12-05', 'Male', 'Male', 'O+', 'Non-Hispanic', 'White', 'English', 'Single', 'Scientist'),
    ('MRN037', 'Iris', 'K', 'Carter', '1997-01-06', 'Female', 'Female', 'AB-', 'Hispanic', 'Asian', 'English', 'Married', 'Engineer'),
    ('MRN038', 'Jake', 'L', 'Mitchell', '1988-02-07', 'Male', 'Male', 'A+', 'Non-Hispanic', 'Black', 'French', 'Single', 'Teacher'),
    ('MRN039', 'Kara', 'M', 'Perez', '1991-03-08', 'Female', 'Female', 'B-', 'Hispanic', 'White', 'English', 'Married', 'Nurse'),
    ('MRN040', 'Liam', 'N', 'Roberts', '1985-04-09', 'Male', 'Male', 'AB+', 'Non-Hispanic', 'Black', 'Spanish', 'Single', 'Doctor'),
    ('MRN041', 'Mona', 'O', 'Turner', '1993-05-10', 'Female', 'Female', 'O-', 'Hispanic', 'Asian', 'English', 'Married', 'Student'),
    ('MRN042', 'Nate', 'P', 'Phillips', '1982-06-11', 'Male', 'Male', 'A-', 'Non-Hispanic', 'White', 'English', 'Single', 'Artist'),
    ('MRN043', 'Olga', 'Q', 'Campbell', '1998-07-12', 'Female', 'Female', 'B+', 'Hispanic', 'Black', 'Spanish', 'Married', 'Chef'),
    ('MRN044', 'Pete', 'R', 'Parker', '1989-08-13', 'Male', 'Male', 'O+', 'Non-Hispanic', 'White', 'English', 'Single', 'Lawyer'),
    ('MRN045', 'Quincy', 'S', 'Evans', '1995-09-14', 'Female', 'Female', 'AB-', 'Hispanic', 'Asian', 'English', 'Married', 'Scientist'),
    ('MRN046', 'Rita', 'T', 'Edwards', '1987-10-15', 'Female', 'Female', 'A+', 'Non-Hispanic', 'Black', 'French', 'Single', 'Engineer'),
    ('MRN047', 'Sam', 'U', 'Collins', '1990-11-16', 'Male', 'Male', 'B-', 'Hispanic', 'White', 'English', 'Married', 'Teacher'),
    ('MRN048', 'Tina', 'V', 'Stewart', '1983-12-17', 'Female', 'Female', 'AB+', 'Non-Hispanic', 'Black', 'Spanish', 'Single', 'Nurse'),
    ('MRN049', 'Umar', 'W', 'Sanchez', '1992-01-18', 'Male', 'Male', 'O-', 'Hispanic', 'Asian', 'English', 'Married', 'Doctor'),
    ('MRN050', 'Zoe', 'Y', 'Wilson', '1995-12-12', 'Female', 'Female', 'A+', 'Non-Hispanic', 'Asian', 'Chinese', 'Married', 'Scientist');

-- Insert sample patient contact information
INSERT INTO patient_contact_info (patient_id, email, phone_primary, phone_secondary, preferred_contact_method, emergency_contact_name, emergency_contact_relation, emergency_contact_phone)
SELECT patient_id, 
    CONCAT(first_name, '.', last_name, '@example.com') AS email,
    CONCAT('555-01', LPAD(ROW_NUMBER() OVER (ORDER BY patient_id)::text, 3, '0')) AS phone_primary,
    CONCAT('555-02', LPAD(ROW_NUMBER() OVER (ORDER BY patient_id)::text, 3, '0')) AS phone_secondary,
    'email' AS preferred_contact_method,
    'Emergency Contact', 'Friend', '555-999-9999'
FROM patients;

-- Insert sample patient addresses
INSERT INTO patient_addresses (patient_id, address_type, is_primary, street_address1, street_address2, city, state_province, postal_code, country, geo_latitude, geo_longitude)
SELECT patient_id, 
    'HOME' AS address_type,
    TRUE AS is_primary,
    CONCAT('123 ', first_name, ' St') AS street_address1,
    NULL AS street_address2,
    'City', 'State', '12345', 'United States',
    40.7128 + (ROW_NUMBER() OVER (ORDER BY patient_id) * 0.01) AS geo_latitude,
    -74.0060 + (ROW_NUMBER() OVER (ORDER BY patient_id) * 0.01) AS geo_longitude
FROM patients;

-- Insert sample healthcare providers
INSERT INTO healthcare_providers (npi, first_name, last_name, specialty, credentials, provider_type, email, phone)
VALUES
    ('NPI001', 'Dr. Emily', 'Clark', 'Cardiology', 'MD', 'PHYSICIAN', 'emily.clark@hospital.com', '555-1001'),
    ('NPI002', 'Dr. Michael', 'Lee', 'Neurology', 'MD', 'PHYSICIAN', 'michael.lee@hospital.com', '555-1002'),
    ('NPI003', 'Nurse Sarah', 'Miller', 'Pediatrics', 'RN', 'NURSE', 'sarah.miller@hospital.com', '555-1003'),
    ('NPI004', 'Dr. David', 'Wilson', 'Orthopedics', 'MD', 'PHYSICIAN', 'david.wilson@hospital.com', '555-1004'),
    ('NPI005', 'Tech John', 'Taylor', 'Radiology', 'RT', 'TECHNICIAN', 'john.taylor@hospital.com', '555-1005');

-- Insert sample departments
INSERT INTO departments (name, description, location, phone)
VALUES
    ('Cardiology', 'Heart-related treatments and procedures', 'Building A', '555-2001'),
    ('Neurology', 'Brain and nervous system treatments', 'Building B', '555-2002'),
    ('Pediatrics', 'Child healthcare services', 'Building C', '555-2003'),
    ('Orthopedics', 'Bone and joint treatments', 'Building D', '555-2004'),
    ('Radiology', 'Imaging and diagnostic services', 'Building E', '555-2005');

-- Insert sample provider department assignments
INSERT INTO provider_departments (provider_id, department_id, is_primary, start_date)
SELECT provider_id, department_id, TRUE, '2020-01-01'
FROM healthcare_providers, departments
WHERE healthcare_providers.specialty = departments.name;

-- Insert sample primary care provider assignments
INSERT INTO primary_care_providers (patient_id, provider_id, start_date)
SELECT patient_id, (SELECT provider_id FROM healthcare_providers ORDER BY RANDOM() LIMIT 1), '2021-01-01'
FROM patients;

-- Insert sample patient encounters
INSERT INTO patient_encounters (patient_id, provider_id, department_id, encounter_type, encounter_date, chief_complaint, visit_reason, notes)
SELECT patient_id, 
    (SELECT provider_id FROM healthcare_providers ORDER BY RANDOM() LIMIT 1),
    (SELECT department_id FROM departments ORDER BY RANDOM() LIMIT 1),
    'OFFICE_VISIT',
    '2022-01-01'::date + (ROW_NUMBER() OVER (ORDER BY patient_id) * interval '1 day'),
    'Routine check-up',
    'Annual physical exam',
    'No significant findings'
FROM patients;

-- Insert sample ICD codes
INSERT INTO icd_codes (code, description, icd_version, category)
VALUES
    ('A00', 'Cholera', 'ICD-10', 'Infectious diseases'),
    ('B00', 'Herpesviral [herpes simplex] infections', 'ICD-10', 'Viral infections'),
    ('C00', 'Malignant neoplasm of lip', 'ICD-10', 'Neoplasms'),
    ('D00', 'Carcinoma in situ of oral cavity, esophagus and stomach', 'ICD-10', 'Neoplasms'),
    ('E00', 'Congenital iodine-deficiency syndrome', 'ICD-10', 'Endocrine, nutritional and metabolic diseases');

-- Insert sample patient diagnoses
INSERT INTO diagnoses (patient_id, encounter_id, icd_code_id, diagnosis_date, diagnosis_type, diagnosis_status)
SELECT patient_id, 
    (SELECT encounter_id FROM patient_encounters WHERE patient_encounters.patient_id = patients.patient_id ORDER BY RANDOM() LIMIT 1),
    (SELECT icd_code_id FROM icd_codes ORDER BY RANDOM() LIMIT 1),
    '2022-01-01',
    'PRIMARY',
    'ACTIVE'
FROM patients;

-- Insert sample patient risk factors
INSERT INTO patient_risk_factors (patient_id, factor_name, factor_value, factor_type, severity, onset_date, is_current)
SELECT patient_id, 
    'Smoking', 'Yes', 'BEHAVIORAL', 'HIGH', '2010-01-01', TRUE
FROM patients
WHERE CAST('x' || substring(md5(patient_id::text), 1, 8) AS bit(32))::bigint % 2 = 0;

-- Insert sample social determinants of health
INSERT INTO social_determinants (patient_id, category, description, impact_level, identified_date, is_active)
SELECT patient_id, 
    'ECONOMIC_STABILITY', 'Low income', 'HIGH', '2020-01-01', TRUE
FROM patients
WHERE CAST('x' || substring(md5(patient_id::text), 1, 8) AS bit(32))::bigint % 3 = 0;

-- Insert sample medications
INSERT INTO medications (ndc_code, brand_name, generic_name, drug_class, form, strength, unit)
VALUES
    ('0001-0001-01', 'BrandA', 'GenericA', 'ClassA', 'TABLET', '500', 'mg'),
    ('0002-0002-02', 'BrandB', 'GenericB', 'ClassB', 'CAPSULE', '250', 'mg'),
    ('0003-0003-03', 'BrandC', 'GenericC', 'ClassC', 'LIQUID', '100', 'ml'),
    ('0004-0004-04', 'BrandD', 'GenericD', 'ClassD', 'INJECTION', '50', 'ml'),
    ('0005-0005-05', 'BrandE', 'GenericE', 'ClassE', 'TABLET', '100', 'mg');

-- Insert sample patient medications
INSERT INTO patient_medications (patient_id, medication_id, prescription_date, start_date, dosage, frequency, route, instructions)
SELECT patient_id, 
    (SELECT medication_id FROM medications ORDER BY RANDOM() LIMIT 1),
    '2022-01-01',
    '2022-01-01',
    '1 tablet',
    'Once daily',
    'ORAL',
    'Take with food'
FROM patients;

-- Insert sample patient allergies
INSERT INTO patient_allergies (patient_id, allergen_type, allergen, reaction, severity, onset_date)
SELECT patient_id, 
    'MEDICATION', 'Penicillin', 'Rash', 'MODERATE', '2015-01-01'
FROM patients
WHERE CAST('x' || substring(md5(patient_id::text), 1, 8) AS bit(32))::bigint % 4 = 0;

-- Insert sample lab tests
INSERT INTO lab_tests (test_code, test_name, loinc_code, test_category, description, sample_type)
VALUES
    ('TEST001', 'Complete Blood Count', '12345-6', 'Hematology', 'Measures different components of blood', 'BLOOD'),
    ('TEST002', 'Basic Metabolic Panel', '23456-7', 'Chemistry', 'Measures glucose, calcium, and electrolytes', 'BLOOD'),
    ('TEST003', 'Lipid Panel', '34567-8', 'Chemistry', 'Measures cholesterol and triglycerides', 'BLOOD'),
    ('TEST004', 'Liver Function Test', '45678-9', 'Chemistry', 'Measures liver enzymes and proteins', 'BLOOD'),
    ('TEST005', 'Urinalysis', '56789-0', 'Urine', 'Analyzes urine for various substances', 'URINE');

-- Insert sample patient lab orders
INSERT INTO patient_lab_orders (patient_id, provider_id, order_date, order_status, priority, clinical_indication)
SELECT patient_id, 
    (SELECT provider_id FROM healthcare_providers ORDER BY RANDOM() LIMIT 1),
    '2022-01-01',
    'ORDERED',
    'ROUTINE',
    'Routine check-up'
FROM patients;

-- Insert sample lab order details
INSERT INTO lab_order_details (lab_order_id, lab_test_id, status)
SELECT lab_order_id, 
    (SELECT lab_test_id FROM lab_tests ORDER BY RANDOM() LIMIT 1),
    'PENDING'
FROM patient_lab_orders;

-- Insert sample lab results
INSERT INTO lab_results (lab_order_detail_id, result_value, result_unit, reference_range, is_abnormal, result_date)
SELECT lab_order_detail_id, 
    '5.0', 'mg/dL', '4.0-6.0', FALSE, '2022-01-02'
FROM lab_order_details;

-- Insert sample vital signs
INSERT INTO vital_signs (patient_id, recorded_at, temperature, heart_rate, respiratory_rate, blood_pressure_systolic, blood_pressure_diastolic, oxygen_saturation, height, weight, bmi, pain_score)
SELECT patient_id, 
    '2022-01-01'::date + (ROW_NUMBER() OVER (ORDER BY patient_id) * interval '1 day'),
    36.5, 70, 16, 120, 80, 98.0, 170, 70, 24.2, 0
FROM patients;

-- Insert sample vaccines
INSERT INTO vaccines (cvx_code, name, manufacturer, disease_target, series_count)
VALUES
    ('CVX001', 'COVID-19 Vaccine', 'Pfizer', 'COVID-19', 2),
    ('CVX002', 'Influenza Vaccine', 'Sanofi', 'Influenza', 1),
    ('CVX003', 'Hepatitis B Vaccine', 'Merck', 'Hepatitis B', 3),
    ('CVX004', 'MMR Vaccine', 'GSK', 'Measles, Mumps, Rubella', 2),
    ('CVX005', 'Tetanus Vaccine', 'Pfizer', 'Tetanus', 1);

-- Insert sample patient immunizations
INSERT INTO patient_immunizations (patient_id, vaccine_id, administration_date, dose_number, lot_number, administration_site, route)
SELECT patient_id, 
    (SELECT vaccine_id FROM vaccines ORDER BY RANDOM() LIMIT 1),
    '2022-01-01',
    1,
    'LOT123',
    'LEFT_ARM',
    'INTRAMUSCULAR'
FROM patients;

-- Insert sample family medical history
INSERT INTO family_medical_history (patient_id, relation_type, condition, age_at_diagnosis, is_deceased, age_at_death)
SELECT patient_id, 
    'MOTHER', 'Diabetes', 50, TRUE, 70
FROM patients
WHERE CAST('x' || substring(md5(patient_id::text), 1, 8) AS bit(32))::bigint % 5 = 0;

-- Insert sample patient cohorts
INSERT INTO patient_cohorts (cohort_name, description, created_by)
VALUES
    ('Diabetes Study', 'Patients with diabetes for epidemiological study', (SELECT provider_id FROM healthcare_providers ORDER BY RANDOM() LIMIT 1)),
    ('Hypertension Study', 'Patients with hypertension for epidemiological study', (SELECT provider_id FROM healthcare_providers ORDER BY RANDOM() LIMIT 1));

-- Insert sample cohort members
INSERT INTO cohort_members (cohort_id, patient_id, added_by)
SELECT cohort_id, patient_id, (SELECT provider_id FROM healthcare_providers ORDER BY RANDOM() LIMIT 1)
FROM patient_cohorts, patients
WHERE cohort_name = 'Diabetes Study' AND CAST('x' || substring(md5(patient_id::text), 1, 8) AS bit(32))::bigint % 2 = 0
UNION ALL
SELECT cohort_id, patient_id, (SELECT provider_id FROM healthcare_providers ORDER BY RANDOM() LIMIT 1)
FROM patient_cohorts, patients
WHERE cohort_name = 'Hypertension Study' AND CAST('x' || substring(md5(patient_id::text), 1, 8) AS bit(32))::bigint % 3 = 0;

-- Insert sample geographic regions
INSERT INTO geographic_regions (region_name, region_type, population)
VALUES
    ('New York City', 'CITY', 8419000),
    ('Los Angeles', 'CITY', 3980000),
    ('Chicago', 'CITY', 2716000),
    ('Houston', 'CITY', 2328000),
    ('Phoenix', 'CITY', 1690000);