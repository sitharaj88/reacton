import * as vscode from 'vscode';
import { ReactonScanner } from './reacton_scanner';

/** Diagnostic code identifiers for each rule. */
const enum DiagnosticCode {
  MissingName = 'reacton-missing-name',
  ReactonInBuild = 'reacton-in-build',
  CircularDependency = 'reacton-circular-dependency',
  UnusedReacton = 'reacton-unused',
  TooManyWatchers = 'reacton-too-many-watchers',
}

/** Maximum number of context.watch() calls allowed in a single build method. */
const MAX_WATCHERS_IN_BUILD = 3;

/**
 * Diagnostics provider that analyzes Dart files for common Reacton
 * anti-patterns and issues.
 *
 * Detects:
 * 1. Missing `name` parameter in reacton declarations (Warning)
 * 2. Reacton creation inside a build() method (Error)
 * 3. Circular dependencies between reactons (Error)
 * 4. Unused reacton declarations (Hint)
 * 5. Too many context.watch() calls in a single build method (Information)
 */
export class ReactonDiagnosticsProvider implements vscode.Disposable {
  private readonly _diagnosticCollection: vscode.DiagnosticCollection;
  private readonly _disposables: vscode.Disposable[] = [];

  constructor(private readonly scanner: ReactonScanner) {
    this._diagnosticCollection = vscode.languages.createDiagnosticCollection('reacton');

    // Re-analyze open documents when the scanner finishes a scan.
    this._disposables.push(
      scanner.onDidChange(() => {
        this._analyzeOpenDocuments();
        this.analyzeWorkspace();
      })
    );

    // Analyze a document each time it is opened or its content changes.
    this._disposables.push(
      vscode.workspace.onDidOpenTextDocument((doc) => {
        if (doc.languageId === 'dart') {
          this.analyzeDocument(doc);
        }
      })
    );

    this._disposables.push(
      vscode.workspace.onDidChangeTextDocument((event) => {
        if (event.document.languageId === 'dart') {
          this.analyzeDocument(event.document);
        }
      })
    );

    // Clear diagnostics for files that are closed.
    this._disposables.push(
      vscode.workspace.onDidCloseTextDocument((doc) => {
        this._diagnosticCollection.delete(doc.uri);
      })
    );
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /**
   * Analyze a single document for per-file diagnostics:
   * - Missing `name` parameter
   * - Reacton created inside build()
   * - Too many context.watch() calls in build()
   */
  analyzeDocument(document: vscode.TextDocument): void {
    if (document.languageId !== 'dart') {
      return;
    }

    const text = document.getText();
    const lines = text.split('\n');
    const diagnostics: vscode.Diagnostic[] = [];

    // Build a map of build-method ranges so we can test whether a line falls
    // inside one.
    const buildRanges = this._findBuildMethodRanges(lines);

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      // Rule 1 - Missing `name` parameter
      this._checkMissingName(line, i, lines, text, diagnostics);

      // Rule 2 - Reacton created inside build()
      this._checkReactonInBuild(line, i, buildRanges, diagnostics);
    }

    // Rule 5 - Too many watchers in a single build method
    this._checkTooManyWatchers(lines, buildRanges, diagnostics);

    // Merge in any workspace-level diagnostics that target this file (circular
    // deps, unused reactons).  Those are computed separately by
    // analyzeWorkspace() so we preserve them here.
    const existing = this._diagnosticCollection.get(document.uri);
    const workspaceDiags = (existing ?? []).filter(
      (d) =>
        d.code === DiagnosticCode.CircularDependency ||
        d.code === DiagnosticCode.UnusedReacton
    );

    this._diagnosticCollection.set(document.uri, [...diagnostics, ...workspaceDiags]);
  }

