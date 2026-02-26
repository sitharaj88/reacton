import * as vscode from 'vscode';
import { ReactonScanner, ReactonInfo } from './reacton_scanner';

/**
 * Code lens provider that shows metadata above reacton declarations:
 * - Reacton type (writable, computed, async, etc.)
 * - Number of dependencies and subscribers
 * - "Show in graph" action
 * - "Go to definition" for dependencies
 */
export class ReactonCodeLensProvider implements vscode.CodeLensProvider {
  private _onDidChangeCodeLenses = new vscode.EventEmitter<void>();
  readonly onDidChangeCodeLenses = this._onDidChangeCodeLenses.event;

  constructor(private scanner: ReactonScanner) {
    scanner.onDidChange(() => this._onDidChangeCodeLenses.fire());
  }

  provideCodeLenses(document: vscode.TextDocument): vscode.CodeLens[] {
    const lenses: vscode.CodeLens[] = [];
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

        lenses.push(
          new vscode.CodeLens(range, {
            title: `${typeLabel}${subscriberLabel}`,
            command: '',
          })
        );

        // Dependencies lens (for computed/async/selector/effect)
        if (reactonInfo.deps.length > 0) {
          lenses.push(
            new vscode.CodeLens(range, {
              title: `$(link) ${reactonInfo.deps.length} ${reactonInfo.deps.length === 1 ? 'dependency' : 'dependencies'}: ${reactonInfo.deps.join(', ')}`,
              command: '',
            })
          );
        }

        // Show in graph lens
        lenses.push(
          new vscode.CodeLens(range, {
            title: '$(graph) Show in Graph',
            command: 'reacton.showGraph',
          })
        );

        // Find references lens
        lenses.push(
          new vscode.CodeLens(range, {
            title: '$(references) Find References',
            command: 'reacton.findReferences',
            arguments: [reactonInfo.name],
          })
        );
      }
    }

    return lenses;
  }

  private detectReactonDeclaration(
    line: string,
    _lineNum: number,
  ): { name: string; type: string; deps: string[] } | null {
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

  private getTypeLabel(info: { name: string; type: string }): string {
    const icons: Record<string, string> = {
      reacton: '$(symbol-variable)',
      computed: '$(symbol-function)',
      async: '$(cloud)',
      family: '$(symbol-array)',
      selector: '$(filter)',
      effect: '$(zap)',
      stateMachine: '$(server-process)',
    };

    const labels: Record<string, string> = {
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
