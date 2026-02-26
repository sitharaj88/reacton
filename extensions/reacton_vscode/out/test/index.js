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
exports.run = run;
const path = __importStar(require("path"));
const mocha_1 = __importDefault(require("mocha"));
const fs = __importStar(require("fs"));
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
function run() {
    const mocha = new mocha_1.default({
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
                }
                else {
                    resolve();
                }
            });
        }
        catch (err) {
            reject(err);
        }
    });
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
//# sourceMappingURL=index.js.map