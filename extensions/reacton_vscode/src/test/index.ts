import * as path from 'path';
import Mocha from 'mocha';
import * as fs from 'fs';

/**
 * Mocha entry point for the Reacton VSCode extension test suite.
 *
 * This module discovers all *.test.js files in the compiled test output
 * directory and runs them through Mocha. It serves as the standard
 * index file that can be referenced from package.json scripts or
 * imported by other test harnesses.
 *
 * The tests are pure unit tests that do NOT depend on the vscode module.
 * They test regex patterns, dependency extraction logic, snippet validation,
 * package.json structure, and other pure functions extracted from the
 * extension source code.
 */
export function run(): Promise<void> {
  const mocha = new Mocha({
    ui: 'bdd',
    color: true,
    timeout: 10000,
    reporter: 'spec',
  });

  const testsRoot = path.resolve(__dirname);

  return new Promise((resolve, reject) => {
    try {
      const testFiles = findTestFiles(testsRoot);

      for (const file of testFiles) {
        mocha.addFile(file);
      }

      mocha.run((failures) => {
        if (failures > 0) {
          reject(new Error(`${failures} test(s) failed.`));
        } else {
          resolve();
        }
      });
    } catch (err) {
      reject(err);
    }
  });
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

// Allow running directly with: node ./out/test/index.js
if (require.main === module) {
  run()
    .then(() => {
      console.log('All tests passed.');
      process.exit(0);
    })
    .catch((err) => {
      console.error(err.message);
      process.exit(1);
    });
}
