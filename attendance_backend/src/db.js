const { Pool } = require('pg');
require('dotenv').config();

// Uses DATABASE_URL if provided (e.g. from Render/Railway/Supabase),
// otherwise falls back to discrete PG* vars for local dev.
const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.PGSSL === 'false' ? false : { rejectUnauthorized: false },
    })
  : new Pool({
      host: process.env.PGHOST || 'localhost',
      port: Number(process.env.PGPORT) || 5432,
      user: process.env.PGUSER || 'attendance_user',
      password: process.env.PGPASSWORD || 'postgres',
      database: process.env.PGDATABASE || 'attendance_app',
    });

pool.on('error', (err) => {
  console.error('Unexpected PG pool error', err);
});

module.exports = pool;