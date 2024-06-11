-- Add patient
INSERT INTO "patients"("first_name", "last_name", "gender", "birth_date", "comments")
VALUES("Joe", "Johnson", "Male", "1990-01-01", "None");

-- Add doctor
INSERT INTO "doctors"("first_name", "last_name", "specialization")
VALUES("Ben", "Smith", "Internist");

-- Add bed
INSERT INTO "beds"("room", "department")
VALUES(101, "internal_medicine");

-- Insert patients stay into the occupancy log
INSERT INTO "occupancy_log"("patient_id", "doctor_id", "bed_id", "registration_date", "planned_discharge", "discharge_date", "comments")
VALUES(1, 1, 1, "2024-01-01", "2024-01-10", "2024-01-11", "None");

-- Insert observation on patient
INSERT INTO "patients_log"("patient_id", "doctor_id", "observations")
VALUES(1, 1, "Patient is stable");

-- Select all of the patients who are currently in the hospital
SELECT * FROM "current_patients";

-- Select all of the patients led by chosen doctor who are currently in the hospital
SELECT * FROM "current_patients"
WHERE "doctor_id" == 1;

-- Select all of the patients to be discharged today
SELECT * FROM "to_be_discharged";

-- Select all of the patients to be registered today
SELECT * FROM "to_be_registered";

-- Select all of the beds that are currently free
SELECT * FROM "beds"
WHERE "occupancy" == 0;

-- Select chosen patient treatment history
SELECT * FROM "patients_log"
WHERE "patient_id" == 1;


