// ============================================================================
//  Seeds the ONE super admin account. Safe to run multiple times — it will
//  never create a duplicate and will never touch an existing super admin's
//  password (so changing SUPER_ADMIN_PASSWORD in .env later does NOT
//  silently reset it — use a dedicated reset script for that instead).
// ============================================================================
require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('./db');

const SUPER_ADMIN_EMAIL = process.env.SUPER_ADMIN_EMAIL || 'sarthakbhawsar8@gmail.com';
const SUPER_ADMIN_PASSWORD = process.env.SUPER_ADMIN_PASSWORD || 'sarthak@456';
const SUPER_ADMIN_NAME = process.env.SUPER_ADMIN_NAME || 'Sarthak Bhawsar';

async function seed() {
  const client = await pool.connect();
  try {
    const existing = await client.query(
      'SELECT id FROM users WHERE is_super_admin = TRUE LIMIT 1'
    );

    if (existing.rows.length > 0) {
      console.log('✅ Super admin already exists (id=%s). Skipping.', existing.rows[0].id);
      return;
    }

    const hash = await bcrypt.hash(SUPER_ADMIN_PASSWORD, 12);

    await client.query(
      `INSERT INTO users (name, email, password_hash, role, is_super_admin, is_active)
       VALUES ($1, LOWER($2), $3, 'ADMIN', TRUE, TRUE)
       ON CONFLICT (id) DO NOTHING`,
      [SUPER_ADMIN_NAME, SUPER_ADMIN_EMAIL, hash]
    );

    console.log('✅ Super admin created:', SUPER_ADMIN_EMAIL);
  } catch (err) {
    console.error('❌ Seed failed:', err.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

seed();