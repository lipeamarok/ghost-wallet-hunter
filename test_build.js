/**
 * Test Build Script
 * =================
 *
 * Simple script to test if all imports are working correctly
 * before running the full build process.
 */

// Test import from config files
try {
  console.log('Testing config imports...');

  // Test environment.js
  import('./frontend/src/config/environment.js').then(env => {
    console.log('✅ Environment config loaded:', Object.keys(env));
  }).catch(err => {
    console.error('❌ Environment config failed:', err.message);
  });

  // Test endpoints.js
  import('./frontend/src/config/endpoints.js').then(endpoints => {
    console.log('✅ Endpoints config loaded:', Object.keys(endpoints));
  }).catch(err => {
    console.error('❌ Endpoints config failed:', err.message);
  });

  // Test constants.js
  import('./frontend/src/config/constants.js').then(constants => {
    console.log('✅ Constants config loaded:', Object.keys(constants));
  }).catch(err => {
    console.error('❌ Constants config failed:', err.message);
  });

  console.log('Import tests completed.');

} catch (error) {
  console.error('Test failed:', error.message);
}