  /**
   * Run cross-file checks that require knowledge of the full dependency graph:
   * - Circular dependency detection
   * - Unused reacton detection
   */
  analyzeWorkspace(): void {
    // Collect workspace-level diagnostics grouped by URI.
    const workspaceDiags = new Map<string, vscode.Diagnostic[]>();

    const getOrCreate = (uri: vscode.Uri): vscode.Diagnostic[] => {
      const key = uri.toString();
      if (!workspaceDiags.has(key)) {
        workspaceDiags.set(key, []);
      }
      return workspaceDiags.get(key)!;
    };

    // Rule 3 - Circular dependencies
    this._detectCircularDependencies(getOrCreate);

    // Rule 4 - Unused reactons
    this._detectUnusedReactons(getOrCreate);

    // Merge workspace diagnostics into existing per-file diagnostics (which
    // may already contain per-document diagnostics from analyzeDocument).
    for (const [uriStr, diags] of workspaceDiags) {
      const uri = vscode.Uri.parse(uriStr);
      const existing = this._diagnosticCollection.get(uri);

      // Keep per-document diagnostics; replace workspace-level ones.
      const perDoc = (existing ?? []).filter(
        (d) =>
          d.code !== DiagnosticCode.CircularDependency &&
          d.code !== DiagnosticCode.UnusedReacton
      );

      this._diagnosticCollection.set(uri, [...perDoc, ...diags]);
    }
  }

  dispose(): void {
    this._diagnosticCollection.dispose();
    for (const d of this._disposables) {
      d.dispose();
    }
  }

  // ---------------------------------------------------------------------------
  // Rule 1 - Missing `name` parameter
  // ---------------------------------------------------------------------------

