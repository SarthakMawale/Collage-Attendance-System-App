// attendance_backend/src/server.js

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('./db');
const { signToken, requireAuth, requireRole , JWT_SECRET} = require('./auth');

const app = express();



// ✅ UPDATED CORS - Allow all origins (for public access)
app.use(cors({
  origin: '*',  // Allow all origins
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
}));

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept');
  res.header('Access-Control-Allow-Credentials', 'true');
  
  // Handle pre-flight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  next();
});

// ✅ Pre-flight requests handle karein
// app.options('*', cors());

app.use(express.json({ limit: '50mb' })); // ✅ Allow large payload (for images)

const PORT = process.env.PORT || 4000;





// ✅ Health Check - Important for Render
app.get('/health', (_req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// ✅ Root endpoint
app.get('/', (_req, res) => {
  res.json({ 
    message: '🎓 College Attendance API',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      auth: '/auth/login, /auth/me, /auth/change-password',
      users: '/users, /users/:id',
      classes: '/classes, /classes/:id',
      attendance: '/attendance, /attendance/student/:id',
      notices: '/notices'
    }
  });
});

// ✅ Check if JWT_SECRET is defined
if (!JWT_SECRET) {
    console.error('❌ JWT_SECRET is not defined!');
    console.error('⚠️ Please check your .env file');
    process.exit(1);
}
console.log('✅ JWT_SECRET is defined');



// Shape a DB row into the JSON the Flutter app expects (camelCase).
function toClientUser(row) {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    role: row.role,
    isSuperAdmin: row.is_super_admin,
    rollNo: row.roll_no,
    mobile: row.mobile,
    photo: row.photo,
    className: row.class_name,
    subject: row.subject,
    isActive: row.is_active,
  };
}

// ─────────────────────────────────────────────────────────────────────────
//  AUTH
// ─────────────────────────────────────────────────────────────────────────

