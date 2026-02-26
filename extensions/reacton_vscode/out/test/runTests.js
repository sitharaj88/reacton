"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const path = __importStar(require("path"));
const mocha_1 = __importDefault(require("mocha"));
const fs = __importStar(require("fs"));
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
async function main() {
    const mocha = new mocha_1.default({
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
    const failures = await new Promise((resolve) => {
        mocha.run((failCount) => {
            resolve(failCount);
        });
    });
    if (failures > 0) {
        console.error(`\n${failures} test(s) failed.`);
        process.exit(1);
    }
    else {
        console.log('\nAll tests passed.');
    }
}
/**
 * Recursively find all *.test.js files under the given directory.
 */
function findTestFiles(dir) {
    const results = [];
    if (!fs.existsSync(dir)) {
        return results;
    }
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            results.push(...findTestFiles(fullPath));
        }
        else if (entry.isFile() && entry.name.endsWith('.test.js')) {
            results.push(fullPath);
        }
    }
    return results;
}
main().catch((err) => {
    console.error('Test runner failed:', err);
    process.exit(1);
});
//# sourceMappingURL=runTests.js.map