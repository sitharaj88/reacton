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
exports.ReactonScanner = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Scans workspace Dart files for Reacton declarations
 * and builds a dependency graph.
 */
class ReactonScanner {
    constructor() {
        this._reactons = new Map();
        this._onDidChange = new vscode.EventEmitter();
        this.onDidChange = this._onDidChange.event;
        this._scanning = false;
    }
    get reactons() {
        return Array.from(this._reactons.values());
    }
    get reactonCount() {
        return this._reactons.size;
    }
    get isScanning() {
        return this._scanning;
    }
    getGraph() {
        const reactons = this.reactons;
        const edges = [];
        const nameSet = new Set(reactons.map((r) => r.name));
        for (const reacton of reactons) {
            for (const dep of reacton.dependencies) {
                if (nameSet.has(dep)) {
                    edges.push({ from: dep, to: reacton.name });
                }
            }
        }
        // Build subscribers from edges
        for (const reacton of reactons) {
            reacton.subscribers = edges
                .filter((e) => e.from === reacton.name)
                .map((e) => e.to);
        }
        return { reactons, edges };
    }
    async scan() {
        this._scanning = true;
        this._reactons.clear();
        try {
            const files = await vscode.workspace.findFiles('**/*.dart', '{**/.*,**/.dart_tool/**,**/build/**,**/generated/**}');
            for (const file of files) {
                await this.scanFile(file, false);
            }
        }
        finally {
            this._scanning = false;
        }
        this._onDidChange.fire();
    }
    async scanFile(uri, notify = true) {
        try {
            const content = await vscode.workspace.fs.readFile(uri);
            const text = Buffer.from(content).toString('utf8');
            const lines = text.split('\n');
            // Remove old reactons from this file
            for (const [name, info] of this._reactons) {
                if (info.file.toString() === uri.toString()) {
                    this._reactons.delete(name);
                }
            }
            // Scan each line for reacton declarations
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];
                this.scanLine(line, i, uri, text, lines);
            }
            if (notify) {
                this._onDidChange.fire();
            }
        }
        catch {
            // File might not be readable
        }
    }
    scanLine(line, lineNum, file, fullText, allLines) {
        let match;
        const docComment = this.extractDocComment(allLines, lineNum);
        // Check writable reacton: reacton<Type>( or reacton(
        const writablePattern = /final\s+(\w+)\s*=\s*reacton(?:<([^>]+)>)?\s*\(/;
        match = writablePattern.exec(line);
        if (match && !line.includes('computed') && !line.includes('asyncReacton')) {
            const col = match.index;
            const endLine = this.findClosingLine(fullText, lineNum);
            this.addReacton(match[1], 'writable', match[2] ?? 'dynamic', file, lineNum, col, endLine, [], docComment);
            return;
        }
        // Check computed reacton
        const computedPattern = /final\s+(\w+)\s*=\s*computed(?:<([^>]+)>)?\s*\(/;
        match = computedPattern.exec(line);
        if (match) {
            const deps = this.extractDependencies(fullText, lineNum);
            const col = match.index;
            const endLine = this.findClosingLine(fullText, lineNum);
            this.addReacton(match[1], 'computed', match[2] ?? 'dynamic', file, lineNum, col, endLine, deps, docComment);
            return;
        }
        // Check async reacton: asyncReacton<Type>(
        const asyncPattern = /final\s+(\w+)\s*=\s*asyncReacton(?:<([^>]+)>)?\s*\(/;
        match = asyncPattern.exec(line);
        if (match) {
            const deps = this.extractDependencies(fullText, lineNum);
            const col = match.index;
            const endLine = this.findClosingLine(fullText, lineNum);
            this.addReacton(match[1], 'async', match[2] ?? 'dynamic', file, lineNum, col, endLine, deps, docComment);
            return;
        }
        // Check family
        const familyPattern = /final\s+(\w+)\s*=\s*family(?:<([^,]+),\s*([^>]+)>)?\s*\(/;
        match = familyPattern.exec(line);
        if (match) {
            const valueType = match[2] && match[3] ? `${match[2]}, ${match[3]}` : 'dynamic';
            const col = match.index;
            const endLine = this.findClosingLine(fullText, lineNum);
            this.addReacton(match[1], 'family', valueType, file, lineNum, col, endLine, [], docComment);
            return;
        }
        // Check selector
        const selectorPattern = /final\s+(\w+)\s*=\s*selector(?:<([^,]+),\s*([^>]+)>)?\s*\(/;
        match = selectorPattern.exec(line);
        if (match) {
            const deps = this.extractDependencies(fullText, lineNum);
            const valueType = match[2] && match[3] ? `${match[2]} -> ${match[3]}` : 'dynamic';
            const col = match.index;
            const endLine = this.findClosingLine(fullText, lineNum);
            this.addReacton(match[1], 'selector', valueType, file, lineNum, col, endLine, deps, docComment);
            return;
        }
        // Check effect
        const effectPattern = /final\s+(\w+)\s*=\s*createEffect\s*\(/;
        match = effectPattern.exec(line);
        if (match) {
            const deps = this.extractDependencies(fullText, lineNum);
            const col = match.index;
            const endLine = this.findClosingLine(fullText, lineNum);
            this.addReacton(match[1], 'effect', 'void', file, lineNum, col, endLine, deps, docComment);
            return;
        }
        // Check state machine
        const smPattern = /final\s+(\w+)\s*=\s*stateMachine(?:<([^,]+),\s*([^>]+)>)?\s*\(/;
        match = smPattern.exec(line);
        if (match) {
            const valueType = match[2] && match[3] ? `${match[2]}, ${match[3]}` : 'dynamic';
            const col = match.index;
            const endLine = this.findClosingLine(fullText, lineNum);
            this.addReacton(match[1], 'stateMachine', valueType, file, lineNum, col, endLine, [], docComment);
            return;
        }
    }
    addReacton(name, type, valueType, file, line, column, endLine, dependencies, docComment) {
        this._reactons.set(name, {
            name,
            type,
            valueType: valueType.trim(),
            file,
            line,
            column,
            endLine,
            dependencies,
            subscribers: [],
            docComment,
        });
    }
    /**
     * Extract the doc comment (/// lines) above a declaration.
     */
    extractDocComment(lines, lineNum) {
        const commentLines = [];
        for (let i = lineNum - 1; i >= 0; i--) {
            const trimmed = lines[i].trim();
            if (trimmed.startsWith('///')) {
                commentLines.unshift(trimmed.replace(/^\/\/\/\s?/, ''));
            }
            else if (trimmed === '' || trimmed.startsWith('@')) {
                // Skip blank lines and annotations above doc comments
                if (trimmed.startsWith('@')) {
                    continue;
                }
                if (commentLines.length > 0) {
                    break;
                }
                continue;
            }
            else {
                break;
            }
        }
        return commentLines.length > 0 ? commentLines.join('\n') : undefined;
    }
    /**
     * Find the line number where the declaration's closing ); is.
     */
    findClosingLine(fullText, startLine) {
        const lines = fullText.split('\n');
        let depth = 0;
        let started = false;
        for (let i = startLine; i < Math.min(startLine + 50, lines.length); i++) {
            for (const ch of lines[i]) {
                if (ch === '(') {
                    depth++;
                    started = true;
                }
                if (ch === ')') {
                    depth--;
                }
            }
            if (started && depth <= 0) {
                return i;
            }
        }
        return startLine;
    }
    /**
     * Extract read() dependencies from the body following a reacton declaration.
     */
    extractDependencies(fullText, startLine) {
        const lines = fullText.split('\n');
        const deps = [];
        let depth = 0;
        let started = false;
        for (let i = startLine; i < Math.min(startLine + 50, lines.length); i++) {
            const line = lines[i];
            for (const ch of line) {
                if (ch === '(') {
                    depth++;
                    started = true;
                }
                if (ch === ')') {
                    depth--;
                }
            }
            // Find read() calls
            const readPattern = /read\s*\(\s*(\w+)\s*\)/g;
            let match;
            while ((match = readPattern.exec(line)) !== null) {
                if (!deps.includes(match[1])) {
                    deps.push(match[1]);
                }
            }
            if (started && depth <= 0) {
                break;
            }
        }
        return deps;
    }
    getReacton(name) {
        return this._reactons.get(name);
    }
    /**
     * Find all reactons in a specific file.
     */
    getReactonsInFile(uri) {
        const uriStr = uri.toString();
        return this.reactons.filter((r) => r.file.toString() === uriStr);
    }
    /**
     * Find all reactons that depend on the given reacton name.
     */
    getDependents(name) {
        return this.reactons.filter((r) => r.dependencies.includes(name));
    }
    /**
     * Find all reactons that the given reacton depends on.
     */
    getDependencies(name) {
        const reacton = this._reactons.get(name);
        if (!reacton) {
            return [];
        }
        return reacton.dependencies
            .map((d) => this._reactons.get(d))
            .filter((r) => r !== undefined);
    }
}
exports.ReactonScanner = ReactonScanner;
//# sourceMappingURL=reacton_scanner.js.map