// POST /auth/login  { emailOrRoll, password, role }
// Role sent by client is NEVER trusted for authorization — it's only used
// to disambiguate roll-number logins. Actual role comes from the DB row.
app.post('/auth/login', async (req, res) => {
  const { emailOrRoll, password } = req.body;
  if (!emailOrRoll || !password) {
    return res.status(400).json({ error: 'emailOrRoll and password are required' });
  }

  try {
    const { rows } = await pool.query(
      `SELECT * FROM users
       WHERE is_active = TRUE
         AND (LOWER(email) = LOWER($1) OR roll_no = $1)
       LIMIT 1`,
      [emailOrRoll]
    );

    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = rows[0];
    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = signToken(user);
    res.json({ token, user: toClientUser(user) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Login failed' });
  }
});

// GET /auth/me — re-initialize app state from a stored token (session restore)
app.get('/auth/me', requireAuth, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT * FROM users WHERE id = $1 AND is_active = TRUE',
      [req.user.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json({ user: toClientUser(rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// POST /auth/change-password
app.post('/auth/change-password', requireAuth, async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword || newPassword.length < 6) {
    return res.status(400).json({ error: 'Invalid password payload' });
  }
  try {
    const { rows } = await pool.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    const user = rows[0];
    const match = await bcrypt.compare(currentPassword, user.password_hash);
    if (!match) return res.status(401).json({ error: 'Current password is incorrect' });

    const hash = await bcrypt.hash(newPassword, 12);
    await pool.query('UPDATE users SET password_hash = $1 WHERE id = $2', [hash, req.user.id]);
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to change password' });
  }
});


// ─────────────────────────────────────────────────────────────────────────
//  USER MANAGEMENT (Admin / Super Admin only)
// ─────────────────────────────────────────────────────────────────────────

// GET /users?role=TEACHER|STUDENT|ADMIN
app.get('/users', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { role } = req.query;
  try {
    const { rows } = role
      ? await pool.query(
          'SELECT * FROM users WHERE role = $1 AND is_active = TRUE ORDER BY name',
          [role]
        )
      : await pool.query('SELECT * FROM users WHERE is_active = TRUE ORDER BY name');
    res.json({ users: rows.map(toClientUser) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// POST /users — create Admin, Teacher, or Student
// Only the super admin may create another ADMIN account.
app.post('/users', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { name, email, password, role, rollNo, mobile, photo, className, subject } = req.body;

  if (!name || !email || !password || !role) {
    return res.status(400).json({ error: 'name, email, password, role are required' });
  }
  if (!['ADMIN', 'TEACHER', 'STUDENT'].includes(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }
  if (role === 'ADMIN' && !req.user.isSuperAdmin) {
    return res.status(403).json({ error: 'Only the super admin can create admin accounts' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  try {
    const hash = await bcrypt.hash(password, 12);
    const { rows } = await pool.query(
      `INSERT INTO users (name, email, password_hash, role, roll_no, mobile, photo, class_name, subject)
       VALUES ($1, LOWER($2), $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [name, email, hash, role, rollNo || null, mobile || null, photo || null, className || null, subject || null]
    );
    res.status(201).json({ user: toClientUser(rows[0]) });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Email already exists' });
    }
    console.error(err);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// PUT /users/:id
app.put('/users/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { id } = req.params;
  const { name, mobile, photo, className, subject, rollNo } = req.body;

  try {
    const target = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    if (target.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    if (target.rows[0].is_super_admin && !req.user.isSuperAdmin) {
      return res.status(403).json({ error: 'Cannot modify the super admin' });
    }

    const { rows } = await pool.query(
      `UPDATE users SET
         name = COALESCE($1, name),
         mobile = COALESCE($2, mobile),
         photo = COALESCE($3, photo),
         class_name = COALESCE($4, class_name),
         subject = COALESCE($5, subject),
         roll_no = COALESCE($6, roll_no)
       WHERE id = $7
       RETURNING *`,
      [name, mobile, photo, className, subject, rollNo, id]
    );
    res.json({ user: toClientUser(rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// DELETE /users/:id — soft delete (isActive = false). Super admin is protected.
app.delete('/users/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { id } = req.params;
  try {
    const target = await pool.query('SELECT is_super_admin FROM users WHERE id = $1', [id]);
    if (target.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    if (target.rows[0].is_super_admin) {
      return res.status(403).json({ error: 'The super admin account cannot be deleted' });
    }

    await pool.query('UPDATE users SET is_active = FALSE WHERE id = $1', [id]);
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});




// ============================================================
//  STUDENT MANAGEMENT - CLASS WISE
// ============================================================

// ── GET STUDENTS BY CLASS WITH FILTERS ─────────────────────
app.get('/students/by-class', requireAuth, requireRole('ADMIN', 'TEACHER'), async (req, res) => {
    const { classId, category, gender, attendanceRange, search } = req.query;

    try {
        let query = `
            SELECT 
                u.id, u.name, u.email, u.roll_no, u.mobile, u.photo,
                u.class_name, u.gender, u.date_of_birth, u.address,
                u.parent_name, u.parent_phone, u.admission_date,
                COALESCE(sas.total_classes, 0) AS total_classes,
                COALESCE(sas.present_count, 0) AS present_count,
                COALESCE(sas.absent_count, 0) AS absent_count,
                COALESCE(sas.late_count, 0) AS late_count,
                COALESCE(sas.leave_count, 0) AS leave_count,
                COALESCE(sas.attendance_percentage, 0) AS attendance_percentage
            FROM users u
            LEFT JOIN student_attendance_summary sas ON sas.student_id = u.id
            WHERE u.role = 'STUDENT' AND u.is_active = TRUE
        `;

        const params = [];
        let paramIndex = 1;

        // Class filter
        if (classId) {
            query += ` AND u.class_name = (SELECT name FROM classes WHERE id = $${paramIndex})`;
            params.push(classId);
            paramIndex++;
        }

        // Category filter (Boys/Girls)
        if (gender && gender !== 'ALL') {
            query += ` AND u.gender = $${paramIndex}`;
            params.push(gender);
            paramIndex++;
        }

        // Attendance range filter
        if (attendanceRange) {
            const [min, max] = attendanceRange.split('-').map(Number);
            if (min !== undefined && max !== undefined) {
                query += ` AND COALESCE(sas.attendance_percentage, 0) BETWEEN $${paramIndex} AND $${paramIndex + 1}`;
                params.push(min, max);
                paramIndex += 2;
            }
        }

        // Search
        if (search) {
            query += ` AND (u.name ILIKE $${paramIndex} OR u.roll_no ILIKE $${paramIndex} OR u.email ILIKE $${paramIndex})`;
            params.push(`%${search}%`);
            paramIndex++;
        }

        query += ` ORDER BY u.name ASC`;

        const { rows } = await pool.query(query, params);
        res.json({ students: rows });

    } catch (err) {
        console.error('Error fetching students by class:', err);
        res.status(500).json({ error: 'Failed to fetch students' });
    }
});

// ── GET CLASS CATEGORIES ─────────────────────────────────────
app.get('/classes/:classId/categories', requireAuth, requireRole('ADMIN', 'TEACHER'), async (req, res) => {
    const { classId } = req.params;

    try {
        // Get class name
        const classResult = await pool.query(
            'SELECT name FROM classes WHERE id = $1 AND is_active = TRUE',
            [classId]
        );

        if (classResult.rows.length === 0) {
            return res.status(404).json({ error: 'Class not found' });
        }

        const className = classResult.rows[0].name;

        // Get student counts by gender
        const { rows } = await pool.query(
            `SELECT 
                COUNT(*) FILTER (WHERE gender = 'MALE') AS boys,
                COUNT(*) FILTER (WHERE gender = 'FEMALE') AS girls,
                COUNT(*) FILTER (WHERE gender IS NULL OR gender = 'OTHER') AS others,
                COUNT(*) AS total
             FROM users
             WHERE role = 'STUDENT' AND is_active = TRUE AND class_name = $1`,
            [className]
        );

        // Get attendance summary
        const attendanceSummary = await pool.query(
            `SELECT 
                COUNT(*) FILTER (WHERE attendance_percentage >= 75) AS excellent,
                COUNT(*) FILTER (WHERE attendance_percentage >= 60 AND attendance_percentage < 75) AS good,
                COUNT(*) FILTER (WHERE attendance_percentage >= 40 AND attendance_percentage < 60) AS average,
                COUNT(*) FILTER (WHERE attendance_percentage < 40) AS poor
             FROM student_attendance_summary
             WHERE class_name = $1`,
            [className]
        );

        res.json({
            classId: parseInt(classId),
            className: className,
            counts: rows[0] || { boys: 0, girls: 0, others: 0, total: 0 },
            attendance: attendanceSummary.rows[0] || { excellent: 0, good: 0, average: 0, poor: 0 }
        });

    } catch (err) {
        console.error('Error fetching categories:', err);
        res.status(500).json({ error: 'Failed to fetch categories' });
    }
});

// ── GET ALL CLASSES WITH STUDENT COUNTS ────────────────────
app.get('/classes/with-counts', requireAuth, requireRole('ADMIN', 'TEACHER'), async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT 
                c.id,
                c.name,
                c.semester,
                COUNT(u.id) AS total_students,
                COUNT(u.id) FILTER (WHERE u.gender = 'MALE') AS boys,
                COUNT(u.id) FILTER (WHERE u.gender = 'FEMALE') AS girls,
                COALESCE(SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END), 0) AS total_present
             FROM classes c
             LEFT JOIN users u ON u.class_name = c.name AND u.role = 'STUDENT' AND u.is_active = TRUE
             LEFT JOIN attendance a ON a.student_id = u.id
             WHERE c.is_active = TRUE
             GROUP BY c.id, c.name, c.semester
             ORDER BY c.name`
        );

        res.json({ classes: rows });

    } catch (err) {
        console.error('Error fetching classes with counts:', err);
        res.status(500).json({ error: 'Failed to fetch classes' });
    }
});

// ── UPDATE STUDENT CATEGORY ─────────────────────────────────
app.put('/students/:id/category', requireAuth, requireRole('ADMIN'), async (req, res) => {
    const { id } = req.params;
    const { category } = req.body;

    if (!['BOYS', 'GIRLS', 'ALL'].includes(category)) {
        return res.status(400).json({ error: 'Invalid category' });
    }

    try {
        // Check if student exists
        const studentCheck = await pool.query(
            'SELECT id FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
            [id, 'STUDENT']
        );

        if (studentCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Student not found' });
        }

        // Update or insert category
        await pool.query(
            `INSERT INTO student_categories (class_id, category)
             SELECT class_id, $1 FROM class_students WHERE student_id = $2
             ON CONFLICT (class_id, category) DO NOTHING`,
            [category, id]
        );

        res.json({ success: true, message: 'Student category updated' });

    } catch (err) {
        console.error('Error updating category:', err);
        res.status(500).json({ error: 'Failed to update category' });
    }
});

// ── GET STUDENT DETAILS WITH ATTENDANCE ────────────────────
app.get('/students/:id/details', requireAuth, async (req, res) => {
    const { id } = req.params;

    try {
        const { rows } = await pool.query(
            `SELECT 
                u.*,
                COALESCE(sas.total_classes, 0) AS total_classes,
                COALESCE(sas.present_count, 0) AS present_count,
                COALESCE(sas.absent_count, 0) AS absent_count,
                COALESCE(sas.late_count, 0) AS late_count,
                COALESCE(sas.leave_count, 0) AS leave_count,
                COALESCE(sas.attendance_percentage, 0) AS attendance_percentage
             FROM users u
             LEFT JOIN student_attendance_summary sas ON sas.student_id = u.id
             WHERE u.id = $1 AND u.role = 'STUDENT' AND u.is_active = TRUE`,
            [id]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Student not found' });
        }

        // Get recent attendance records
        const attendanceRecords = await pool.query(
            `SELECT a.date, a.status, a.subject, a.time, c.name AS class_name
             FROM attendance a
             LEFT JOIN classes c ON c.id = a.class_id
             WHERE a.student_id = $1
             ORDER BY a.date DESC, a.time DESC
             LIMIT 10`,
            [id]
        );

        res.json({
            student: rows[0],
            recentAttendance: attendanceRecords.rows
        });

    } catch (err) {
        console.error('Error fetching student details:', err);
        res.status(500).json({ error: 'Failed to fetch student details' });
    }
});



// ============================================================
//  REPORT ENDPOINTS
// ============================================================

// ── GET DAILY REPORT ──────────────────────────────────────────
app.get('/reports/daily', requireAuth, requireRole('ADMIN', 'TEACHER'), async (req, res) => {
    const { date, classId } = req.query;
    const reportDate = date || new Date().toISOString().split('T')[0];

    try {
        let query = `
            SELECT 
                c.id as class_id,
                c.name as class_name,
                COUNT(DISTINCT u.id) as total_students,
                COUNT(CASE WHEN a.status = 'Present' THEN 1 END) as present_count,
                COUNT(CASE WHEN a.status = 'Absent' THEN 1 END) as absent_count,
                COUNT(CASE WHEN a.status = 'Late' THEN 1 END) as late_count,
                COUNT(CASE WHEN a.status = 'Leave' THEN 1 END) as leave_count,
                ROUND(CAST(COUNT(CASE WHEN a.status = 'Present' THEN 1 END) AS DECIMAL) / 
                    NULLIF(COUNT(DISTINCT u.id), 0) * 100, 2) as percentage
            FROM classes c
            LEFT JOIN users u ON u.class_name = c.name AND u.role = 'STUDENT' AND u.is_active = TRUE
            LEFT JOIN attendance a ON a.student_id = u.id AND a.date = $1 AND a.class_id = c.id
            WHERE c.is_active = TRUE
        `;
        
        const params = [reportDate];
        let paramIndex = 2;

        if (classId) {
            query += ` AND c.id = $${paramIndex}`;
            params.push(classId);
            paramIndex++;
        }

        query += ` GROUP BY c.id, c.name ORDER BY c.name`;

        const { rows } = await pool.query(query, params);
        res.json({ 
            date: reportDate,
            classes: rows,
            summary: {
                total_classes: rows.length,
                total_students: rows.reduce((sum, r) => sum + Number(r.total_students), 0),
                total_present: rows.reduce((sum, r) => sum + Number(r.present_count), 0)
            }
        });

    } catch (err) {
        console.error('Daily report error:', err);
        res.status(500).json({ error: 'Failed to generate daily report' });
    }
});

// ── GET WEEKLY REPORT ─────────────────────────────────────────
app.get('/reports/weekly', requireAuth, requireRole('ADMIN', 'TEACHER'), async (req, res) => {
    const { classId } = req.query;
    
    try {
        const dates = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            dates.push(d.toISOString().split('T')[0]);
        }

        let query = `
            SELECT 
                a.date,
                COUNT(DISTINCT a.student_id) as total_students,
                COUNT(CASE WHEN a.status = 'Present' THEN 1 END) as present_count,
                ROUND(CAST(COUNT(CASE WHEN a.status = 'Present' THEN 1 END) AS DECIMAL) / 
                    NULLIF(COUNT(DISTINCT a.student_id), 0) * 100, 2) as percentage
            FROM attendance a
            WHERE a.date = ANY($1::text[])
        `;

        const params = [dates];
        let paramIndex = 2;

        if (classId) {
            query += ` AND a.class_id = $${paramIndex}`;
            params.push(classId);
            paramIndex++;
        }

        query += ` GROUP BY a.date ORDER BY a.date ASC`;

        const { rows } = await pool.query(query, params);
        res.json({ 
            dates: dates,
            data: rows
        });

    } catch (err) {
        console.error('Weekly report error:', err);
        res.status(500).json({ error: 'Failed to generate weekly report' });
    }
});

// ── GET MONTHLY REPORT ────────────────────────────────────────
app.get('/reports/monthly', requireAuth, requireRole('ADMIN', 'TEACHER'), async (req, res) => {
    const { month, year, classId } = req.query;
    const reportMonth = month || new Date().getMonth() + 1;
    const reportYear = year || new Date().getFullYear();

    try {
        let query = `
            SELECT 
                DATE_TRUNC('month', a.date) as month,
                COUNT(DISTINCT a.student_id) as total_students,
                COUNT(CASE WHEN a.status = 'Present' THEN 1 END) as present_count,
                COUNT(CASE WHEN a.status = 'Absent' THEN 1 END) as absent_count,
                COUNT(CASE WHEN a.status = 'Late' THEN 1 END) as late_count,
                COUNT(CASE WHEN a.status = 'Leave' THEN 1 END) as leave_count,
                ROUND(CAST(COUNT(CASE WHEN a.status = 'Present' THEN 1 END) AS DECIMAL) / 
                    NULLIF(COUNT(DISTINCT a.student_id), 0) * 100, 2) as percentage
            FROM attendance a
            WHERE EXTRACT(MONTH FROM a.date) = $1 AND EXTRACT(YEAR FROM a.date) = $2
        `;

        const params = [reportMonth, reportYear];
        let paramIndex = 3;

        if (classId) {
            query += ` AND a.class_id = $${paramIndex}`;
            params.push(classId);
            paramIndex++;
        }

        query += ` GROUP BY DATE_TRUNC('month', a.date)`;

        const { rows } = await pool.query(query, params);
        res.json({ 
            month: reportMonth,
            year: reportYear,
            data: rows[0] || { total_students: 0, present_count: 0, percentage: 0 }
        });

    } catch (err) {
        console.error('Monthly report error:', err);
        res.status(500).json({ error: 'Failed to generate monthly report' });
    }
});

// ── GET STUDENT-WISE REPORT ────────────────────────────────────
app.get('/reports/students', requireAuth, requireRole('ADMIN', 'TEACHER'), async (req, res) => {
    const { classId, sortBy, order } = req.query;
    const sortColumn = sortBy || 'attendance_percentage';
    const sortOrder = order || 'DESC';

    try {
        let query = `
            SELECT 
                u.id, u.name, u.email, u.roll_no, u.class_name,
                COALESCE(sas.total_classes, 0) as total_classes,
                COALESCE(sas.present_count, 0) as present_count,
                COALESCE(sas.absent_count, 0) as absent_count,
                COALESCE(sas.late_count, 0) as late_count,
                COALESCE(sas.leave_count, 0) as leave_count,
                COALESCE(sas.attendance_percentage, 0) as attendance_percentage
            FROM users u
            LEFT JOIN student_attendance_summary sas ON sas.student_id = u.id
            WHERE u.role = 'STUDENT' AND u.is_active = TRUE
        `;

        const params = [];

        if (classId) {
            query += ` AND u.class_name = (SELECT name FROM classes WHERE id = $1)`;
            params.push(classId);
        }

        query += ` ORDER BY ${sortColumn} ${sortOrder}`;

        const { rows } = await pool.query(query, params);
        res.json({ students: rows });

    } catch (err) {
        console.error('Student report error:', err);
        res.status(500).json({ error: 'Failed to generate student report' });
    }
});

// ── EXPORT CSV ──────────────────────────────────────────────────
app.get('/reports/export/csv', requireAuth, requireRole('ADMIN'), async (req, res) => {
    const { reportType, classId } = req.query;

    try {
        let data = [];
        let filename = `report_${reportType}_${new Date().toISOString().split('T')[0]}.csv`;

        if (reportType === 'students') {
            const result = await pool.query(
                `SELECT u.name, u.email, u.roll_no, u.class_name,
                        COALESCE(sas.attendance_percentage, 0) as attendance_percentage,
                        COALESCE(sas.total_classes, 0) as total_classes,
                        COALESCE(sas.present_count, 0) as present_count
                 FROM users u
                 LEFT JOIN student_attendance_summary sas ON sas.student_id = u.id
                 WHERE u.role = 'STUDENT' AND u.is_active = TRUE
                 ORDER BY u.name`
            );
            data = result.rows;
        } else if (reportType === 'classes') {
            const result = await pool.query(
                `SELECT c.name, c.semester,
                        COUNT(u.id) as total_students,
                        COALESCE(sas.attendance_percentage, 0) as avg_attendance
                 FROM classes c
                 LEFT JOIN users u ON u.class_name = c.name AND u.role = 'STUDENT' AND u.is_active = TRUE
                 LEFT JOIN student_attendance_summary sas ON sas.student_id = u.id
                 WHERE c.is_active = TRUE
                 GROUP BY c.name, c.semester`
            );
            data = result.rows;
        }

        // Generate CSV
        let csv = '';
        if (data.length > 0) {
            const headers = Object.keys(data[0]);
            csv += headers.join(',') + '\n';
            data.forEach(row => {
                csv += headers.map(h => `"${row[h] || ''}"`).join(',') + '\n';
            });
        }

        // Log export
        await pool.query(
            `INSERT INTO export_logs (user_id, export_type, report_type, filters, file_name)
             VALUES ($1, $2, $3, $4, $5)`,
            [req.user.id, 'CSV', reportType, JSON.stringify(req.query), filename]
        );

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
        res.send(csv);

    } catch (err) {
        console.error('Export CSV error:', err);
        res.status(500).json({ error: 'Failed to export CSV' });
    }
});

// ── GET GENDER ANALYTICS ───────────────────────────────────────
app.get('/reports/gender', requireAuth, requireRole('ADMIN'), async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT 
                COUNT(*) FILTER (WHERE gender = 'MALE') as boys,
                COUNT(*) FILTER (WHERE gender = 'FEMALE') as girls,
                COUNT(*) FILTER (WHERE gender IS NULL) as others,
                AVG(sas.attendance_percentage) FILTER (WHERE gender = 'MALE') as boys_attendance,
                AVG(sas.attendance_percentage) FILTER (WHERE gender = 'FEMALE') as girls_attendance
             FROM users u
             LEFT JOIN student_attendance_summary sas ON sas.student_id = u.id
             WHERE u.role = 'STUDENT' AND u.is_active = TRUE`
        );
        res.json({ data: rows[0] });
    } catch (err) {
        console.error('Gender analytics error:', err);
        res.status(500).json({ error: 'Failed to fetch gender analytics' });
    }
});
// ─────────────────────────────────────────────────────────────────────────
//  CLASSES
// ─────────────────────────────────────────────────────────────────────────

// attendance_backend/src/server.js - Update get classes endpoint

// attendance_backend/src/server.js

// GET /classes - Teacher ke liye filter
app.get('/classes', requireAuth, async (req, res) => {
  try {
    let query = `
      SELECT c.*, 
             COUNT(cs.id) AS student_count
      FROM classes c
      LEFT JOIN class_students cs ON cs.class_id = c.id
      WHERE c.is_active = TRUE
    `;
    
    const params = [];
    
    // ✅ Agar TEACHER hai toh sirf assigned classes dikhao
    if (req.user.role === 'TEACHER') {
      query += ` AND c.teacher_id = $1`;
      params.push(req.user.id);
    }
    
    query += ` GROUP BY c.id ORDER BY c.name`;
    
    const { rows } = await pool.query(query, params);
    
    res.json({
      classes: rows.map((r) => ({
        id: r.id,
        name: r.name,
        semester: r.semester,
        teacherId: r.teacher_id,
        students: Number(r.student_count || 0),
        isActive: r.is_active,
      })),
    });
  } catch (err) {
    console.error('Error fetching classes:', err);
    res.status(500).json({ error: 'Failed to fetch classes' });
  }
});

// attendance_backend/src/server.js

// GET /teacher/classes - Sirf teacher ki assigned classes
app.get('/teacher/classes', requireAuth, requireRole('TEACHER'), async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT c.*, 
              COUNT(cs.id) AS student_count
       FROM classes c
       LEFT JOIN class_students cs ON cs.class_id = c.id
       WHERE c.is_active = TRUE 
         AND c.teacher_id = $1
       GROUP BY c.id
       ORDER BY c.name`,
      [req.user.id]
    );
    
    res.json({
      classes: rows.map((r) => ({
        id: r.id,
        name: r.name,
        semester: r.semester,
        teacherId: r.teacher_id,
        students: Number(r.student_count || 0),
        isActive: r.is_active,
      })),
    });
  } catch (err) {
    console.error('Error fetching teacher classes:', err);
    res.status(500).json({ error: 'Failed to fetch teacher classes' });
  }
});

// attendance_backend/src/server.js

// POST /classes - Admin se class create karega aur teacher assign karega
app.post('/classes', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { name, semester, teacherId } = req.body;
  
  console.log(`📝 Creating class: ${name}, Teacher: ${teacherId}`);
  
  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  try {
    // ✅ Step 1: Class create karo
    const { rows } = await pool.query(
      `INSERT INTO classes (name, semester, teacher_id)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [name, semester || null, teacherId || null]
    );
    
    const newClass = rows[0];
    console.log(`✅ Class created: ${newClass.id} - ${newClass.name}`);

    // ✅ Step 2: Agar teacherId diya hai toh teacher_class_assignments mein bhi entry karo
    if (teacherId) {
      // Check if teacher exists
      const teacherCheck = await pool.query(
        'SELECT id, name FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
        [teacherId, 'TEACHER']
      );
      
      if (teacherCheck.rows.length > 0) {
        // Check if already assigned
        const existing = await pool.query(
          'SELECT id FROM teacher_class_assignments WHERE teacher_id = $1 AND class_id = $2 AND is_active = TRUE',
          [teacherId, newClass.id]
        );
        
        if (existing.rows.length === 0) {
          await pool.query(
            `INSERT INTO teacher_class_assignments (teacher_id, class_id, subject)
             VALUES ($1, $2, $3)`,
            [teacherId, newClass.id, null]
          );
          console.log(`✅ Teacher ${teacherId} assigned to class ${newClass.id}`);
        }
      }
    }

    res.status(201).json({ classItem: newClass });
  } catch (err) {
    console.error('Create class error:', err);
    res.status(500).json({ error: 'Failed to create class' });
  }
});


// ============================================================
//  QR CODE GENERATION - 15 SEC VALIDITY
// ============================================================

// POST /students/qr/generate - Generate QR with 15 sec expiry
app.post('/students/qr/generate', requireAuth, async (req, res) => {
    const { studentId, classId } = req.body;
    
    if (!studentId || !classId) {
        return res.status(400).json({ error: 'studentId and classId required' });
    }

    try {
        // ✅ Check if student exists
        const studentCheck = await pool.query(
            'SELECT id, name, roll_no FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
            [studentId, 'STUDENT']
        );
        
        if (studentCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Student not found' });
        }
        
        const student = studentCheck.rows[0];
        
        // ✅ Check if class exists
        const classCheck = await pool.query(
            'SELECT id, name FROM classes WHERE id = $1 AND is_active = TRUE',
            [classId]
        );
        
        if (classCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Class not found' });
        }
        
        const classInfo = classCheck.rows[0];
        
        // ✅ Generate unique QR token (15 seconds expiry)
        const token = jwt.sign(
            {
                id: student.id,
                rollNo: student.roll_no,
                classId: classInfo.id,
                type: 'qr_attendance',
                timestamp: Date.now()
            },
            JWT_SECRET,
            { expiresIn: '15s' } // ✅ 15 SECONDS
        );
        
        // ✅ Store QR session
        const expiresAt = new Date(Date.now() + 15 * 1000);
        await pool.query(
            `INSERT INTO qr_sessions (student_id, class_id, qr_token, expires_at)
             VALUES ($1, $2, $3, $4)
             ON CONFLICT (student_id, class_id, qr_token) DO UPDATE
             SET generated_at = now(), expires_at = $4, is_used = FALSE`,
            [student.id, classInfo.id, token, expiresAt]
        );
        
        // ✅ QR data structure
        const qrData = {
            type: 'ATTENDANCE',
            studentId: student.id,
            rollNo: student.roll_no,
            name: student.name,
            classId: classInfo.id,
            className: classInfo.name,
            timestamp: Date.now(),
            token: token,
            expiresIn: 15 // seconds
        };
        
        res.json({
            success: true,
            qrData: JSON.stringify(qrData),
            expiresAt: expiresAt.toISOString(),
            student: {
                id: student.id,
                name: student.name,
                rollNo: student.roll_no
            },
            class: {
                id: classInfo.id,
                name: classInfo.name
            }
        });
        
    } catch (err) {
        console.error('QR Generation Error:', err);
        res.status(500).json({ error: 'Failed to generate QR' });
    }
});

// ============================================================
//  QR SCAN - WITH ENROLL AND DUPLICATE CHECK
// ============================================================

// POST /attendance/scan-with-enroll - Updated
// POST /attendance/scan-with-enroll - Scan QR, enroll if needed, mark attendance
app.post('/attendance/scan-with-enroll', requireAuth, requireRole('TEACHER', 'ADMIN'), async (req, res) => {
    console.log('📝 [SCAN-WITH-ENROLL] Request received');
    console.log('📦 Body:', req.body);
    console.log('👤 User:', req.user);
    
    const { qrData, classId, subject, autoEnroll } = req.body;

    if (!qrData || !classId) {
        console.log('❌ Missing qrData or classId');
        return res.status(400).json({ error: 'qrData and classId are required' });
    }

    try {
        // Parse QR data
        let parsedData;
        try {
            parsedData = typeof qrData === 'string' ? JSON.parse(qrData) : qrData;
            console.log('✅ QR Data parsed:', parsedData);
        } catch (e) {
            console.log('❌ Invalid QR format:', e.message);
            return res.status(400).json({ error: 'Invalid QR data format' });
        }

        // ✅ FIX: Accept both 'ATTENDANCE' AND 'CLASS_ATTENDANCE'
        const validTypes = ['ATTENDANCE', 'CLASS_ATTENDANCE'];
        if (!validTypes.includes(parsedData.type)) {
            console.log('❌ Invalid QR type:', parsedData.type);
            return res.status(400).json({ 
                error: 'Invalid QR type. Expected ATTENDANCE or CLASS_ATTENDANCE',
                receivedType: parsedData.type 
            });
        }

        // Verify JWT token
        let decoded;
        try {
            decoded = jwt.verify(parsedData.token, JWT_SECRET);
            console.log('✅ Token verified:', decoded);
        } catch (jwtError) {
            console.log('❌ JWT Error:', jwtError.message);
            if (jwtError.name === 'TokenExpiredError') {
                return res.status(401).json({ error: 'QR code expired (15 seconds)' });
            }
            return res.status(401).json({ error: 'Invalid QR token' });
        }

        // Verify student exists
        console.log('🔍 Looking for student:', parsedData.studentId);
        const studentCheck = await pool.query(
            'SELECT id, name, roll_no, is_registered FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
            [parsedData.studentId, 'STUDENT']
        );

        if (studentCheck.rows.length === 0) {
            console.log('❌ Student not found:', parsedData.studentId);
            return res.status(404).json({ error: 'Student not found' });
        }

        const student = studentCheck.rows[0];
        console.log('✅ Student found:', student);

        // Check if class exists
        console.log('🔍 Looking for class:', classId);
        const classCheck = await pool.query(
            'SELECT id, name FROM classes WHERE id = $1 AND is_active = TRUE',
            [classId]
        );

        if (classCheck.rows.length === 0) {
            console.log('❌ Class not found:', classId);
            return res.status(404).json({ error: 'Class not found' });
        }

        const classInfo = classCheck.rows[0];
        console.log('✅ Class found:', classInfo);

        // ✅ Check if already marked attendance today
        const today = new Date().toISOString().split('T')[0];
        const existingAttendance = await pool.query(
            `SELECT id, status, time FROM attendance 
             WHERE student_id = $1 AND class_id = $2 AND date = $3`,
            [student.id, classId, today]
        );

        if (existingAttendance.rows.length > 0) {
            const existing = existingAttendance.rows[0];
            console.log('⚠️ Already marked today:', existing);
            return res.status(409).json({
                error: 'Attendance already marked today',
                status: existing.status,
                time: existing.time,
                alreadyMarked: true
            });
        }

        // Check if enrolled in class
        const enrolledCheck = await pool.query(
            'SELECT id FROM class_students WHERE class_id = $1 AND student_id = $2',
            [classId, student.id]
        );

        let isEnrolled = enrolledCheck.rows.length > 0;
        console.log('📊 Enrolled status:', isEnrolled);

        // If not enrolled and autoEnroll is true, enroll the student
        if (!isEnrolled && autoEnroll) {
            console.log('📝 Enrolling student...');
            await pool.query(
                `INSERT INTO class_students (class_id, student_id, roll_no)
                 VALUES ($1, $2, $3)`,
                [classId, student.id, student.roll_no]
            );
            isEnrolled = true;
            console.log('✅ Student enrolled');
        }

        // If not enrolled and autoEnroll is false
        if (!isEnrolled) {
            console.log('❌ Student not enrolled and autoEnroll is false');
            return res.status(403).json({
                error: 'Student is not enrolled in this class',
                isEnrolled: false
            });
        }

        // Mark attendance
        const nowTime = new Date().toTimeString().slice(0, 5);
        console.log('📝 Marking attendance:', { studentId: student.id, classId, date: today, time: nowTime });

        const { rows } = await pool.query(
            `INSERT INTO attendance (student_id, teacher_id, class_id, subject, status, method, date, time)
             VALUES ($1, $2, $3, $4, 'Present', 'QR', $5, $6)
             ON CONFLICT (student_id, class_id, subject, date)
             DO UPDATE SET status = 'Present', method = 'QR', time = EXCLUDED.time
             RETURNING *`,
            [student.id, req.user.id, classId, subject || null, today, nowTime]
        );

        console.log('✅ Attendance marked:', rows[0]);

        res.json({
            success: true,
            message: 'Attendance marked!',
            student: {
                id: student.id,
                name: student.name,
                rollNo: student.roll_no
            },
            isEnrolled: isEnrolled,
            attendance: rows[0],
            timestamp: {
                date: today,
                time: nowTime
            }
        });

    } catch (err) {
        console.error('❌ Error in scan-with-enroll:', err);
        console.error('Stack:', err.stack);
        res.status(500).json({ error: 'Failed to mark attendance: ' + err.message });
    }
});

// ============================================================
//  STUDENT PERMANENT QR (Registration QR)
// ============================================================

// ============================================================
//  PERMANENT QR FOR UNREGISTERED STUDENTS
// ============================================================

// attendance_backend/src/server.js

// GET /students/qr/permanent/:id - Permanent QR for student
app.get('/students/qr/permanent/:id', requireAuth, async (req, res) => {
    const { id } = req.params;

    try {
        const { rows } = await pool.query(
            'SELECT id, name, email, roll_no, class_name, is_registered FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
            [id, 'STUDENT']
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Student not found' });
        }

        const student = rows[0];

        // ✅ If student is already registered, return that info
        if (student.is_registered) {
            return res.json({
                success: true,
                isRegistered: true,
                message: 'Student is already registered. Use Class QR for attendance.',
                student: {
                    id: student.id,
                    name: student.name,
                    rollNo: student.roll_no,
                    className: student.class_name
                }
            });
        }

        // ✅ Generate permanent QR token (1 year validity)
        const token = jwt.sign(
            {
                id: student.id,
                rollNo: student.roll_no,
                type: 'permanent_registration'
            },
            JWT_SECRET,
            { expiresIn: '365d' }
        );

        // Save permanent token
        await pool.query(
            'UPDATE users SET permanent_qr_token = $1 WHERE id = $2',
            [token, student.id]
        );

        const qrData = {
            type: 'PERMANENT',
            studentId: student.id,
            rollNo: student.roll_no,
            name: student.name,
            className: student.class_name,
            token: token,
            isRegistered: false
        };

        res.json({
            success: true,
            qrData: JSON.stringify(qrData),
            isRegistered: false,
            student: {
                id: student.id,
                name: student.name,
                rollNo: student.roll_no,
                className: student.class_name
            }
        });

    } catch (err) {
        console.error('Permanent QR Error:', err);
        res.status(500).json({ error: 'Failed to generate permanent QR' });
    }
});
// ============================================================
//  STUDENT REGISTRATION VIA QR SCAN (Teacher Scanner 1)
// ============================================================

// POST /students/register-by-qr - Register student via QR scan
app.post('/students/register-by-qr', requireAuth, requireRole('TEACHER', 'ADMIN'), async (req, res) => {
    const { qrData, classId } = req.body;

    if (!qrData || !classId) {
        return res.status(400).json({ error: 'qrData and classId are required' });
    }

    try {
        // Parse QR data
        let parsedData;
        try {
            parsedData = typeof qrData === 'string' ? JSON.parse(qrData) : qrData;
        } catch (e) {
            return res.status(400).json({ error: 'Invalid QR data format' });
        }

        // ✅ FIX: Accept both 'PERMANENT' and 'PERMANENT_REGISTRATION'
        if (parsedData.type !== 'PERMANENT' && parsedData.type !== 'PERMANENT_REGISTRATION') {
            return res.status(400).json({ 
                error: 'Invalid QR type. Use registration QR.',
                receivedType: parsedData.type 
            });
        }

        // Verify token - skip if no token (for older QR codes)
        if (parsedData.token) {
            try {
                const decoded = jwt.verify(parsedData.token, JWT_SECRET);
                // Token is valid
            } catch (jwtError) {
                if (jwtError.name === 'TokenExpiredError') {
                    return res.status(401).json({ error: 'QR expired. Please generate new QR.' });
                }
                // If token is invalid but QR is from old system, still allow
                console.log('⚠️ Token verification failed but continuing:', jwtError.message);
            }
        }

        // Check if student exists
        const studentCheck = await pool.query(
            'SELECT id, name, roll_no, is_registered FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
            [parsedData.studentId, 'STUDENT']
        );

        if (studentCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Student not found' });
        }

        const student = studentCheck.rows[0];

        // Check if already registered
        if (student.is_registered) {
            return res.status(409).json({ 
                error: 'Student is already registered!',
                isRegistered: true,
                student: student
            });
        }

        // Check if class exists
        const classCheck = await pool.query(
            'SELECT id, name FROM classes WHERE id = $1 AND is_active = TRUE',
            [classId]
        );

        if (classCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Class not found' });
        }

        // ✅ Register student (set is_registered = TRUE)
        await pool.query(
            `UPDATE users SET 
                is_registered = TRUE, 
                registered_at = now(),
                class_name = $1
             WHERE id = $2`,
            [classCheck.rows[0].name, student.id]
        );

        // ✅ Enroll student in class
        await pool.query(
            `INSERT INTO class_students (class_id, student_id, roll_no)
             VALUES ($1, $2, $3)
             ON CONFLICT (class_id, student_id) DO NOTHING`,
            [classId, student.id, student.roll_no]
        );

        res.json({
            success: true,
            message: `${student.name} registered successfully!`,
            isRegistered: true,
            student: {
                id: student.id,
                name: student.name,
                rollNo: student.roll_no,
                className: classCheck.rows[0].name
            },
            class: classCheck.rows[0]
        });

    } catch (err) {
        console.error('Registration error:', err);
        res.status(500).json({ error: 'Failed to register student: ' + err.message });
    }
});

// ============================================================
//  CLASS QR FOR REGISTERED STUDENTS (15 sec - Scanner 2)
// ============================================================

// POST /students/qr/class - Generate class QR with 15 sec expiry
app.post('/students/qr/class', requireAuth, async (req, res) => {
    const { studentId, classId } = req.body;

    if (!studentId || !classId) {
        return res.status(400).json({ error: 'studentId and classId required' });
    }

    try {
        // Check if student exists and is registered
        const studentCheck = await pool.query(
            'SELECT id, name, roll_no, is_registered FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
            [studentId, 'STUDENT']
        );

        if (studentCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Student not found' });
        }

        const student = studentCheck.rows[0];

        // Student MUST be registered to get class QR
        if (!student.is_registered) {
            return res.status(403).json({ 
                error: 'Student not registered. Please get registered first.',
                isRegistered: false
            });
        }

        // Check if class exists
        const classCheck = await pool.query(
            'SELECT id, name FROM classes WHERE id = $1 AND is_active = TRUE',
            [classId]
        );

        if (classCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Class not found' });
        }

        // Check if student is enrolled in this class
        const enrolledCheck = await pool.query(
            'SELECT id FROM class_students WHERE class_id = $1 AND student_id = $2',
            [classId, studentId]
        );

        if (enrolledCheck.rows.length === 0) {
            return res.status(403).json({ error: 'Student not enrolled in this class' });
        }

        const classInfo = classCheck.rows[0];

        // ✅ Generate 15 second token
        const token = jwt.sign(
            {
                id: student.id,
                rollNo: student.roll_no,
                classId: classInfo.id,
                type: 'class_attendance',
                timestamp: Date.now()
            },
            process.env.JWT_SECRET,  // ✅ Make sure JWT_SECRET is defined
            { expiresIn: '15s' }
        );

        const qrData = {
            type: 'CLASS_ATTENDANCE',
            studentId: student.id,
            rollNo: student.roll_no,
            name: student.name,
            classId: classInfo.id,
            className: classInfo.name,
            timestamp: Date.now(),
            token: token,
            expiresIn: 15,
            isRegistered: true
        };

        res.json({
            success: true,
            qrData: JSON.stringify(qrData),
            expiresAt: new Date(Date.now() + 15 * 1000).toISOString(),
            isRegistered: true,
            student: {
                id: student.id,
                name: student.name,
                rollNo: student.roll_no
            },
            class: {
                id: classInfo.id,
                name: classInfo.name
            }
        });

    } catch (err) {
        console.error('Class QR Error:', err);
        console.error('Stack:', err.stack);
        res.status(500).json({ error: 'Failed to generate class QR: ' + err.message });
    }
});
// GET /students/classes - Get classes for logged in student
app.get('/students/classes', requireAuth, async (req, res) => {
  try {
    // Check if user is student
    if (req.user.role !== 'STUDENT') {
      return res.status(403).json({ error: 'Only students can access this' });
    }

    // Get student's classes from class_students
    const { rows } = await pool.query(
      `SELECT c.id, c.name, c.semester, c.teacher_id,
              u.name as teacher_name,
              COUNT(a.id) as total_lectures,
              COUNT(CASE WHEN a.status = 'Present' THEN 1 END) as present_count
       FROM class_students cs
       JOIN classes c ON c.id = cs.class_id
       LEFT JOIN users u ON u.id = c.teacher_id
       LEFT JOIN attendance a ON a.student_id = cs.student_id 
          AND a.class_id = c.id
       WHERE cs.student_id = $1 AND c.is_active = TRUE
       GROUP BY c.id, c.name, c.semester, c.teacher_id, u.name
       ORDER BY c.name`,
      [req.user.id]
    );

    res.json({
      classes: rows.map((r) => ({
        id: r.id,
        name: r.name,
        semester: r.semester,
        teacherId: r.teacher_id,
        teacherName: r.teacher_name || 'Not Assigned',
        totalLectures: Number(r.total_lectures || 0),
        presentCount: Number(r.present_count || 0),
        percentage: r.total_lectures > 0 
          ? Math.round((r.present_count / r.total_lectures) * 100) 
          : 0,
      })),
    });
  } catch (err) {
    console.error('Error fetching student classes:', err);
    res.status(500).json({ error: 'Failed to fetch classes' });
  }
});

// GET /student/lectures/:classId - Get lectures for a class
app.get('/student/lectures/:classId', requireAuth, async (req, res) => {
  const { classId } = req.params;
  
  try {
    // Check if student is enrolled in this class
    const enrolled = await pool.query(
      'SELECT id FROM class_students WHERE class_id = $1 AND student_id = $2',
      [classId, req.user.id]
    );
    
    if (enrolled.rows.length === 0) {
      return res.status(403).json({ error: 'You are not enrolled in this class' });
    }

    // Get lectures/attendance for this class
    const { rows } = await pool.query(
      `SELECT a.id, a.date, a.time, a.status, a.subject,
              a.method, a.created_at
       FROM attendance a
       WHERE a.student_id = $1 AND a.class_id = $2
       ORDER BY a.date DESC, a.time DESC`,
      [req.user.id, classId]
    );

    res.json({
      lectures: rows.map((r) => ({
        id: r.id,
        date: r.date,
        time: r.time,
        status: r.status,
        subject: r.subject || 'General',
        method: r.method,
      })),
    });
  } catch (err) {
    console.error('Error fetching lectures:', err);
    res.status(500).json({ error: 'Failed to fetch lectures' });
  }
});


// ============================================================================
//  TEACHER → CLASS ASSIGNMENTS
// ============================================================================

// ── Get all teacher-class assignments ──────────────────────────────────
app.get('/teacher-class-assignments', requireAuth, requireRole('ADMIN'), async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT tca.*,
                    u.name as teacher_name,
                    u.email as teacher_email,
                    c.name as class_name,
                    c.semester
             FROM teacher_class_assignments tca
             JOIN users u ON u.id = tca.teacher_id AND u.is_active = TRUE
             JOIN classes c ON c.id = tca.class_id AND c.is_active = TRUE
             WHERE tca.is_active = TRUE
             ORDER BY u.name, c.name`
        );
        res.json({ assignments: rows });
    } catch (err) {
        console.error('Error fetching assignments:', err);
        res.status(500).json({ error: 'Failed to fetch assignments' });
    }
});

// ── Assign teacher to class ──────────────────────────────────────────
app.post('/teacher-class-assignments', requireAuth, requireRole('ADMIN'), async (req, res) => {
    const { teacher_id, class_id, subject } = req.body;

    if (!teacher_id || !class_id) {
        return res.status(400).json({ error: 'teacher_id and class_id are required' });
    }

    try {
        // Check if teacher exists
        const teacher = await pool.query(
            'SELECT id, name FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
            [teacher_id, 'TEACHER']
        );
        if (teacher.rows.length === 0) {
            return res.status(404).json({ error: 'Teacher not found' });
        }

        // Check if class exists
        const classCheck = await pool.query(
            'SELECT id, name FROM classes WHERE id = $1 AND is_active = TRUE',
            [class_id]
        );
        if (classCheck.rows.length === 0) {
            return res.status(404).json({ error: 'Class not found' });
        }

        // Check if already assigned
        const existing = await pool.query(
            'SELECT id FROM teacher_class_assignments WHERE teacher_id = $1 AND class_id = $2 AND is_active = TRUE',
            [teacher_id, class_id]
        );

        if (existing.rows.length > 0) {
            return res.status(409).json({ error: 'Teacher already assigned to this class' });
        }

        // ✅ Also update classes table teacher_id
        await pool.query(
            'UPDATE classes SET teacher_id = $1 WHERE id = $2',
            [teacher_id, class_id]
        );

        const { rows } = await pool.query(
            `INSERT INTO teacher_class_assignments (teacher_id, class_id, subject)
             VALUES ($1, $2, $3)
             RETURNING *`,
            [teacher_id, class_id, subject || null]
        );

        res.status(201).json({
            success: true,
            message: 'Teacher assigned to class successfully',
            assignment: rows[0]
        });

    } catch (err) {
        console.error('Assignment error:', err);
        res.status(500).json({ error: 'Failed to assign teacher to class' });
    }
});

// ── Remove teacher from class ────────────────────────────────────────
app.delete('/teacher-class-assignments/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
    const { id } = req.params;

    try {
        // Get assignment details first
        const assignment = await pool.query(
            'SELECT teacher_id, class_id FROM teacher_class_assignments WHERE id = $1 AND is_active = TRUE',
            [id]
        );

        if (assignment.rows.length === 0) {
            return res.status(404).json({ error: 'Assignment not found' });
        }

        // Soft delete assignment
        await pool.query(
            'UPDATE teacher_class_assignments SET is_active = FALSE WHERE id = $1',
            [id]
        );

        // ✅ Check if teacher has other classes assigned
        const otherAssignments = await pool.query(
            'SELECT id FROM teacher_class_assignments WHERE teacher_id = $1 AND is_active = TRUE',
            [assignment.rows[0].teacher_id]
        );

        // ✅ If no other classes, remove teacher_id from classes table
        if (otherAssignments.rows.length === 0) {
            await pool.query(
                'UPDATE classes SET teacher_id = NULL WHERE id = $1',
                [assignment.rows[0].class_id]
            );
        }

        res.json({ success: true, message: 'Teacher removed from class' });
    } catch (err) {
        console.error('Error removing assignment:', err);
        res.status(500).json({ error: 'Failed to remove assignment' });
    }
});

// ── Get teacher's assigned classes ──────────────────────────────────
app.get('/teacher/:id/classes', requireAuth, async (req, res) => {
    const { id } = req.params;

    try {
        // ✅ Check if user is teacher
        const userCheck = await pool.query(
            'SELECT role FROM users WHERE id = $1 AND is_active = TRUE',
            [id]
        );

        if (userCheck.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        if (userCheck.rows[0].role !== 'TEACHER') {
            return res.status(403).json({ error: 'User is not a teacher' });
        }

        const { rows } = await pool.query(
            `SELECT c.*, tca.subject as assigned_subject,
                    tca.assigned_at,
                    COUNT(cs.id)::integer as student_count
             FROM teacher_class_assignments tca
             JOIN classes c ON c.id = tca.class_id AND c.is_active = TRUE
             LEFT JOIN class_students cs ON cs.class_id = c.id
             WHERE tca.teacher_id = $1 AND tca.is_active = TRUE
             GROUP BY c.id, tca.subject, tca.assigned_at
             ORDER BY c.name`,
            [id]
        );

        res.json({ classes: rows });
    } catch (err) {
        console.error('Error fetching teacher classes:', err);
        res.status(500).json({ error: 'Failed to fetch teacher classes' });
    }
});

// ── Get all teachers for dropdown ────────────────────────────────────
app.get('/teachers/list', requireAuth, requireRole('ADMIN'), async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT id, name, email, subject
             FROM users
             WHERE role = 'TEACHER' AND is_active = TRUE
             ORDER BY name`
        );
        res.json({ teachers: rows });
    } catch (err) {
        console.error('Error fetching teachers:', err);
        res.status(500).json({ error: 'Failed to fetch teachers' });
    }
}); 

// ── Get classes not assigned to a teacher ────────────────────────────
app.get('/unassigned-classes', requireAuth, requireRole('ADMIN'), async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT c.*
             FROM classes c
             WHERE c.is_active = TRUE
               AND c.id NOT IN (
                   SELECT class_id FROM teacher_class_assignments WHERE is_active = TRUE
               )
             ORDER BY c.name`
        );
        res.json({ classes: rows });
    } catch (err) {
        console.error('Error fetching unassigned classes:', err);
        res.status(500).json({ error: 'Failed to fetch unassigned classes' });
    }
});
// ─────────────────────────────────────────────────────────────────────────
//  ATTENDANCE
// ─────────────────────────────────────────────────────────────────────────

// POST /attendance — mark attendance (QR or manual). Enforces one record
// per student+class+subject+date via the DB unique constraint.
app.post('/attendance', requireAuth, requireRole('TEACHER', 'ADMIN'), async (req, res) => {
  const { studentId, classId, subject, status, method, date, time } = req.body;
  if (!studentId || !classId || !status || !date) {
    return res.status(400).json({ error: 'studentId, classId, status, date are required' });
  }
  if (!['Present', 'Absent', 'Late', 'Leave'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }

  try {
    const { rows } = await pool.query(
      `INSERT INTO attendance (student_id, teacher_id, class_id, subject, status, method, date, time)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (student_id, class_id, subject, date)
       DO UPDATE SET status = EXCLUDED.status, method = EXCLUDED.method, time = EXCLUDED.time
       RETURNING *`,
      [studentId, req.user.id, classId, subject || null, status, method || 'MANUAL', date, time || null]
    );
    res.status(201).json({ attendance: rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to mark attendance' });
  }
});

// ============================================================================
//  STUDENT SELF-REGISTRATION (Public endpoint - no auth required)
// ============================================================================

// POST /auth/register-student - Student self-registration
app.post('/auth/register-student', async (req, res) => {
  const { name, email, password, rollNo, mobile, className, semester } = req.body;

  // Validation
  if (!name || !email || !password || !rollNo) {
    return res.status(400).json({ 
      error: 'name, email, password, and rollNo are required' 
    });
  }

  if (password.length < 6) {
    return res.status(400).json({ 
      error: 'Password must be at least 6 characters' 
    });
  }

  // Check if email or rollNo already exists
  try {
    const existing = await pool.query(
      'SELECT id FROM users WHERE LOWER(email) = LOWER($1) OR roll_no = $2',
      [email, rollNo]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({ 
        error: 'Email or Roll Number already registered' 
      });
    }

    // Create student account
    const hash = await bcrypt.hash(password, 12);
    const { rows } = await pool.query(
      `INSERT INTO users (name, email, password_hash, role, roll_no, mobile, class_name, is_active)
       VALUES ($1, LOWER($2), $3, 'STUDENT', $4, $5, $6, TRUE)
       RETURNING id, name, email, roll_no, class_name`,
      [name, email, hash, rollNo, mobile || null, className || null]
    );

    // Generate unique QR token for student
    const student = rows[0];
    const qrToken = signToken({
      id: student.id,
      role: 'STUDENT',
      rollNo: student.roll_no,
      type: 'qr_attendance'
    });

    res.status(201).json({
      success: true,
      message: 'Student registered successfully!',
      user: {
        id: student.id,
        name: student.name,
        email: student.email,
        rollNo: student.roll_no,
        className: student.class_name,
        qrToken: qrToken // For QR code generation
      }
    });

  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

// GET /students/qr/:id - Generate QR data for student
app.get('/students/qr/:id', requireAuth, async (req, res) => {
  const { id } = req.params;
  
  try {
    const { rows } = await pool.query(
      'SELECT id, name, email, roll_no, class_name FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
      [id, 'STUDENT']
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Student not found' });
    }

    const student = rows[0];
    
    // Generate QR data with student info
    const qrData = {
      type: 'ATTENDANCE',
      studentId: student.id,
      rollNo: student.roll_no,
      name: student.name,
      timestamp: Date.now(),
      // Short-lived token for QR (valid for 5 minutes)
      token: signToken({
        id: student.id,
        rollNo: student.roll_no,
        type: 'qr_attendance'
      }, '5m')
    };

    res.json({
      student: {
        id: student.id,
        name: student.name,
        rollNo: student.roll_no,
        className: student.class_name
      },
      qrData: JSON.stringify(qrData)
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to generate QR' });
  }
});

// POST /attendance/scan - Scan QR code and mark attendance
app.post('/attendance/scan', requireAuth, requireRole('TEACHER', 'ADMIN'), async (req, res) => {
  const { qrData, classId, subject } = req.body;

  if (!qrData || !classId) {
    return res.status(400).json({ error: 'qrData and classId are required' });
  }

  try {
    // Parse QR data
    let parsedData;
    try {
      parsedData = typeof qrData === 'string' ? JSON.parse(qrData) : qrData;
    } catch (e) {
      return res.status(400).json({ error: 'Invalid QR data format' });
    }

    // Verify QR token
    try {
      const decoded = jwt.verify(parsedData.token, JWT_SECRET);
      if (decoded.type !== 'qr_attendance') {
        return res.status(400).json({ error: 'Invalid QR type' });
      }
      
      // Check if QR is expired (5 minutes)
      const now = Date.now();
      const qrTime = parsedData.timestamp || 0;
      if (now - qrTime > 5 * 60 * 1000) {
        return res.status(400).json({ error: 'QR code expired' });
      }

      // Verify student exists
      const studentCheck = await pool.query(
        'SELECT id, name, roll_no FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
        [parsedData.studentId, 'STUDENT']
      );

      if (studentCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Student not found' });
      }

      const student = studentCheck.rows[0];
      const today = new Date().toISOString().split('T')[0];
      const nowTime = new Date().toTimeString().slice(0, 5);

      // Mark attendance
      const { rows } = await pool.query(
        `INSERT INTO attendance (student_id, teacher_id, class_id, subject, status, method, date, time)
         VALUES ($1, $2, $3, $4, 'Present', 'QR', $5, $6)
         ON CONFLICT (student_id, class_id, subject, date)
         DO UPDATE SET status = 'Present', method = 'QR', time = EXCLUDED.time
         RETURNING *`,
        [student.id, req.user.id, classId, subject || null, today, nowTime]
      );

      res.json({
        success: true,
        message: `Attendance marked for ${student.name}`,
        student: student,
        attendance: rows[0]
      });

    } catch (jwtError) {
      return res.status(401).json({ error: 'Invalid QR token' });
    }

  } catch (err) {
    console.error('QR scan error:', err);
    res.status(500).json({ error: 'Failed to mark attendance' });
  }
});

// GET /attendance/student/:id
app.get('/attendance/student/:id', requireAuth, async (req, res) => {
  const { id } = req.params;
  // students may only view their own record
  if (req.user.role === 'STUDENT' && !req.user.isSuperAdmin && String(req.user.id) !== id) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  try {
    const { rows } = await pool.query(
      'SELECT * FROM attendance WHERE student_id = $1 ORDER BY date DESC',
      [id]
    );
    const total = rows.length;
    const present = rows.filter((r) => r.status === 'Present').length;
    res.json({
      records: rows,
      percentage: total ? Math.round((present / total) * 1000) / 10 : 0,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch attendance' });
  }
});

// POST /auth/check-user - Check if email or rollNo exists
app.post('/auth/check-user', async (req, res) => {
  const { email, rollNo } = req.body;
  try {
    const { rows } = await pool.query(
      'SELECT id FROM users WHERE LOWER(email) = LOWER($1) OR roll_no = $2',
      [email || '', rollNo || '']
    );
    res.json({ exists: rows.length > 0 });
  } catch (err) {
    res.status(500).json({ error: 'Check failed' });
  }
});


// attendance_backend/src/server.js - Add these endpoints

// ============================================================================
//  CLASS STUDENT MANAGEMENT
// ============================================================================

// POST /classes/:classId/enroll - Enroll student in class
app.post('/classes/:classId/enroll', requireAuth, requireRole('TEACHER', 'ADMIN'), async (req, res) => {
  const { classId } = req.params;
  const { studentId, rollNo } = req.body;

  if (!studentId) {
    return res.status(400).json({ error: 'studentId is required' });
  }

  try {
    // Check if class exists
    const classCheck = await pool.query(
      'SELECT id, name FROM classes WHERE id = $1 AND is_active = TRUE',
      [classId]
    );
    if (classCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Class not found' });
    }

    // Check if student exists
    const studentCheck = await pool.query(
      'SELECT id, name, roll_no FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
      [studentId, 'STUDENT']
    );
    if (studentCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Student not found' });
    }

    const student = studentCheck.rows[0];

    // Check if already enrolled
    const existing = await pool.query(
      'SELECT id FROM class_students WHERE class_id = $1 AND student_id = $2',
      [classId, studentId]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({ 
        error: 'Student already enrolled in this class',
        student: student
      });
    }

    // Enroll student
    await pool.query(
      `INSERT INTO class_students (class_id, student_id, roll_no)
       VALUES ($1, $2, $3)`,
      [classId, studentId, rollNo || student.roll_no]
    );

    res.json({
      success: true,
      message: 'Student enrolled successfully!',
      student: {
        id: student.id,
        name: student.name,
        rollNo: student.roll_no
      }
    });

  } catch (err) {
    console.error('Enrollment error:', err);
    res.status(500).json({ error: 'Failed to enroll student' });
  }
});

// GET /classes/:classId/students - Get enrolled students
app.get('/classes/:classId/students', requireAuth, requireRole('TEACHER', 'ADMIN'), async (req, res) => {
  const { classId } = req.params;

  try {
    const { rows } = await pool.query(
      `SELECT u.id, u.name, u.email, u.roll_no, cs.roll_no as class_roll_no,
              u.mobile, u.photo, cs.enrolled_at
       FROM class_students cs
       JOIN users u ON u.id = cs.student_id
       WHERE cs.class_id = $1 AND u.is_active = TRUE
       ORDER BY cs.roll_no ASC, u.name ASC`,
      [classId]
    );

    res.json({
      students: rows.map(r => ({
        id: r.id,
        name: r.name,
        email: r.email,
        rollNo: r.class_roll_no || r.roll_no,
        mobile: r.mobile,
        photo: r.photo,
        enrolledAt: r.enrolled_at
      }))
    });

  } catch (err) {
    console.error('Error fetching students:', err);
    res.status(500).json({ error: 'Failed to fetch students' });
  }
});

// DELETE /classes/:classId/students/:studentId - Remove student from class
app.delete('/classes/:classId/students/:studentId', requireAuth, requireRole('TEACHER', 'ADMIN'), async (req, res) => {
  const { classId, studentId } = req.params;

  try {
    await pool.query(
      'DELETE FROM class_students WHERE class_id = $1 AND student_id = $2',
      [classId, studentId]
    );

    res.json({ success: true, message: 'Student removed from class' });
  } catch (err) {
    console.error('Error removing student:', err);
    res.status(500).json({ error: 'Failed to remove student' });
  }
});

// POST /attendance/scan-with-enroll - Scan QR, enroll if needed, mark attendance
// POST /attendance/scan-with-enroll - Scan QR, enroll if needed, mark attendance
// POST /attendance/scan-with-enroll - Scan QR, enroll if needed, mark attendance
app.post('/attendance/scan-with-enroll', requireAuth, requireRole('TEACHER', 'ADMIN'), async (req, res) => {
    console.log('📝 [SCAN-WITH-ENROLL] Request received');
    console.log('📦 Body:', req.body);
    console.log('👤 User:', req.user);
    
    const { qrData, classId, subject, autoEnroll } = req.body;

    if (!qrData || !classId) {
        console.log('❌ Missing qrData or classId');
        return res.status(400).json({ error: 'qrData and classId are required' });
    }

    try {
        // Parse QR data
        let parsedData;
        try {
            parsedData = typeof qrData === 'string' ? JSON.parse(qrData) : qrData;
            console.log('✅ QR Data parsed:', parsedData);
        } catch (e) {
            console.log('❌ Invalid QR format:', e.message);
            return res.status(400).json({ error: 'Invalid QR data format' });
        }

        // ✅ FIX: Accept both 'ATTENDANCE' AND 'CLASS_ATTENDANCE'
        const validTypes = ['ATTENDANCE', 'CLASS_ATTENDANCE'];
        if (!validTypes.includes(parsedData.type)) {
            console.log('❌ Invalid QR type:', parsedData.type);
            return res.status(400).json({ 
                error: 'Invalid QR type. Expected ATTENDANCE or CLASS_ATTENDANCE',
                receivedType: parsedData.type 
            });
        }

        // Verify JWT token
        let decoded;
        try {
            decoded = jwt.verify(parsedData.token, JWT_SECRET);
            console.log('✅ Token verified:', decoded);
        } catch (jwtError) {
            console.log('❌ JWT Error:', jwtError.message);
            if (jwtError.name === 'TokenExpiredError') {
                return res.status(401).json({ error: 'QR code expired (15 seconds)' });
            }
            return res.status(401).json({ error: 'Invalid QR token' });
        }

        // Verify student exists
        console.log('🔍 Looking for student:', parsedData.studentId);
        const studentCheck = await pool.query(
            'SELECT id, name, roll_no, is_registered FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
            [parsedData.studentId, 'STUDENT']
        );

        if (studentCheck.rows.length === 0) {
            console.log('❌ Student not found:', parsedData.studentId);
            return res.status(404).json({ error: 'Student not found' });
        }

        const student = studentCheck.rows[0];
        console.log('✅ Student found:', student);

        // Check if class exists
        console.log('🔍 Looking for class:', classId);
        const classCheck = await pool.query(
            'SELECT id, name FROM classes WHERE id = $1 AND is_active = TRUE',
            [classId]
        );

        if (classCheck.rows.length === 0) {
            console.log('❌ Class not found:', classId);
            return res.status(404).json({ error: 'Class not found' });
        }

        const classInfo = classCheck.rows[0];
        console.log('✅ Class found:', classInfo);

        // ✅ Check if already marked attendance today
        const today = new Date().toISOString().split('T')[0];
        const existingAttendance = await pool.query(
            `SELECT id, status, time FROM attendance 
             WHERE student_id = $1 AND class_id = $2 AND date = $3`,
            [student.id, classId, today]
        );

        if (existingAttendance.rows.length > 0) {
            const existing = existingAttendance.rows[0];
            console.log('⚠️ Already marked today:', existing);
            return res.status(409).json({
                error: 'Attendance already marked today',
                status: existing.status,
                time: existing.time,
                alreadyMarked: true
            });
        }

        // Check if enrolled in class
        const enrolledCheck = await pool.query(
            'SELECT id FROM class_students WHERE class_id = $1 AND student_id = $2',
            [classId, student.id]
        );

        let isEnrolled = enrolledCheck.rows.length > 0;
        console.log('📊 Enrolled status:', isEnrolled);

        // If not enrolled and autoEnroll is true, enroll the student
        if (!isEnrolled && autoEnroll) {
            console.log('📝 Enrolling student...');
            await pool.query(
                `INSERT INTO class_students (class_id, student_id, roll_no)
                 VALUES ($1, $2, $3)`,
                [classId, student.id, student.roll_no]
            );
            isEnrolled = true;
            console.log('✅ Student enrolled');
        }

        // If not enrolled and autoEnroll is false
        if (!isEnrolled) {
            console.log('❌ Student not enrolled and autoEnroll is false');
            return res.status(403).json({
                error: 'Student is not enrolled in this class',
                isEnrolled: false
            });
        }

        // Mark attendance
        const nowTime = new Date().toTimeString().slice(0, 5);
        console.log('📝 Marking attendance:', { studentId: student.id, classId, date: today, time: nowTime });

        const { rows } = await pool.query(
            `INSERT INTO attendance (student_id, teacher_id, class_id, subject, status, method, date, time)
             VALUES ($1, $2, $3, $4, 'Present', 'QR', $5, $6)
             ON CONFLICT (student_id, class_id, subject, date)
             DO UPDATE SET status = 'Present', method = 'QR', time = EXCLUDED.time
             RETURNING *`,
            [student.id, req.user.id, classId, subject || null, today, nowTime]
        );

        console.log('✅ Attendance marked:', rows[0]);

        res.json({
            success: true,
            message: 'Attendance marked!',
            student: {
                id: student.id,
                name: student.name,
                rollNo: student.roll_no
            },
            isEnrolled: isEnrolled,
            attendance: rows[0],
            timestamp: {
                date: today,
                time: nowTime
            }
        });

    } catch (err) {
        console.error('❌ Error in scan-with-enroll:', err);
        console.error('Stack:', err.stack);
        res.status(500).json({ error: 'Failed to mark attendance: ' + err.message });
    }
});


// attendance_backend/src/server.js - Add this endpoint

// attendance_backend/src/server.js - Add this endpoint

// DELETE /classes/:id - Delete a class
app.delete('/classes/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { id } = req.params;
  
  console.log(`🗑️ Deleting class: ${id}`);
  
  try {
    // Check if class exists
    const classCheck = await pool.query(
      'SELECT id FROM classes WHERE id = $1 AND is_active = TRUE',
      [id]
    );
    
    if (classCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Class not found' });
    }
    
    // Delete class (cascade will delete class_students)
    await pool.query(
      'DELETE FROM classes WHERE id = $1',
      [id]
    );
    
    console.log(`✅ Class ${id} deleted`);
    res.json({ success: true, message: 'Class deleted successfully' });
  } catch (err) {
    console.error('Delete class error:', err);
    res.status(500).json({ error: 'Failed to delete class' });
  }
});



// ============================================================================
//  CLASSROOM MANAGEMENT
// ============================================================================

// ── GET all classrooms ────────────────────────────────────────────────
// attendance_backend/src/server.js

// attendance_backend/src/server.js

// ✅ FIX: Agar table exist nahi karti toh handle karo
app.get('/classrooms', requireAuth, async (req, res) => {
    try {
        // Check if table exists first
        const tableCheck = await pool.query(`
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'classrooms'
            )
        `);
        
        if (!tableCheck.rows[0].exists) {
            // Table doesn't exist - return empty array
            return res.json({ classrooms: [] });
        }
        
        const { rows } = await pool.query(
            `SELECT c.*, 
                    COUNT(tc.id)::integer as teacher_count,
                    COUNT(DISTINCT ts.class_id)::integer as class_count
             FROM classrooms c
             LEFT JOIN teacher_classrooms tc ON tc.classroom_id = c.id AND tc.is_active = TRUE
             LEFT JOIN teacher_schedule ts ON ts.classroom_id = c.id AND ts.is_active = TRUE
             WHERE c.is_active = TRUE
             GROUP BY c.id
             ORDER BY c.building, c.room_number`
        );
        res.json({ classrooms: rows });
    } catch (err) {
        console.error('Error fetching classrooms:', err);
        // ✅ Return empty array instead of error
        res.json({ classrooms: [] });
    }
});

// ── GET single classroom ─────────────────────────────────────────────
app.get('/classrooms/:id', requireAuth, async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT c.*,
                    json_agg(DISTINCT jsonb_build_object(
                        'teacher_id', u.id,
                        'teacher_name', u.name,
                        'subject', tc.subject,
                        'is_primary', tc.is_primary
                    )) FILTER (WHERE u.id IS NOT NULL) as teachers
             FROM classrooms c
             LEFT JOIN teacher_classrooms tc ON tc.classroom_id = c.id AND tc.is_active = TRUE
             LEFT JOIN users u ON u.id = tc.teacher_id AND u.is_active = TRUE
             WHERE c.id = $1 AND c.is_active = TRUE
             GROUP BY c.id`,
            [req.params.id]
        );
        
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Classroom not found' });
        }
        res.json({ classroom: rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to fetch classroom' });
    }
});

// ── CREATE classroom ──────────────────────────────────────────────────
app.post('/classrooms', requireAuth, requireRole('ADMIN'), async (req, res) => {
    const { room_number, building, floor, capacity, has_projector, has_whiteboard } = req.body;
    
    if (!room_number) {
        return res.status(400).json({ error: 'room_number is required' });
    }
    
    try {
        const { rows } = await pool.query(
            `INSERT INTO classrooms (room_number, building, floor, capacity, has_projector, has_whiteboard)
             VALUES ($1, $2, $3, $4, $5, $6)
             RETURNING *`,
            [room_number, building, floor, capacity, has_projector || false, has_whiteboard || true]
        );
        res.status(201).json({ classroom: rows[0] });
    } catch (err) {
        if (err.code === '23505') {
            return res.status(409).json({ error: 'Classroom already exists' });
        }
        console.error(err);
        res.status(500).json({ error: 'Failed to create classroom' });
    }
});

// ── UPDATE classroom ──────────────────────────────────────────────────
app.put('/classrooms/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
    const { id } = req.params;
    const { room_number, building, floor, capacity, has_projector, has_whiteboard, is_active } = req.body;
    
    try {
        const { rows } = await pool.query(
            `UPDATE classrooms SET
                room_number = COALESCE($1, room_number),
                building = COALESCE($2, building),
                floor = COALESCE($3, floor),
                capacity = COALESCE($4, capacity),
                has_projector = COALESCE($5, has_projector),
                has_whiteboard = COALESCE($6, has_whiteboard),
                is_active = COALESCE($7, is_active)
             WHERE id = $8
             RETURNING *`,
            [room_number, building, floor, capacity, has_projector, has_whiteboard, is_active, id]
        );
        
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Classroom not found' });
        }
        res.json({ classroom: rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to update classroom' });
    }
});

// ── DELETE classroom ──────────────────────────────────────────────────
app.delete('/classrooms/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
    const { id } = req.params;
    
    try {
        await pool.query('UPDATE classrooms SET is_active = FALSE WHERE id = $1', [id]);
        res.json({ success: true, message: 'Classroom deleted' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to delete classroom' });
    }
});

// ============================================================================
//  TEACHER → CLASSROOM ASSIGNMENTS
// ============================================================================

// ── Get all teacher assignments ──────────────────────────────────────
app.get('/teacher-assignments', requireAuth, requireRole('ADMIN'), async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT tc.*,
                    u.name as teacher_name,
                    u.email as teacher_email,
                    c.room_number,
                    c.building,
                    c.floor
             FROM teacher_classrooms tc
             JOIN users u ON u.id = tc.teacher_id AND u.is_active = TRUE
             JOIN classrooms c ON c.id = tc.classroom_id AND c.is_active = TRUE
             WHERE tc.is_active = TRUE
             ORDER BY u.name, c.room_number`
        );
        res.json({ assignments: rows });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to fetch assignments' });
    }
});

// ── Get teacher's classrooms ─────────────────────────────────────────
app.get('/teachers/:id/classrooms', requireAuth, async (req, res) => {
    const { id } = req.params;
    
    try {
        const { rows } = await pool.query(
            `SELECT tc.*, c.room_number, c.building, c.floor, c.capacity
             FROM teacher_classrooms tc
             JOIN classrooms c ON c.id = tc.classroom_id
             WHERE tc.teacher_id = $1 AND tc.is_active = TRUE AND c.is_active = TRUE
             ORDER BY c.room_number`,
            [id]
        );
        res.json({ classrooms: rows });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to fetch teacher classrooms' });
    }
});

// ── Assign teacher to classroom ──────────────────────────────────────
app.post('/teacher-assignments', requireAuth, requireRole('ADMIN'), async (req, res) => {
    const { teacher_id, classroom_id, subject, is_primary } = req.body;
    
    if (!teacher_id || !classroom_id) {
        return res.status(400).json({ error: 'teacher_id and classroom_id are required' });
    }
    
    try {
        // Check if teacher exists
        const teacher = await pool.query(
            'SELECT id, name FROM users WHERE id = $1 AND role = $2 AND is_active = TRUE',
            [teacher_id, 'TEACHER']
        );
        if (teacher.rows.length === 0) {
            return res.status(404).json({ error: 'Teacher not found' });
        }
        
        // Check if classroom exists
        const classroom = await pool.query(
            'SELECT id, room_number FROM classrooms WHERE id = $1 AND is_active = TRUE',
            [classroom_id]
        );
        if (classroom.rows.length === 0) {
            return res.status(404).json({ error: 'Classroom not found' });
        }
        
        // If is_primary is true, remove primary flag from other assignments
        if (is_primary) {
            await pool.query(
                'UPDATE teacher_classrooms SET is_primary = FALSE WHERE teacher_id = $1',
                [teacher_id]
            );
        }
        
        const { rows } = await pool.query(
            `INSERT INTO teacher_classrooms (teacher_id, classroom_id, subject, is_primary)
             VALUES ($1, $2, $3, $4)
             ON CONFLICT (teacher_id, classroom_id)
             DO UPDATE SET subject = EXCLUDED.subject, is_primary = EXCLUDED.is_primary, is_active = TRUE
             RETURNING *`,
            [teacher_id, classroom_id, subject, is_primary || false]
        );
        
        res.status(201).json({
            success: true,
            message: 'Teacher assigned to classroom successfully',
            assignment: rows[0],
            teacher: teacher.rows[0],
            classroom: classroom.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to assign teacher to classroom' });
    }
});

// ── Remove teacher from classroom ────────────────────────────────────
app.delete('/teacher-assignments/:id', requireAuth, requireRole('ADMIN'), async (req, res) => {
    const { id } = req.params;
    
    try {
        await pool.query(
            'DELETE FROM teacher_classrooms WHERE id = $1',
            [id]
        );
        res.json({ success: true, message: 'Teacher removed from classroom' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to remove assignment' });
    }
});

// ── Get available teachers (not assigned to a classroom) ────────────
app.get('/available-teachers', requireAuth, requireRole('ADMIN'), async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT u.id, u.name, u.email, u.subject
             FROM users u
             WHERE u.role = 'TEACHER' 
               AND u.is_active = TRUE
               AND NOT EXISTS (
                   SELECT 1 FROM teacher_classrooms tc 
                   WHERE tc.teacher_id = u.id AND tc.is_active = TRUE
               )
             ORDER BY u.name`
        );
        res.json({ teachers: rows });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to fetch available teachers' });
    }
});

// ── Get teachers by classroom ────────────────────────────────────────
app.get('/classrooms/:id/teachers', requireAuth, async (req, res) => {
    const { id } = req.params;
    
    try {
        const { rows } = await pool.query(
            `SELECT u.id, u.name, u.email, u.subject, tc.subject as teaches_subject, tc.is_primary
             FROM teacher_classrooms tc
             JOIN users u ON u.id = tc.teacher_id AND u.is_active = TRUE
             WHERE tc.classroom_id = $1 AND tc.is_active = TRUE
             ORDER BY tc.is_primary DESC, u.name`,
            [id]
        );
        res.json({ teachers: rows });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to fetch classroom teachers' });
    }
});
// ─────────────────────────────────────────────────────────────────────────
//  NOTICES
// ─────────────────────────────────────────────────────────────────────────

app.get('/notices', requireAuth, async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM notices ORDER BY date DESC, id DESC');
  res.json({ notices: rows });
});

app.post('/notices', requireAuth, requireRole('ADMIN'), async (req, res) => {
  const { title, description } = req.body;
  if (!title) return res.status(400).json({ error: 'title is required' });
  const { rows } = await pool.query(
    'INSERT INTO notices (title, description, posted_by) VALUES ($1, $2, $3) RETURNING *',
    [title, description || null, req.user.isSuperAdmin ? 'Super Admin' : 'Admin']
  );
  res.status(201).json({ notice: rows[0] });
});

// ─────────────────────────────────────────────────────────────────────────

// app.get('/health', (_req, res) => res.json({ status: 'ok' }));


// attendance_backend/src/server.js
const HOST = '0.0.0.0';  // ✅ Important for Render
app.listen(PORT, HOST, () => {
  console.log(`🚀 Attendance API running on ${HOST}:${PORT} ✅ `);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
});