import * as vscode from 'vscode';
import { ReactonProvider } from './providers/reacton_provider';
import { ReactonCodeLensProvider } from './providers/codelens_provider';
import { ReactonHoverProvider } from './providers/hover_provider';
import { ReactonDocumentSymbolProvider } from './providers/symbol_provider';
import { ReactonDiagnosticsProvider } from './providers/diagnostics_provider';
import { ReactonStatusBar } from './providers/statusbar_provider';
import { ReactonDefinitionProvider, ReactonReferenceProvider } from './providers/definition_provider';
import { ReactonGraphPanel } from './views/graph_panel';
import { ReactonScanner } from './providers/reacton_scanner';

const DART_SELECTOR: vscode.DocumentSelector = { language: 'dart', scheme: 'file' };
let reactonScanner: ReactonScanner;

export function activate(context: vscode.ExtensionContext) {
  console.log('Reacton extension activated');

  // Initialize reacton scanner
  reactonScanner = new ReactonScanner();

  // Check if this is a Reacton project
  checkReactonProject().then((isActive) => {
    vscode.commands.executeCommand('setContext', 'reacton.isActive', isActive);
  });

  const config = vscode.workspace.getConfiguration('reacton');

  // --- Tree View ---
  const reactonProvider = new ReactonProvider(reactonScanner);
  vscode.window.registerTreeDataProvider('reactonExplorer', reactonProvider);

  // --- Code Lens ---
  if (config.get('showCodeLens', true)) {
    context.subscriptions.push(
      vscode.languages.registerCodeLensProvider(DART_SELECTOR, new ReactonCodeLensProvider(reactonScanner))
    );
  }

  // --- Hover Provider ---
  context.subscriptions.push(
    vscode.languages.registerHoverProvider(DART_SELECTOR, new ReactonHoverProvider(reactonScanner))
  );

  // --- Document Symbol Provider ---
  context.subscriptions.push(
    vscode.languages.registerDocumentSymbolProvider(DART_SELECTOR, new ReactonDocumentSymbolProvider(reactonScanner))
  );

  // --- Definition Provider (Go to Definition) ---
  context.subscriptions.push(
    vscode.languages.registerDefinitionProvider(DART_SELECTOR, new ReactonDefinitionProvider(reactonScanner))
  );

  // --- Reference Provider (Find All References) ---
  context.subscriptions.push(
    vscode.languages.registerReferenceProvider(DART_SELECTOR, new ReactonReferenceProvider(reactonScanner))
  );

  // --- Diagnostics ---
  if (config.get('showDiagnostics', true)) {
    const diagnosticsProvider = new ReactonDiagnosticsProvider(reactonScanner);
    context.subscriptions.push(diagnosticsProvider);
  }

  // --- Status Bar ---
  if (config.get('showStatusBar', true)) {
    const statusBar = new ReactonStatusBar(reactonScanner);
    context.subscriptions.push(statusBar);
  }

  // --- Commands ---
  context.subscriptions.push(
    vscode.commands.registerCommand('reacton.showGraph', () => {
      ReactonGraphPanel.createOrShow(context.extensionUri, reactonScanner);
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('reacton.refreshGraph', () => {
      reactonScanner.scan();
      reactonProvider.refresh();
      if (ReactonGraphPanel.currentPanel) {
        ReactonGraphPanel.currentPanel.update(reactonScanner);
      }
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('reacton.wrapWithReactonBuilder', () => {
      wrapSelection('ReactonBuilder', 'ReactonBuilder<Type>(\n  reacton: reactonName,\n  builder: (context, value) {\n    return SELECTION;\n  },\n)');
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('reacton.wrapWithReactonConsumer', () => {
      wrapSelection('ReactonConsumer', 'ReactonConsumer(\n  builder: (context, ref) {\n    return SELECTION;\n  },\n)');
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('reacton.wrapWithReactonScope', () => {
      wrapSelection('ReactonScope', 'ReactonScope(\n  store: ReactonStore(),\n  child: SELECTION,\n)');
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('reacton.findReferences', async (reactonName: string) => {
      const reacton = reactonScanner.getReacton(reactonName);
      if (reacton) {
        const doc = await vscode.workspace.openTextDocument(reacton.file);
        const editor = await vscode.window.showTextDocument(doc);
        const pos = new vscode.Position(reacton.line, reacton.column);
        editor.selection = new vscode.Selection(pos, pos);
        await vscode.commands.executeCommand('editor.action.findReferences', reacton.file, pos);
      }
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('reacton.goToReacton', async () => {
      const reactons = reactonScanner.reactons;
      if (reactons.length === 0) {
        vscode.window.showInformationMessage('No Reacton declarations found in workspace.');
        return;
      }

      const items = reactons.map((r) => ({
        label: `$(${getIcon(r.type)}) ${r.name}`,
        description: r.valueType,
        detail: `${r.type} — ${vscode.workspace.asRelativePath(r.file)}:${r.line + 1}`,
        reacton: r,
      }));

      const selected = await vscode.window.showQuickPick(items, {
        placeHolder: 'Select a Reacton to navigate to...',
        matchOnDescription: true,
        matchOnDetail: true,
      });

      if (selected) {
        const doc = await vscode.workspace.openTextDocument(selected.reacton.file);
        await vscode.window.showTextDocument(doc, {
          selection: new vscode.Range(selected.reacton.line, 0, selected.reacton.line, 0),
        });
      }
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('reacton.showDependencyChain', async () => {
      const reactons = reactonScanner.reactons;
      if (reactons.length === 0) {
        vscode.window.showInformationMessage('No Reacton declarations found in workspace.');
        return;
      }

      const items = reactons.map((r) => ({
        label: r.name,
        description: r.type,
        reacton: r,
      }));

      const selected = await vscode.window.showQuickPick(items, {
        placeHolder: 'Select a Reacton to trace dependencies...',
      });

      if (selected) {
        const chain = buildDependencyChain(selected.reacton.name, reactonScanner);
        const panel = vscode.window.createOutputChannel('Reacton Dependencies');
        panel.clear();
        panel.appendLine(`Dependency chain for: ${selected.reacton.name}`);
        panel.appendLine('='.repeat(50));
        panel.appendLine('');
        panel.appendLine(chain);
        panel.show();
      }
    })
  );

  // --- Auto-refresh on save ---
  if (config.get('autoRefreshGraph', true)) {
    context.subscriptions.push(
      vscode.workspace.onDidSaveTextDocument((doc) => {
        if (doc.languageId === 'dart') {
          reactonScanner.scanFile(doc.uri);
          reactonProvider.refresh();
        }
      })
    );
  }

  // --- Watch for configuration changes ---
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('reacton')) {
        vscode.window.showInformationMessage('Reacton: Configuration changed. Reload window to apply.');
      }
    })
  );

  // Initial scan
  reactonScanner.scan();
}

export function deactivate() {
  // Clean up
}

async function checkReactonProject(): Promise<boolean> {
  const pubspecFiles = await vscode.workspace.findFiles('pubspec.yaml', null, 1);
  if (pubspecFiles.length === 0) {
    return false;
  }

  try {
    const content = await vscode.workspace.fs.readFile(pubspecFiles[0]);
    const text = Buffer.from(content).toString('utf8');
    return text.includes('reacton:') || text.includes('flutter_reacton:');
  } catch {
    return false;
  }
}

async function wrapSelection(name: string, template: string): Promise<void> {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showWarningMessage('No active editor');
    return;
  }

  const selection = editor.selection;
  if (selection.isEmpty) {
    vscode.window.showWarningMessage(`Select a widget to wrap with ${name}`);
    return;
  }

  const selectedText = editor.document.getText(selection);
  const indentation = editor.document.lineAt(selection.start.line).text.match(/^\s*/)?.[0] ?? '';
  const indent = '  ';

  const wrapped = template
    .replace('SELECTION', selectedText)
    .split('\n')
    .map((line, i) => (i === 0 ? indentation + line : indentation + indent + line))
    .join('\n');

  await editor.edit((editBuilder) => {
    editBuilder.replace(selection, wrapped);
  });
}

function getIcon(type: string): string {
  const icons: Record<string, string> = {
    writable: 'symbol-variable',
    computed: 'symbol-function',
    async: 'cloud',
    family: 'symbol-array',
    selector: 'filter',
    effect: 'zap',
    stateMachine: 'server-process',
  };
  return icons[type] ?? 'circle';
}

function buildDependencyChain(name: string, scanner: ReactonScanner, indent = '', visited = new Set<string>()): string {
  if (visited.has(name)) {
    return `${indent}${name} (circular ref)`;
  }
  visited.add(name);

  const reacton = scanner.getReacton(name);
  if (!reacton) {
    return `${indent}${name} (unknown)`;
  }

  const lines = [`${indent}${reacton.name} [${reacton.type}] <${reacton.valueType}>`];

  const deps = scanner.getDependencies(name);
  for (let i = 0; i < deps.length; i++) {
    const isLast = i === deps.length - 1;
    const prefix = isLast ? '└── ' : '├── ';
    const childIndent = isLast ? '    ' : '│   ';
    const childChain = buildDependencyChain(deps[i].name, scanner, indent + childIndent, new Set(visited));
    lines.push(`${indent}${prefix}${childChain.trimStart()}`);
  }

  const subs = scanner.getDependents(name);
  if (subs.length > 0) {
    lines.push(`${indent}  Subscribers: ${subs.map(s => s.name).join(', ')}`);
  }

  return lines.join('\n');
}