  /**
   * Reacton declarations should include a `name:` argument for debuggability.
   * We flag any `reacton(`, `computed(`, `asyncReacton(`, `family(`,
   * `selector(`, `stateMachine(` or `createEffect(` that does not contain a
   * `name:` keyword in its body.
   */
  private _checkMissingName(
    line: string,
    lineNum: number,
    allLines: string[],
    fullText: string,
    diagnostics: vscode.Diagnostic[]
  ): void {
    const declarationPattern =
      /final\s+(\w+)\s*=\s*(reacton|computed|asyncReacton|family|selector|stateMachine|createEffect)(?:<[^>]*>)?\s*\(/;
    const match = declarationPattern.exec(line);
    if (!match) {
      return;
    }

    const name = match[1];
    const funcName = match[2];

    // Gather the full body of the call to look for `name:`.
    const body = this._extractCallBody(allLines, lineNum, fullText);
    if (!body.includes('name:')) {
      const col = match.index + match[0].indexOf(funcName);
      const range = new vscode.Range(lineNum, col, lineNum, col + funcName.length);

      const diag = new vscode.Diagnostic(
        range,
        `Reacton '${name}' is missing the 'name' parameter. Adding a name improves debugging and DevTools experience.`,
        vscode.DiagnosticSeverity.Warning
      );
      diag.code = DiagnosticCode.MissingName;
      diag.source = 'reacton';
      diagnostics.push(diag);
    }
  }

  // ---------------------------------------------------------------------------
  // Rule 2 - Reacton created inside build()
  // ---------------------------------------------------------------------------

  /**
   * Creating a new reacton inside a build method causes a new reacton to be
   * allocated on every rebuild, which is almost certainly a bug.
   */
  private _checkReactonInBuild(
    line: string,
    lineNum: number,
    buildRanges: BuildMethodRange[],
    diagnostics: vscode.Diagnostic[]
  ): void {
    if (!this._isInsideBuildMethod(lineNum, buildRanges)) {
      return;
    }

    const creationPattern =
      /(?:^|[=\s])(reacton|computed|asyncReacton)(?:<[^>]*>)?\s*\(/;
    const match = creationPattern.exec(line);
    if (!match) {
      return;
    }

    const funcName = match[1];
    const col = match.index + match[0].indexOf(funcName);
    const range = new vscode.Range(lineNum, col, lineNum, col + funcName.length);

    const diag = new vscode.Diagnostic(
      range,
      `'${funcName}()' should not be called inside a build() method. Reactons created here will be re-allocated on every rebuild. Declare reactons as top-level or class-level fields instead.`,
      vscode.DiagnosticSeverity.Error
    );
    diag.code = DiagnosticCode.ReactonInBuild;
    diag.source = 'reacton';
    diagnostics.push(diag);
  }

  // ---------------------------------------------------------------------------
  // Rule 3 - Circular dependencies
  // ---------------------------------------------------------------------------

  /**
   * Detects cycles in the reacton dependency graph using iterative DFS.
   * Reports an error on every reacton that participates in a cycle.
   */
  private _detectCircularDependencies(
    getOrCreate: (uri: vscode.Uri) => vscode.Diagnostic[]
  ): void {
    const allReactons = this.scanner.reactons;
    const nameSet = new Set(allReactons.map((r) => r.name));

    // Build adjacency list from the scanner data.
    const adj = new Map<string, string[]>();
    for (const r of allReactons) {
      adj.set(
        r.name,
        r.dependencies.filter((d) => nameSet.has(d))
      );
    }

    // Track every reacton that is part of at least one cycle.
    const inCycle = new Set<string>();

    // For each reacton, attempt to find a cycle that includes it.
    const visited = new Set<string>();
    const recStack = new Set<string>();

    const dfs = (node: string, path: string[]): void => {
      visited.add(node);
      recStack.add(node);
      path.push(node);

      for (const dep of adj.get(node) ?? []) {
        if (!visited.has(dep)) {
          dfs(dep, path);
        } else if (recStack.has(dep)) {
          // Found a cycle.  Mark all nodes from `dep` back to `dep` on the
          // current path.
          const cycleStart = path.indexOf(dep);
          if (cycleStart !== -1) {
            for (let i = cycleStart; i < path.length; i++) {
              inCycle.add(path[i]);
            }
          }
        }
      }

      path.pop();
      recStack.delete(node);
    };

    for (const r of allReactons) {
      if (!visited.has(r.name)) {
        dfs(r.name, []);
      }
    }

    // Emit a diagnostic for every reacton that participates in a cycle.
    for (const name of inCycle) {
      const reacton = this.scanner.getReacton(name);
      if (!reacton) {
        continue;
      }

      // Identify which of this reacton's dependencies are also in the cycle
      // so we can give a precise message.
      const cyclicDeps = reacton.dependencies.filter((d) => inCycle.has(d));
      const depsList = cyclicDeps.join(', ');

      const range = new vscode.Range(
        reacton.line,
        reacton.column,
        reacton.line,
        reacton.column + reacton.name.length
      );

      const diag = new vscode.Diagnostic(
        range,
        `Circular dependency detected: '${name}' and '${depsList}' depend on each other. This will cause infinite re-evaluation at runtime.`,
        vscode.DiagnosticSeverity.Error
      );
      diag.code = DiagnosticCode.CircularDependency;
      diag.source = 'reacton';

      getOrCreate(reacton.file).push(diag);
    }
  }

  // ---------------------------------------------------------------------------
  // Rule 4 - Unused reactons
  // ---------------------------------------------------------------------------

  /**
   * A reacton is considered "unused" when:
   * - No other reacton lists it as a dependency, AND
   * - No file in the workspace contains a `read(reactonName)` or
   *   `watch(reactonName)` or `context.watch(reactonName)` call referencing it
   *
   * Effects are excluded since they are side-effect-only by design.
   */
  private _detectUnusedReactons(
    getOrCreate: (uri: vscode.Uri) => vscode.Diagnostic[]
  ): void {
    const allReactons = this.scanner.reactons;

    // Collect the set of all reacton names that are referenced as a dependency
    // by at least one other reacton.
    const referenced = new Set<string>();
    for (const r of allReactons) {
      for (const dep of r.dependencies) {
        referenced.add(dep);
      }
      for (const sub of r.subscribers) {
        referenced.add(sub);
      }
    }

    // Additionally, scan open text documents for read()/watch() references
    // so that we do not flag reactons that are consumed in widget code.
    const readWatchPattern = /(?:read|watch|context\.watch|context\.read)\s*\(\s*(\w+)\s*\)/g;
    for (const doc of vscode.workspace.textDocuments) {
      if (doc.languageId !== 'dart') {
        continue;
      }
      const text = doc.getText();
      let m: RegExpExecArray | null;
      while ((m = readWatchPattern.exec(text)) !== null) {
        referenced.add(m[1]);
      }
    }

    for (const reacton of allReactons) {
      // Effects are side-effect-only and are not expected to be read.
      if (reacton.type === 'effect') {
        continue;
      }

      if (!referenced.has(reacton.name)) {
        const range = new vscode.Range(
          reacton.line,
          reacton.column,
          reacton.line,
          reacton.column + reacton.name.length
        );

        const diag = new vscode.Diagnostic(
          range,
          `Reacton '${reacton.name}' is declared but never referenced by another reacton, read(), or watch() call. Consider removing it if it is no longer needed.`,
          vscode.DiagnosticSeverity.Hint
        );
        diag.code = DiagnosticCode.UnusedReacton;
        diag.source = 'reacton';
        diag.tags = [vscode.DiagnosticTag.Unnecessary];

        getOrCreate(reacton.file).push(diag);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Rule 5 - Too many watchers in a single build method
  // ---------------------------------------------------------------------------

  /**
   * Having 3 or more `context.watch()` calls in a single build method is a
   * code smell. Each watcher triggers a rebuild independently, so the widget
   * will rebuild more often than necessary. Suggest extracting a `computed()`
   * that combines the watched values.
   */
  private _checkTooManyWatchers(
    lines: string[],
    buildRanges: BuildMethodRange[],
    diagnostics: vscode.Diagnostic[]
  ): void {
    for (const range of buildRanges) {
      const watchCalls: { line: number; col: number }[] = [];

      for (let i = range.startLine; i <= range.endLine && i < lines.length; i++) {
        const watchPattern = /context\.watch\s*\(/g;
        let m: RegExpExecArray | null;
        while ((m = watchPattern.exec(lines[i])) !== null) {
          watchCalls.push({ line: i, col: m.index });
        }
      }

      if (watchCalls.length >= MAX_WATCHERS_IN_BUILD) {
        // Place the diagnostic on the build method signature itself.
        const diag = new vscode.Diagnostic(
          new vscode.Range(range.startLine, 0, range.startLine, lines[range.startLine].length),
          `This build method contains ${watchCalls.length} context.watch() calls. ` +
            `Consider combining them into a single computed() reacton to reduce unnecessary rebuilds.`,
          vscode.DiagnosticSeverity.Information
        );
        diag.code = DiagnosticCode.TooManyWatchers;
        diag.source = 'reacton';

        diagnostics.push(diag);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /**
   * Re-analyze all currently open Dart documents.
   */
  private _analyzeOpenDocuments(): void {
    for (const doc of vscode.workspace.textDocuments) {
      if (doc.languageId === 'dart') {
        this.analyzeDocument(doc);
      }
    }
  }

  /**
   * Extract the full text of a function call starting at `startLine`,
   * tracking parentheses depth until the closing `)` is found.
   */
  private _extractCallBody(
    allLines: string[],
    startLine: number,
    _fullText: string
  ): string {
    const parts: string[] = [];
    let depth = 0;
    let started = false;

    for (let i = startLine; i < Math.min(startLine + 50, allLines.length); i++) {
      const line = allLines[i];
      parts.push(line);

      for (const ch of line) {
        if (ch === '(') {
          depth++;
          started = true;
        }
        if (ch === ')') {
          depth--;
        }
      }

      if (started && depth <= 0) {
        break;
      }
    }

    return parts.join('\n');
  }

  /**
   * Locate all `build()` method bodies in the given source lines.
   * Returns an array of line ranges (inclusive).
   *
   * We look for the standard Flutter/Dart patterns:
   *   Widget build(BuildContext context) {
   *   State<T> build(BuildContext context) {
   *   @override ... build(BuildContext context) {
   *
   * The opening brace may be on the same line or the next line.
   */
  private _findBuildMethodRanges(lines: string[]): BuildMethodRange[] {
    const ranges: BuildMethodRange[] = [];
    const buildSignature = /\bbuild\s*\(\s*BuildContext\b/;

    for (let i = 0; i < lines.length; i++) {
      if (!buildSignature.test(lines[i])) {
        continue;
      }

      // Find the opening brace (may be on the same line or the next).
      let braceLineIdx = -1;
      for (let j = i; j < Math.min(i + 3, lines.length); j++) {
        if (lines[j].includes('{')) {
          braceLineIdx = j;
          break;
        }
      }

      if (braceLineIdx === -1) {
        continue;
      }

      // Walk forward to find the matching closing brace.
      let depth = 0;
      let endLine = braceLineIdx;
      for (let j = braceLineIdx; j < lines.length; j++) {
        for (const ch of lines[j]) {
          if (ch === '{') {
            depth++;
          }
          if (ch === '}') {
            depth--;
          }
        }
        if (depth <= 0) {
          endLine = j;
          break;
        }
      }

      ranges.push({ startLine: i, endLine });
    }

    return ranges;
  }

  /**
   * Return true if `lineNum` falls within any known build() method body.
   */
  private _isInsideBuildMethod(
    lineNum: number,
    buildRanges: BuildMethodRange[]
  ): boolean {
    return buildRanges.some(
      (r) => lineNum > r.startLine && lineNum <= r.endLine
    );
  }
}

/** Represents the line range of a build() method body. */
interface BuildMethodRange {
  /** Line number of the build() signature. */
  startLine: number;
  /** Line number of the closing brace. */
  endLine: number;
}
