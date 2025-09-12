// Script to run the app on web
const { exec } = require('child_process');
const path = require('path');

// Get the project root directory
const projectRoot = __dirname;

// Run flutter on web
console.log('🚀 Starting Math Scanner on web...');
const process = exec('flutter run -d chrome', { cwd: projectRoot });

process.stdout.on('data', (data) => {
  console.log(data);
});

process.stderr.on('data', (data) => {
  console.error(data);
});

process.on('exit', (code) => {
  console.log(`Process exited with code ${code}`);
});
