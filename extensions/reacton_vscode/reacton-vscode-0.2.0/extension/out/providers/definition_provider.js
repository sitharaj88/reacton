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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReactonReferenceProvider = exports.ReactonDefinitionProvider = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Definition provider that enables "Go to Definition" for Reacton
 * declarations in Dart files.
 *
 * When the cursor is on a word that matches a known reacton name,
 * this provider returns the Location of the reacton's declaration,
 * allowing the user to jump directly to where it is defined.
 */
class ReactonDefinitionProvider {
    constructor(scanner) {
        this.scanner = scanner;
    }
    provideDefinition(document, position, _token) {
        const wordRange = document.getWordRangeAtPosition(position, /[a-zA-Z_]\w*/);
        if (!wordRange) {
            return undefined;
        }
        const word = document.getText(wordRange);
        const reacton = this.scanner.getReacton(word);
        if (!reacton) {
            return undefined;
        }
        return new vscode.Location(reacton.file, new vscode.Position(reacton.line, reacton.column));
    }
}
exports.ReactonDefinitionProvider = ReactonDefinitionProvider;
/**
 * Reference provider that enables "Find All References" for Reacton
 * declarations in Dart files.
 *
 * When the cursor is on a word that matches a known reacton name,
 * this provider searches all workspace Dart files for occurrences
 * of that name and returns their locations. This includes:
 * - The declaration site itself (when includeDeclaration is true)
 * - All usage sites across the workspace (read, watch, listen, etc.)
 *
 * Results are gathered by scanning file contents with a word-boundary
 * regex to avoid false positives from partial matches.
 */
class ReactonReferenceProvider {
    constructor(scanner) {
        this.scanner = scanner;
    }
    async provideReferences(document, position, context, _token) {
        const wordRange = document.getWordRangeAtPosition(position, /[a-zA-Z_]\w*/);
        if (!wordRange) {
            return [];
        }
        const word = document.getText(wordRange);
        const reacton = this.scanner.getReacton(word);
        if (!reacton) {
            return [];
        }
        const locations = [];
        // Include the declaration location if requested
        if (context.includeDeclaration) {
            locations.push(new vscode.Location(reacton.file, new vscode.Position(reacton.line, reacton.column)));
        }
        // Search all workspace Dart files for references to this reacton
        const dartFiles = await vscode.workspace.findFiles('**/*.dart', '{**/.*,**/.dart_tool/**,**/build/**,**/generated/**}');
        // Use a word-boundary pattern to avoid matching substrings.
        // Dart identifiers consist of word characters, so \b is appropriate.
        const pattern = new RegExp(`\\b${escapeRegExp(word)}\\b`, 'g');
        for (const fileUri of dartFiles) {
            const fileLocations = await this.findReferencesInFile(fileUri, reacton, pattern, context.includeDeclaration);
            locations.push(...fileLocations);
        }
        return locations;
    }
    /**
     * Scans a single file for all occurrences of the reacton name
     * and returns their locations.
     *
     * Skips the declaration site itself to avoid duplicating the
     * location already added from the scanner data (unless the file
     * is different from the declaration file, which shouldn't happen
     * but is handled defensively).
     */
    async findReferencesInFile(fileUri, reacton, pattern, includeDeclaration) {
        const locations = [];
        try {
            const content = await vscode.workspace.fs.readFile(fileUri);
            const text = Buffer.from(content).toString('utf8');
            const lines = text.split('\n');
            const isDeclarationFile = fileUri.toString() === reacton.file.toString();
            for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
                const line = lines[lineIndex];
                // Reset the regex lastIndex for each line
                pattern.lastIndex = 0;
                let match;
                while ((match = pattern.exec(line)) !== null) {
                    // Skip the declaration site in the declaration file
                    // (it was already added from scanner data if includeDeclaration is true)
                    if (isDeclarationFile &&
                        lineIndex === reacton.line &&
                        match.index === reacton.column) {
                        continue;
                    }
                    locations.push(new vscode.Location(fileUri, new vscode.Position(lineIndex, match.index)));
                }
            }
        }
        catch {
            // File might not be readable; skip silently
        }
        return locations;
    }
}
exports.ReactonReferenceProvider = ReactonReferenceProvider;
/**
 * Escapes special regex characters in a string so it can be used
 * safely inside a RegExp constructor.
 */
function escapeRegExp(text) {
    return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
//# sourceMappingURL=definition_provider.js.map