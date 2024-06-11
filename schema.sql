-- Create table with the data on all of hospital patients.
CREATE TABLE IF NOT EXISTS patients (
    "id" INTEGER,
    "first_name" TEXT,
    "last_name" TEXT,
    "gender" TEXT CHECK("gender" IN ('Male', 'Female', 'Other')),
    "birth_date" NUMERIC,
    "comments" TEXT,
    PRIMARY KEY("id")
);

-- Create table with the data on all of hospital doctors;
CREATE TABLE IF NOT EXISTS doctors (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "specialization" TEXT NOT NULL,
    PRIMARY KEY("id")
);

-- Create table with all the beds available in hospital. Including occupancy column with values based on the
-- occupancy log. Applicable triggers later on.
CREATE TABLE IF NOT EXISTS beds (
    "id" INTEGER,
    "room" INTEGER NOT NULL,
    "department" TEXT NOT NULL,
    "occupancy" INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY("id")
);

-- Create occupancy log with the data on each patient visit in hospital. Dates overlaping occupancy of the same bed
-- resticted by applicable trigger later on.
CREATE TABLE IF NOT EXISTS occupancy_log (
    "id" INTEGER,
    "patient_id" INTEGER,
    "doctor_id" INTEGER,
    "bed_id" INTEGER,
    "registration_date" NUMERIC NOT NULL,
    "planned_discharge" NUMERIC,
    "discharge_date" NUMERIC,
    "comments" TEXT,
    PRIMARY KEY("id"),
    FOREIGN KEY("patient_id") REFERENCES "patients"("id"),
    FOREIGN KEY("doctor_id") REFERENCES "doctors"("id"),
    FOREIGN KEY("bed_id") REFERENCES "beds"("id")
);

-- Create patient log with the data on tratment of every patient in the hospital. Entries done only by leading doctors.
CREATE TABLE IF NOT EXISTS patients_log (
    "id" INTEGER,
    "patient_id" INTEGER,
    "doctor_id" INTEGER,
    "entry_date" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "observations" TEXT NOT NULL,
    PRIMARY KEY("id"),
    FOREIGN KEY("patient_id") REFERENCES "patients"("id"),
    FOREIGN KEY("doctor_id") REFERENCES "doctors"("id")
);

-- Create trigger that will update 'occupancy' column in 'beds' table when insert in the occupancy log is done.
CREATE TRIGGER IF NOT EXISTS update_occupancy_insert
AFTER INSERT ON "occupancy_log"
FOR EACH ROW
BEGIN
    UPDATE "beds"
    SET "occupancy" = (
        SELECT CASE
            WHEN EXISTS (
                SELECT 1
                FROM "occupancy_log"
                WHERE "bed_id" = NEW."bed_id"
                AND "registration_date" <= DATE('now')
                AND ("discharge_date" IS NULL OR "discharge_date" > DATE('now'))
            ) THEN 1
            ELSE 0
        END
    )
    WHERE "id" = NEW."bed_id";
END;

-- Create trigger that will update 'occupancy' column in 'beds' table when update on the occupancy log is done.
CREATE TRIGGER IF NOT EXISTS update_occupancy_update
AFTER UPDATE ON "occupancy_log"
FOR EACH ROW
BEGIN
    UPDATE "beds"
    SET "occupancy" = (
        SELECT CASE
            WHEN EXISTS (
                SELECT 1
                FROM "occupancy_log"
                WHERE "bed_id" = NEW."bed_id"
                AND "registration_date" <= DATE('now')
                AND ("discharge_date" IS NULL OR "discharge_date" > DATE('now'))
            ) THEN 1
            ELSE 0
        END
    )
    WHERE "id" = NEW."bed_id";
END;

-- Create trigger that will update 'occupancy' column in 'beds' table when delete from the occupancy log is done.
CREATE TRIGGER IF NOT EXISTS update_occupancy_delete
AFTER DELETE ON "occupancy_log"
FOR EACH ROW
BEGIN
    UPDATE "beds"
    SET "occupancy" = (
        SELECT CASE
            WHEN EXISTS (
                SELECT 1
                FROM "occupancy_log"
                WHERE "bed_id" = OLD."bed_id"
                AND "registration_date" <= DATE('now')
                AND ("discharge_date" IS NULL OR "discharge_date" > DATE('now'))
            ) THEN 1
            ELSE 0
        END
    )
    WHERE "id" = OLD."bed_id";
END;

-- Create trigger that will check if entry to the occupancy log is not overlapping existing reservations.
CREATE TRIGGER IF NOT EXISTS check_duplicate_occupancy
BEFORE INSERT ON "occupancy_log"
FOR EACH ROW
WHEN EXISTS (
    SELECT 1
    FROM "occupancy_log"
    WHERE "bed_id" = NEW."bed_id"
    AND "registration_date" <= NEW."discharge_date"
    AND "discharge_date" >= NEW."registration_date"
    AND (id <> NEW."id" OR NEW."id" IS NULL)
)
BEGIN
    SELECT RAISE(ABORT, 'This bed is already occupied within chosen dates');
END;

-- Create view showing all of the beds occupied at the time with patient names.
CREATE VIEW IF NOT EXISTS current_patients AS
SELECT "beds"."id", "beds"."room", "beds"."department", "patients"."first_name", "patients"."last_name", "occupancy_log"."doctor_id"
FROM "beds"
JOIN "occupancy_log" ON "beds"."id" = "occupancy_log"."bed_id"
JOIN "patients" ON "occupancy_log"."patient_id" = "patients"."id"
WHERE "beds"."occupancy" == 1
AND "occupancy_log"."registration_date" <= DATE('now')
AND "occupancy_log"."discharge_date" >= DATE('now');

-- Create view showing all of the patients to be discharged today.
CREATE VIEW IF NOT EXISTS to_be_discharged AS
SELECT "beds"."id", "beds"."room", "beds"."department", "patients"."first_name", "patients"."last_name", "occupancy_log"."doctor_id"
FROM "beds"
JOIN "occupancy_log" ON "beds"."id" = "occupancy_log"."bed_id"
JOIN "patients" ON "occupancy_log"."patient_id" = "patients"."id"
WHERE "occupancy_log"."discharge_date" == DATE('now');

-- Create view showing all of the patients to be registered today.
CREATE VIEW IF NOT EXISTS to_be_registered AS
SELECT "beds"."id", "beds"."room", "beds"."department", "patients"."first_name", "patients"."last_name", "occupancy_log"."doctor_id"
FROM "beds"
JOIN "occupancy_log" ON "beds"."id" = "occupancy_log"."bed_id"
JOIN "patients" ON "occupancy_log"."patient_id" = "patients"."id"
WHERE "occupancy_log"."registration_date" == DATE('now');

-- Create index preventing beds status queries from scanning whole `beds` table.
CREATE INDEX IF NOT EXISTS "beds_occupancy" ON "beds"("occupancy");

-- Create index enabling searching all of the patients to be registered given day to the hospital.
CREATE INDEX IF NOT EXISTS "registrations" ON "occupancy_log"("registration_date");

-- Create index enabling searching all of the patients to be discharged given day from the hospital.
CREATE INDEX IF NOT EXISTS "discharges" ON "occupancy_log"("discharge_date");

-- Create index enabling fast search of current patients of given doctor.
CREATE INDEX IF NOT EXISTS "doctor_patients" ON "occupancy_log"("doctor_id");

-- Create index enabling fast search of whole treatment history of chosen patient.
CREATE INDEX IF NOT EXISTS "patients_history" ON "patients_log"("patient_id");
