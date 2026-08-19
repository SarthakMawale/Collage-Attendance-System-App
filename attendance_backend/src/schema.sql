-- ============================================================================
--  SAFE SCHEMA MIGRATION (No Errors)
-- ============================================================================

-- ── CREATE TABLES IF NOT EXISTS ──────────────────────────────────────

-- USERS
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    role            TEXT NOT NULL CHECK (role IN ('ADMIN', 'TEACHER', 'STUDENT')),
    is_super_admin  BOOLEAN NOT NULL DEFAULT FALSE,
    roll_no         TEXT,
    mobile          TEXT,
    photo           TEXT,
    class_name      TEXT,
    subject         TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- CLASSES
CREATE TABLE IF NOT EXISTS classes (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    semester    TEXT,
    teacher_id  INTEGER REFERENCES users(id) ON DELETE SET NULL,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- CLASS STUDENTS
CREATE TABLE IF NOT EXISTS class_students (
    id          SERIAL PRIMARY KEY,
    class_id    INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    student_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    roll_no     TEXT,
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (class_id, student_id)
);

-- ATTENDANCE
CREATE TABLE IF NOT EXISTS attendance (
    id          SERIAL PRIMARY KEY,
    student_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    teacher_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id    INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    subject     TEXT,
    status      TEXT NOT NULL CHECK (status IN ('Present', 'Absent', 'Late', 'Leave')),
    method      TEXT NOT NULL DEFAULT 'MANUAL' CHECK (method IN ('QR', 'MANUAL')),
    date        DATE NOT NULL,
    time        TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, class_id, subject, date)
);

