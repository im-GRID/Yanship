const mysql = require('mysql2/promise');

// Database configuration
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'yanship_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

// Create connection pool
const pool = mysql.createPool(dbConfig);

// Test driver authentication functions (copied from whatsappBotController.js)
async function findDriverByPhone(phone) {
  try {
    const cleanPhone = phone.replace('whatsapp:', '').replace(/\s+/g, '').trim();
    
    console.log(`🔍 Searching for driver with phone: ${cleanPhone}`);
    
    const [drivers] = await pool.query(
      'SELECT * FROM cdb_users WHERE phone LIKE ? AND userlevel > 5 AND active = 1',
      [`%${cleanPhone}%`]
    );
    
    console.log(`📋 Found ${drivers.length} drivers matching phone ${cleanPhone}`);
    if (drivers.length > 0) {
      console.log(`✅ Driver found: ${drivers[0].fname} ${drivers[0].lname} (ID: ${drivers[0].id}, userlevel: ${drivers[0].userlevel})`);
    }
    
    return drivers.length > 0 ? drivers[0] : null;
  } catch (error) {
    console.error('Error finding driver:', error);
    return null;
  }
}

async function authenticateDriver(username, password) {
  try {
    console.log(`🔐 Authenticating driver: ${username}`);
    
    const [drivers] = await pool.query(
      'SELECT * FROM cdb_users WHERE username = ? AND userlevel > 5 AND active = 1',
      [username]
    );
    
    if (drivers.length === 0) {
      console.log(`❌ No driver found with username: ${username}`);
      return null;
    }
    
    const driver = drivers[0];
    console.log(`📋 Driver found: ${driver.fname} ${driver.lname} (ID: ${driver.id}, userlevel: ${driver.userlevel})`);
    
    // For plain text passwords (current setup)
    const isPasswordValid = password === driver.password;
    
    if (!isPasswordValid) {
      console.log(`❌ Invalid password for driver: ${username}`);
      return null;
    }
    
    console.log(`✅ Authentication successful for driver: ${username}`);
    return driver;
  } catch (error) {
    console.error('Error authenticating driver:', error);
    return null;
  }
}

async function testDriverAuth() {
  console.log('🧪 Testing WhatsApp Bot Driver Authentication\n');
  
  try {
    // First, let's check what drivers exist with userlevel > 5
    console.log('📊 Checking all active drivers with userlevel > 5:');
    const [allDrivers] = await pool.query(
      'SELECT id, username, fname, lname, phone, userlevel, active FROM cdb_users WHERE userlevel > 5 AND active = 1'
    );
    
    console.log(`Found ${allDrivers.length} active drivers:`);
    allDrivers.forEach(driver => {
      console.log(`  - ID: ${driver.id}, Username: ${driver.username}, Name: ${driver.fname} ${driver.lname}, Phone: ${driver.phone}, Level: ${driver.userlevel}`);
    });
    
    if (allDrivers.length === 0) {
      console.log('❌ No active drivers found with userlevel > 5');
      return;
    }
    
    console.log('\n🔍 Testing phone number lookup:');
    
    // Test with driver 57's phone if it exists
    const driver57 = allDrivers.find(d => d.id === 57);
    if (driver57 && driver57.phone) {
      console.log(`\nTesting phone lookup for driver 57: ${driver57.phone}`);
      const foundByPhone = await findDriverByPhone(driver57.phone);
      if (foundByPhone) {
        console.log('✅ Phone lookup successful for driver 57');
      } else {
        console.log('❌ Phone lookup failed for driver 57');
      }
      
      // Test with WhatsApp format
      const whatsappPhone = `whatsapp:${driver57.phone}`;
      console.log(`\nTesting WhatsApp phone format: ${whatsappPhone}`);
      const foundByWhatsAppPhone = await findDriverByPhone(whatsappPhone);
      if (foundByWhatsAppPhone) {
        console.log('✅ WhatsApp phone lookup successful for driver 57');
      } else {
        console.log('❌ WhatsApp phone lookup failed for driver 57');
      }
    }
    
    // Test with first available driver
    const testDriver = allDrivers[0];
    if (testDriver.phone) {
      console.log(`\nTesting phone lookup for driver ${testDriver.id}: ${testDriver.phone}`);
      const foundByPhone = await findDriverByPhone(testDriver.phone);
      if (foundByPhone) {
        console.log(`✅ Phone lookup successful for driver ${testDriver.id}`);
      } else {
        console.log(`❌ Phone lookup failed for driver ${testDriver.id}`);
      }
    }
    
    console.log('\n🔐 Testing username/password authentication:');
    
    // Test authentication with driver 57 if exists
    if (driver57) {
      console.log(`\nTesting authentication for driver 57 (${driver57.username})`);
      // Note: We don't know the actual password, so this will likely fail
      const authResult = await authenticateDriver(driver57.username, 'test_password');
      if (authResult) {
        console.log('✅ Authentication successful for driver 57');
      } else {
        console.log('❌ Authentication failed for driver 57 (expected - password unknown)');
      }
    }
    
    console.log('\n📱 WhatsApp Bot Access Test Summary:');
    console.log('✅ Fixed userlevel criteria from = 3 to > 5');
    console.log('✅ Added active = 1 condition');
    console.log('✅ Added detailed logging for debugging');
    console.log('✅ Phone number lookup now matches invoice system criteria');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await pool.end();
  }
}

// Run the test
testDriverAuth();
