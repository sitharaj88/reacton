import * as vscode from 'vscode';
import { ReactonScanner, ReactonInfo } from './reacton_scanner';

/**
 * Tree data provider for the Reacton explorer sidebar view.
 * Groups reactons by type (writable, computed, async, family, selector, effect, stateMachine).
 * Shows dependency info, value types, and click-to-navigate.
 */
export class ReactonProvider implements vscode.TreeDataProvider<ReactonTreeItem> {
  private _onDidChangeTreeData = new vscode.EventEmitter<ReactonTreeItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

  constructor(private scanner: ReactonScanner) {
    scanner.onDidChange(() => this._onDidChangeTreeData.fire(undefined));
  }

  refresh(): void {
    this._onDidChangeTreeData.fire(undefined);
  }

  getTreeItem(element: ReactonTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: ReactonTreeItem): ReactonTreeItem[] {
    if (!element) {
      return this.getGroupItems();
    }

    if (element.contextValue === 'group') {
      return this.getReactonItems(element.reactonType!);
    }

    if (element.contextValue === 'reacton' && element.reactonName) {
      return this.getDependencyItems(element.reactonName);
    }

    return [];
  }

  private getGroupItems(): ReactonTreeItem[] {
    const reactons = this.scanner.reactons;
    const groups: { type: ReactonInfo['type']; label: string; icon: string }[] = [
      { type: 'writable', label: 'Reactons', icon: 'symbol-variable' },
      { type: 'computed', label: 'Computed', icon: 'symbol-function' },
      { type: 'async', label: 'Async', icon: 'cloud' },
      { type: 'family', label: 'Families', icon: 'symbol-array' },
      { type: 'selector', label: 'Selectors', icon: 'filter' },
      { type: 'effect', label: 'Effects', icon: 'zap' },
      { type: 'stateMachine', label: 'State Machines', icon: 'server-process' },
    ];

    return groups
      .filter((g) => reactons.some((a) => a.type === g.type))
      .map((g) => {
        const count = reactons.filter((a) => a.type === g.type).length;
        const item = new ReactonTreeItem(
          `${g.label} (${count})`,
          vscode.TreeItemCollapsibleState.Expanded
        );
        item.contextValue = 'group';
        item.reactonType = g.type;
        item.iconPath = new vscode.ThemeIcon(g.icon);
        return item;
      });
  }

  private getReactonItems(type: ReactonInfo['type']): ReactonTreeItem[] {
    return this.scanner.reactons
      .filter((a) => a.type === type)
      .sort((a, b) => a.name.localeCompare(b.name))
      .map((reacton) => {
        const hasDeps = reacton.dependencies.length > 0;
        const item = new ReactonTreeItem(
          reacton.name,
          hasDeps
            ? vscode.TreeItemCollapsibleState.Collapsed
            : vscode.TreeItemCollapsibleState.None
        );
        item.contextValue = 'reacton';
        item.reactonName = reacton.name;
        item.description = reacton.valueType;

        // Build rich tooltip
        const depsList = reacton.dependencies.length > 0
          ? `\n\n**Dependencies:**\n${reacton.dependencies.map((d) => `- \`${d}\``).join('\n')}`
          : '';
        const subscribersList = reacton.subscribers.length > 0
          ? `\n\n**Subscribers:**\n${reacton.subscribers.map((s) => `- \`${s}\``).join('\n')}`
          : '';
        const doc = reacton.docComment
          ? `\n\n---\n\n${reacton.docComment}`
          : '';

        item.tooltip = new vscode.MarkdownString(
          `**${reacton.name}** \`${reacton.type}\`\n\n` +
            `Type: \`${reacton.valueType}\`\n\n` +
            `File: ${vscode.workspace.asRelativePath(reacton.file)}:${reacton.line + 1}` +
            depsList +
            subscribersList +
            doc
        );

        item.command = {
          command: 'vscode.open',
          title: 'Go to Reacton',
          arguments: [
            reacton.file,
            { selection: new vscode.Range(reacton.line, 0, reacton.line, 0) },
          ],
        };

        // Icon based on type
        const icons: Record<ReactonInfo['type'], string> = {
          writable: 'symbol-variable',
          computed: 'symbol-function',
          async: 'cloud',
          family: 'symbol-array',
          selector: 'filter',
          effect: 'zap',
          stateMachine: 'server-process',
        };
        item.iconPath = new vscode.ThemeIcon(icons[reacton.type]);

        return item;
      });
  }

  private getDependencyItems(reactonName: string): ReactonTreeItem[] {
    const reacton = this.scanner.getReacton(reactonName);
    if (!reacton || reacton.dependencies.length === 0) {
      return [];
    }

    return reacton.dependencies.map((depName) => {
      const dep = this.scanner.getReacton(depName);
      const item = new ReactonTreeItem(
        depName,
        vscode.TreeItemCollapsibleState.None
      );
      item.contextValue = 'dependency';
      item.description = dep ? `${dep.type} (${dep.valueType})` : 'unknown';
      item.iconPath = new vscode.ThemeIcon('arrow-right');

      if (dep) {
        item.command = {
          command: 'vscode.open',
          title: 'Go to Dependency',
          arguments: [
            dep.file,
            { selection: new vscode.Range(dep.line, 0, dep.line, 0) },
          ],
        };
      }

      return item;
    });
  }
}

class ReactonTreeItem extends vscode.TreeItem {
  reactonType?: ReactonInfo['type'];
  reactonName?: string;
}
