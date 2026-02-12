const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Get the version number provided as argument
let version = process.argv[2];

if (version.startsWith('v')) {
    version = version.slice(1)
}

if (!version) {
    console.error('Please provide a version number to bump.');
    process.exit(1);
}

const packageJsonPath = path.join(process.cwd(), 'package.json');
const packageJson = require(packageJsonPath);

packageJson.version = version;

fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 4));

console.log(`Version bumped to ${version} in package.json successfully.`);

try {
    execSync('pnpm run build');
    execSync('git add .');
    execSync(`git commit -m "build: bump version to ${version}"`);
} catch (error) {
    console.error('Error committing changes:', error.message);
}
