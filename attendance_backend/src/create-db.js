// create-db.js
const { Client } = require('pg');
require('dotenv').config();

async function createDatabase() {
  // Connect to default 'postgres' database
  const client = new Client({
    host: process.env.PGHOST || 'localhost',
    port: Number(process.env.PGPORT) || 5432,
    user: process.env.PGUSER || 'postgres',
    password: process.env.PGPASSWORD || 'postgres',
    database: 'postgres', // Always connect to default database
    ssl: process.env.PGSSL === 'false' ? false : { rejectUnauthorized: false },
  });

  try {
    await client.connect();
    console.log('✅ Connected to PostgreSQL server');
    
    const dbName = process.env.PGDATABASE || 'attendance_app';
    
    // Check if database exists
    const checkResult = await client.query(
      "SELECT 1 FROM pg_database WHERE datname = $1",
      [dbName]
    );
    
    if (checkResult.rows.length > 0) {
      console.log(`✅ Database "${dbName}" already exists`);
    } else {
      // Create database
      await client.query(`CREATE DATABASE ${dbName}`);
      console.log(`✅ Database "${dbName}" created successfully`);
    }
  } catch (err) {
    console.error('❌ Error:', err.message);
    
    if (err.code === '28P01') {
      console.log('\n🔧 Password authentication failed. Check your .env file:');
      console.log('   PGPASSWORD in .env must match PostgreSQL password');
    } else if (err.code === 'ENOTFOUND' || err.code === 'ECONNREFUSED') {
      console.log('\n🔧 PostgreSQL is not running or unreachable.');
      console.log('   Start PostgreSQL service first.');
    }
  } finally {
    await client.end();
  }
}

createDatabase();