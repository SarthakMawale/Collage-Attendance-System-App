// attendance_backend/src/db.js

const { Pool } = require('pg');
require('dotenv').config();

// ✅ Use DATABASE_URL from environment (Supabase)
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,  // ✅ Required for Supabase
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// Test connection
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Database connection error:', err.message);
    console.error('📌 DATABASE_URL:', process.env.DATABASE_URL ? 'Set' : 'Not Set');
  } else {
    console.log('✅ Database connected successfully');
    release();
  }
});

module.exports = pool;
