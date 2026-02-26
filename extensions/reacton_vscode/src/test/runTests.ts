import * as path from 'path';
import Mocha from 'mocha';
import * as fs from 'fs';

/**
 * Standalone test runner for Reacton VSCode extension unit tests.
 *
 * Discovers and runs all compiled test files (*.test.js) in the test
 * output directory using Mocha. This runner does NOT require the
 * VSCode test electron host -- it runs pure unit tests that exercise
 * regex patterns, logic, snippets, and package.json validation.
 *
 * Usage:
 *   npx tsc -p ./ && node ./out/test/runTests.js
 *   -- or --
 *   npm test
 */
async function main(): Promise<void> {
  const mocha = new Mocha({
    ui: 'bdd',
    color: true,
    timeout: 10000,
    reporter: 'spec',
  });

  // The compiled test files live in out/test/
  const testsRoot = path.resolve(__dirname);

  // Discover all *.test.js files in the test directory
  const testFiles = findTestFiles(testsRoot);

  if (testFiles.length === 0) {
    console.error('No test files found in', testsRoot);
    process.exit(1);
  }

  // Add each test file to the Mocha runner
  for (const file of testFiles) {
    mocha.addFile(file);
  }

  // Run the tests
  const failures = await new Promise<number>((resolve) => {
    mocha.run((failCount) => {
      resolve(failCount);
    });
  });

  if (failures > 0) {
    console.error(`\n${failures} test(s) failed.`);
    process.exit(1);
  } else {
    console.log('\nAll tests passed.');
  }
}

/**
 * Recursively find all *.test.js files under the given directory.
 */
function findTestFiles(dir: string): string[] {
  const results: string[] = [];

  if (!fs.existsSync(dir)) {
    return results;
  }

  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...findTestFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.test.js')) {
      results.push(fullPath);
    }
  }

  return results;
}

main().catch((err) => {
  console.error('Test runner failed:', err);
  process.exit(1);
});
