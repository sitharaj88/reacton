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
exports.ReactonDocumentSymbolProvider = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Maps each Reacton type to an appropriate VS Code SymbolKind
 * for display in the file outline, breadcrumbs, and Go to Symbol.
 */
const SYMBOL_KIND_MAP = {
    writable: vscode.SymbolKind.Variable,
    computed: vscode.SymbolKind.Function,
    async: vscode.SymbolKind.Interface,
    family: vscode.SymbolKind.Array,
    selector: vscode.SymbolKind.Property,
    effect: vscode.SymbolKind.Event,
    stateMachine: vscode.SymbolKind.Enum,
};
/**
 * Human-readable labels for each Reacton type, used in the detail field
 * of document symbols.
 */
const TYPE_LABELS = {
    writable: 'Writable Reacton',
    computed: 'Computed Reacton',
    async: 'Async Reacton',
    family: 'Reacton Family',
    selector: 'Selector',
    effect: 'Effect',
    stateMachine: 'State Machine',
};
/**
 * Document symbol provider that surfaces Reacton declarations in
 * the file outline (breadcrumbs, Go to Symbol, Ctrl+Shift+O).
 *
 * Each Reacton declaration is represented as a DocumentSymbol with:
 * - A name matching the declared variable name
 * - A detail string showing the Reacton type and value type
 * - An appropriate SymbolKind based on the Reacton type
 * - A range spanning the full declaration (from declaration line to endLine)
 * - A selection range on the declaration line itself
 *
 * When a file contains multiple Reacton declarations, they are grouped
 * under a parent "Reactons" namespace symbol for a cleaner outline.
 */
class ReactonDocumentSymbolProvider {
    constructor(scanner) {
        this.scanner = scanner;
    }
    provideDocumentSymbols(document, _token) {
        const reactons = this.scanner.getReactonsInFile(document.uri);
        if (reactons.length === 0) {
            return [];
        }
        const symbols = reactons.map((reacton) => this.createSymbol(reacton, document));
        // When there are multiple reactons, group them under a parent symbol
        // for a cleaner outline hierarchy.
        if (symbols.length > 1) {
            return [this.createGroupSymbol(symbols, document)];
        }
        return symbols;
    }
    /**
     * Creates a DocumentSymbol for a single Reacton declaration.
     */
    createSymbol(reacton, document) {
        const kind = SYMBOL_KIND_MAP[reacton.type];
        const detail = `${TYPE_LABELS[reacton.type]}<${reacton.valueType}>`;
        // Full range spans from the declaration line to the end of the declaration block.
        // Clamp endLine to the document's last line to avoid out-of-bounds errors
        // when the scanner data is stale relative to the current document content.
        const lastDocLine = document.lineCount - 1;
        const clampedStartLine = Math.min(reacton.line, lastDocLine);
        const clampedEndLine = Math.min(reacton.endLine, lastDocLine);
        const range = new vscode.Range(clampedStartLine, 0, clampedEndLine, document.lineAt(clampedEndLine).text.length);
        // Selection range covers just the declaration line, starting at the column
        // where the declaration was found.
        const declarationLine = document.lineAt(clampedStartLine);
        const selectionRange = new vscode.Range(clampedStartLine, reacton.column, clampedStartLine, declarationLine.text.length);
        return new vscode.DocumentSymbol(reacton.name, detail, kind, range, selectionRange);
    }
    /**
     * Creates a parent "Reactons" namespace symbol that contains all
     * individual Reacton symbols as children. This provides a clean
     * grouping in the file outline when multiple Reactons are declared.
     */
    createGroupSymbol(children, document) {
        // The group range encompasses all child symbols, from the first
        // declaration to the last.
        const firstLine = Math.min(...children.map((c) => c.range.start.line));
        const lastLine = Math.max(...children.map((c) => c.range.end.line));
        const groupRange = new vscode.Range(firstLine, 0, lastLine, document.lineAt(lastLine).text.length);
        const selectionRange = new vscode.Range(firstLine, 0, firstLine, document.lineAt(firstLine).text.length);
        const group = new vscode.DocumentSymbol('Reactons', `${children.length} declarations`, vscode.SymbolKind.Namespace, groupRange, selectionRange);
        group.children = children;
        return group;
    }
}
exports.ReactonDocumentSymbolProvider = ReactonDocumentSymbolProvider;
//# sourceMappingURL=symbol_provider.js.map