-- NOTICES
CREATE TABLE IF NOT EXISTS notices (
    id          SERIAL PRIMARY KEY,
    title       TEXT NOT NULL,
    description TEXT,
    posted_by   TEXT,
    date        DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- LEAVE REQUESTS
CREATE TABLE IF NOT EXISTS leave_requests (
    id          SERIAL PRIMARY KEY,
    student_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason      TEXT NOT NULL,
    from_date   DATE NOT NULL,
    to_date     DATE NOT NULL,
    status      TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','REJECTED')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
--  CLASSROOM MANAGEMENT TABLES
-- ============================================================================

-- ── CLASSROOMS ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS classrooms (
    id              SERIAL PRIMARY KEY,
    room_number     TEXT NOT NULL UNIQUE,
    building        TEXT,
    floor           INTEGER,
    capacity        INTEGER DEFAULT 30,
    has_projector   BOOLEAN DEFAULT FALSE,
    has_whiteboard  BOOLEAN DEFAULT TRUE,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── TEACHER CLASSROOMS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS teacher_classrooms (
    id              SERIAL PRIMARY KEY,
    teacher_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    classroom_id    INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
    subject         TEXT,
    is_primary      BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (teacher_id, classroom_id)
);

-- attendance_backend/src/schema.sql

-- ── TEACHER CLASS ASSIGNMENTS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS teacher_class_assignments (
    id          SERIAL PRIMARY KEY,
    teacher_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id    INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    subject     TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (teacher_id, class_id)
);

-- ✅ Add index for performance
CREATE INDEX IF NOT EXISTS idx_teacher_class_assignments_teacher ON teacher_class_assignments (teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_class_assignments_class ON teacher_class_assignments (class_id);
-- ✅ Update classes table to have teacher_id
ALTER TABLE classes ADD COLUMN IF NOT EXISTS teacher_id INTEGER REFERENCES users(id) ON DELETE SET NULL;


-- ============================================================
--  ATTENDANCE WITH UNIQUE CONSTRAINT - No Duplicate
-- ============================================================

-- ✅ Unique constraint already exists in schema.sql
-- UNIQUE (student_id, class_id, subject, date)

-- ✅ Add QR session tracking table
CREATE TABLE IF NOT EXISTS qr_sessions (
    id          SERIAL PRIMARY KEY,
    student_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id    INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    qr_token    TEXT NOT NULL,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at  TIMESTAMPTZ NOT NULL,
    is_used     BOOLEAN DEFAULT FALSE,
    used_at     TIMESTAMPTZ,
    UNIQUE (student_id, class_id, qr_token)
);

-- ✅ Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_qr_sessions_token ON qr_sessions (qr_token);
CREATE INDEX IF NOT EXISTS idx_qr_sessions_expires ON qr_sessions (expires_at);


-- ============================================================
--  NEW TABLES FOR CLASS-WISE STUDENT MANAGEMENT
-- ============================================================

-- ── STUDENT CATEGORIES ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS student_categories (
    id          SERIAL PRIMARY KEY,
    class_id    INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    category    TEXT NOT NULL CHECK (category IN ('BOYS', 'GIRLS', 'ALL')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (class_id, category)
);

-- ── STUDENT DETAILS (Extended) ─────────────────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('MALE', 'FEMALE', 'OTHER'));
ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS parent_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS parent_phone TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS admission_date DATE;
-- Add column to track if student is registered
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_registered BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS registered_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS permanent_qr_token TEXT;
-- Add is_registered column to users table


-- Add registered_at column to track when student was registered


-- Add permanent_qr_token column to store the permanent QR token

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_is_registered ON users (is_registered);

-- ── STUDENT ATTENDANCE SUMMARY (Materialized View for performance) ──
CREATE MATERIALIZED VIEW IF NOT EXISTS student_attendance_summary AS
SELECT 
    s.id AS student_id,
    s.name AS student_name,
    s.roll_no,
    s.class_name,
    s.gender,
    COUNT(a.id) AS total_classes,
    COUNT(CASE WHEN a.status = 'Present' THEN 1 END) AS present_count,
    COUNT(CASE WHEN a.status = 'Absent' THEN 1 END) AS absent_count,
    COUNT(CASE WHEN a.status = 'Late' THEN 1 END) AS late_count,
    COUNT(CASE WHEN a.status = 'Leave' THEN 1 END) AS leave_count,
    ROUND(CAST(COUNT(CASE WHEN a.status = 'Present' THEN 1 END) AS DECIMAL) / NULLIF(COUNT(a.id), 0) * 100, 2) AS attendance_percentage
FROM users s
LEFT JOIN attendance a ON a.student_id = s.id
WHERE s.role = 'STUDENT' AND s.is_active = TRUE
GROUP BY s.id, s.name, s.roll_no, s.class_name, s.gender;


-- ============================================================
--  REPORTING TABLES
-- ============================================================

-- ── DAILY ATTENDANCE SUMMARY ──────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_attendance_summary (
    id              SERIAL PRIMARY KEY,
    date            DATE NOT NULL,
    class_id        INTEGER REFERENCES classes(id),
    total_students  INTEGER DEFAULT 0,
    present_count   INTEGER DEFAULT 0,
    absent_count    INTEGER DEFAULT 0,
    late_count      INTEGER DEFAULT 0,
    leave_count     INTEGER DEFAULT 0,
    percentage      DECIMAL(5,2) DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE (date, class_id)
);

-- ── MONTHLY ATTENDANCE SUMMARY ──────────────────────────────
CREATE TABLE IF NOT EXISTS monthly_attendance_summary (
    id              SERIAL PRIMARY KEY,
    month           INTEGER NOT NULL,
    year            INTEGER NOT NULL,
    class_id        INTEGER REFERENCES classes(id),
    total_days      INTEGER DEFAULT 0,
    total_present   INTEGER DEFAULT 0,
    total_absent    INTEGER DEFAULT 0,
    average_percentage DECIMAL(5,2) DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE (month, year, class_id)
);

-- ── EXPORT LOGS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS export_logs (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER REFERENCES users(id),
    export_type     TEXT NOT NULL CHECK (export_type IN ('CSV', 'PDF', 'EXCEL')),
    report_type     TEXT NOT NULL,
    filters         JSONB,
    file_name       TEXT,
    exported_at     TIMESTAMPTZ DEFAULT now()
);




-- ── PERIODS ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS periods (
    id              SERIAL PRIMARY KEY,
    day_of_week     INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    period_number   INTEGER NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    UNIQUE (day_of_week, period_number)
);

-- ── TEACHER SCHEDULE ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS teacher_schedule (
    id                  SERIAL PRIMARY KEY,
    teacher_id          INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    classroom_id        INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
    period_id           INTEGER NOT NULL REFERENCES periods(id) ON DELETE CASCADE,
    class_id            INTEGER REFERENCES classes(id) ON DELETE SET NULL,
    subject             TEXT,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (teacher_id, classroom_id, period_id)
);

-- ── ALTER CLASSES TABLE ─────────────────────────────────────────────
DO $$ 
BEGIN
    BEGIN
        ALTER TABLE classes ADD COLUMN classroom_id INTEGER REFERENCES classrooms(id) ON DELETE SET NULL;
    EXCEPTION
        WHEN duplicate_column THEN
            RAISE NOTICE '✅ column classroom_id already exists';
    END;
END $$;

DO $$ 
BEGIN
    BEGIN
        ALTER TABLE classes ADD COLUMN room_number TEXT;
    EXCEPTION
        WHEN duplicate_column THEN
            RAISE NOTICE '✅ column room_number already exists';
    END;
END $$;


-- ── INDEXES ──────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_users_email_lower ON users (LOWER(email));
CREATE INDEX IF NOT EXISTS idx_users_role ON users (role);
CREATE INDEX IF NOT EXISTS idx_users_roll_no ON users (roll_no);
CREATE UNIQUE INDEX IF NOT EXISTS idx_only_one_super_admin ON users (is_super_admin) WHERE is_super_admin = TRUE;

CREATE INDEX IF NOT EXISTS idx_class_students_class ON class_students (class_id);
CREATE INDEX IF NOT EXISTS idx_class_students_student ON class_students (student_id);

CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance (student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance (date);

-- ── INDEXES ──────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_teacher_classrooms_teacher ON teacher_classrooms (teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_classrooms_classroom ON teacher_classrooms (classroom_id);
CREATE INDEX IF NOT EXISTS idx_teacher_schedule_teacher ON teacher_schedule (teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_schedule_period ON teacher_schedule (period_id);
CREATE INDEX IF NOT EXISTS idx_teacher_schedule_class ON teacher_schedule (class_id);

-- ── INDEXES ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_users_gender ON users (gender);
CREATE INDEX IF NOT EXISTS idx_users_class_name ON users (class_name);
CREATE INDEX IF NOT EXISTS idx_users_roll_no ON users (roll_no);

-- ── INDEXES ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_daily_summary_date ON daily_attendance_summary (date);
CREATE INDEX IF NOT EXISTS idx_monthly_summary_month ON monthly_attendance_summary (month, year);
CREATE INDEX IF NOT EXISTS idx_export_logs_user ON export_logs (user_id);


-- ── TRIGGER FUNCTION ──────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION touch_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_classrooms_updated_at ON classrooms;
CREATE TRIGGER trg_classrooms_updated_at
    BEFORE UPDATE ON classrooms
    FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ── SAMPLE PERIODS ──────────────────────────────────────────────────

INSERT INTO periods (day_of_week, period_number, start_time, end_time) VALUES
    (1, 1, '08:00', '08:50'),
    (1, 2, '08:50', '09:40'),
    (1, 3, '09:40', '10:30'),
    (1, 4, '10:45', '11:35'),
    (1, 5, '11:35', '12:25'),
    (1, 6, '12:25', '13:15'),
    (1, 7, '14:00', '14:50'),
    (1, 8, '14:50', '15:40'),
    (1, 9, '15:40', '16:30')
ON CONFLICT (day_of_week, period_number) DO NOTHING;

INSERT INTO periods (day_of_week, period_number, start_time, end_time)
SELECT 2, period_number, start_time, end_time FROM periods WHERE day_of_week = 1
ON CONFLICT (day_of_week, period_number) DO NOTHING;

INSERT INTO periods (day_of_week, period_number, start_time, end_time)
SELECT 3, period_number, start_time, end_time FROM periods WHERE day_of_week = 1
ON CONFLICT (day_of_week, period_number) DO NOTHING;

INSERT INTO periods (day_of_week, period_number, start_time, end_time)
SELECT 4, period_number, start_time, end_time FROM periods WHERE day_of_week = 1
ON CONFLICT (day_of_week, period_number) DO NOTHING;

INSERT INTO periods (day_of_week, period_number, start_time, end_time)
SELECT 5, period_number, start_time, end_time FROM periods WHERE day_of_week = 1
ON CONFLICT (day_of_week, period_number) DO NOTHING;

INSERT INTO periods (day_of_week, period_number, start_time, end_time)
SELECT 6, period_number, start_time, end_time FROM periods WHERE day_of_week = 1
ON CONFLICT (day_of_week, period_number) DO NOTHING;

INSERT INTO periods (day_of_week, period_number, start_time, end_time)
SELECT 7, period_number, start_time, end_time FROM periods WHERE day_of_week = 1
ON CONFLICT (day_of_week, period_number) DO NOTHING;

-- ── SUPER ADMIN ──────────────────────────────────────────────────────

INSERT INTO users (name, email, password_hash, role, is_super_admin, is_active)
VALUES (
    'Sarthak Bhawsar',
    'sarthakbhawsar8@gmail.com',
    '$2a$12$M9fYxKqJxvCq5XQ9ZQnL2OeP9xYxKqJxvCq5XQ9ZQnL2OeP9xYx',
    'ADMIN',
    TRUE,
    TRUE
) ON CONFLICT (email) DO NOTHING;