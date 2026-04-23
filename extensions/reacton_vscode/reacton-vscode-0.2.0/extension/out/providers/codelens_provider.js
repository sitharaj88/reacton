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
exports.ReactonCodeLensProvider = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Code lens provider that shows metadata above reacton declarations:
 * - Reacton type (writable, computed, async, etc.)
 * - Number of dependencies and subscribers
 * - "Show in graph" action
 * - "Go to definition" for dependencies
 */
class ReactonCodeLensProvider {
    constructor(scanner) {
        this.scanner = scanner;
        this._onDidChangeCodeLenses = new vscode.EventEmitter();
        this.onDidChangeCodeLenses = this._onDidChangeCodeLenses.event;
        scanner.onDidChange(() => this._onDidChangeCodeLenses.fire());
    }
    provideCodeLenses(document) {
        const lenses = [];
        const text = document.getText();
        const lines = text.split('\n');
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const reactonInfo = this.detectReactonDeclaration(line, i);
            if (reactonInfo) {
                const range = new vscode.Range(i, 0, i, line.length);
                // Type info lens with subscriber count
                const typeLabel = this.getTypeLabel(reactonInfo);
                const subscriberCount = this.scanner.getDependents(reactonInfo.name).length;
                const subscriberLabel = subscriberCount > 0
                    ? ` | $(eye) ${subscriberCount} ${subscriberCount === 1 ? 'subscriber' : 'subscribers'}`
                    : '';
                lenses.push(new vscode.CodeLens(range, {
                    title: `${typeLabel}${subscriberLabel}`,
                    command: '',
                }));
                // Dependencies lens (for computed/async/selector/effect)
                if (reactonInfo.deps.length > 0) {
                    lenses.push(new vscode.CodeLens(range, {
                        title: `$(link) ${reactonInfo.deps.length} ${reactonInfo.deps.length === 1 ? 'dependency' : 'dependencies'}: ${reactonInfo.deps.join(', ')}`,
                        command: '',
                    }));
                }
                // Show in graph lens
                lenses.push(new vscode.CodeLens(range, {
                    title: '$(graph) Show in Graph',
                    command: 'reacton.showGraph',
                }));
                // Find references lens
                lenses.push(new vscode.CodeLens(range, {
                    title: '$(references) Find References',
                    command: 'reacton.findReferences',
                    arguments: [reactonInfo.name],
                }));
            }
        }
        return lenses;
    }
    detectReactonDeclaration(line, _lineNum) {
        // writable reacton: reacton<Type>( or reacton(
        let match = /final\s+(\w+)\s*=\s*reacton(?:<[^>]+>)?\s*\(/.exec(line);
        if (match && !line.includes('computed') && !line.includes('asyncReacton')) {
            return { name: match[1], type: 'reacton', deps: [] };
        }
        // computed reacton
        match = /final\s+(\w+)\s*=\s*computed(?:<[^>]+>)?\s*\(/.exec(line);
        if (match) {
            const reacton = this.scanner.getReacton(match[1]);
            return {
                name: match[1],
                type: 'computed',
                deps: reacton?.dependencies ?? [],
            };
        }
        // async reacton
        match = /final\s+(\w+)\s*=\s*asyncReacton(?:<[^>]+>)?\s*\(/.exec(line);
        if (match) {
            const reacton = this.scanner.getReacton(match[1]);
            return {
                name: match[1],
                type: 'async',
                deps: reacton?.dependencies ?? [],
            };
        }
        // family
        match = /final\s+(\w+)\s*=\s*family(?:<[^>]+>)?\s*\(/.exec(line);
        if (match) {
            return { name: match[1], type: 'family', deps: [] };
        }
        // selector
        match = /final\s+(\w+)\s*=\s*selector(?:<[^>]+>)?\s*\(/.exec(line);
        if (match) {
            const reacton = this.scanner.getReacton(match[1]);
            return {
                name: match[1],
                type: 'selector',
                deps: reacton?.dependencies ?? [],
            };
        }
        // effect
        match = /final\s+(\w+)\s*=\s*createEffect\s*\(/.exec(line);
        if (match) {
            const reacton = this.scanner.getReacton(match[1]);
            return {
                name: match[1],
                type: 'effect',
                deps: reacton?.dependencies ?? [],
            };
        }
        // state machine
        match = /final\s+(\w+)\s*=\s*stateMachine(?:<[^>]+>)?\s*\(/.exec(line);
        if (match) {
            return { name: match[1], type: 'stateMachine', deps: [] };
        }
        return null;
    }
    getTypeLabel(info) {
        const icons = {
            reacton: '$(symbol-variable)',
            computed: '$(symbol-function)',
            async: '$(cloud)',
            family: '$(symbol-array)',
            selector: '$(filter)',
            effect: '$(zap)',
            stateMachine: '$(server-process)',
        };
        const labels = {
            reacton: 'Writable Reacton',
            computed: 'Computed Reacton',
            async: 'Async Reacton',
            family: 'Reacton Family',
            selector: 'Selector',
            effect: 'Effect',
            stateMachine: 'State Machine',
        };
        const icon = icons[info.type] ?? '$(circle)';
        const label = labels[info.type] ?? info.type;
        return `${icon} ${label}`;
    }
}
exports.ReactonCodeLensProvider = ReactonCodeLensProvider;
//# sourceMappingURL=codelens_provider.js.map