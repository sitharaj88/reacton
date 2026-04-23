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
exports.ReactonStatusBar = void 0;
const vscode = __importStar(require("vscode"));
/**
 * Human-readable labels for each Reacton type, used in the
 * status bar tooltip breakdown.
 */
const TYPE_LABELS = {
    writable: 'Writable',
    computed: 'Computed',
    async: 'Async',
    family: 'Family',
    selector: 'Selector',
    effect: 'Effect',
    stateMachine: 'State Machine',
};
/**
 * Provides a status bar item that displays the total number of
 * Reacton declarations detected in the workspace.
 *
 * The item appears on the left side of the status bar and shows:
 * - "$(symbol-variable) N Reactons" when idle
 * - "$(sync~spin) Scanning..." while the scanner is running
 *
 * Clicking the item executes the `reacton.showGraph` command to
 * open the dependency graph panel.
 *
 * The tooltip provides a breakdown of reacton counts by type.
 */
class ReactonStatusBar {
    constructor(scanner) {
        this.scanner = scanner;
        this.disposables = [];
        this.statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
        this.statusBarItem.command = 'reacton.showGraph';
        // Listen for scanner changes and update the display
        const changeListener = scanner.onDidChange(() => this.update());
        this.disposables.push(changeListener);
        // Perform the initial render
        this.update();
        this.statusBarItem.show();
    }
    /**
     * Updates the status bar text and tooltip to reflect the
     * current scanner state.
     */
    update() {
        if (this.scanner.isScanning) {
            this.statusBarItem.text = '$(sync~spin) Scanning...';
            this.statusBarItem.tooltip = 'Reacton: Scanning workspace for declarations...';
            return;
        }
        const count = this.scanner.reactonCount;
        this.statusBarItem.text = `$(symbol-variable) ${count} Reacton${count === 1 ? '' : 's'}`;
        this.statusBarItem.tooltip = this.buildTooltip();
    }
    /**
     * Builds a rich MarkdownString tooltip that shows a breakdown
     * of reacton counts grouped by type.
     */
    buildTooltip() {
        const md = new vscode.MarkdownString();
        md.isTrusted = true;
        const reactons = this.scanner.reactons;
        const total = reactons.length;
        md.appendMarkdown(`**Reacton Workspace Summary**\n\n`);
        md.appendMarkdown(`Total: **${total}** reacton${total === 1 ? '' : 's'}\n\n`);
        if (total === 0) {
            md.appendMarkdown('_No reacton declarations found._\n');
            return md;
        }
        // Group by type and display counts
        const counts = this.countByType(reactons);
        md.appendMarkdown('| Type | Count |\n');
        md.appendMarkdown('|------|------:|\n');
        for (const [type, count] of counts) {
            const label = TYPE_LABELS[type] ?? type;
            md.appendMarkdown(`| ${label} | ${count} |\n`);
        }
        md.appendMarkdown('\n_Click to open the dependency graph._');
        return md;
    }
    /**
     * Groups reactons by type and returns an array of [type, count]
     * pairs sorted in descending order by count.
     */
    countByType(reactons) {
        const map = new Map();
        for (const reacton of reactons) {
            map.set(reacton.type, (map.get(reacton.type) ?? 0) + 1);
        }
        return Array.from(map.entries()).sort((a, b) => b[1] - a[1]);
    }
    dispose() {
        this.statusBarItem.dispose();
        for (const disposable of this.disposables) {
            disposable.dispose();
        }
    }
}
exports.ReactonStatusBar = ReactonStatusBar;
//# sourceMappingURL=statusbar_provider.js.map