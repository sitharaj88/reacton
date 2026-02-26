import * as vscode from 'vscode';
import { ReactonScanner, ReactonInfo } from './reacton_scanner';

/**
 * Maps each reacton type to a display-friendly label and icon.
 */
const TYPE_META: Record<ReactonInfo['type'], { icon: string; label: string }> = {
  writable: { icon: '$(symbol-variable)', label: 'Writable Reacton' },
  computed: { icon: '$(symbol-function)', label: 'Computed Reacton' },
  async: { icon: '$(cloud)', label: 'Async Reacton' },
  family: { icon: '$(symbol-array)', label: 'Reacton Family' },
  selector: { icon: '$(filter)', label: 'Selector' },
  effect: { icon: '$(zap)', label: 'Effect' },
  stateMachine: { icon: '$(server-process)', label: 'State Machine' },
};

/**
 * Hover provider that shows rich information when the cursor
 * is over a Reacton declaration or reference in a Dart file.
 *
 * The hover tooltip includes the reacton type, value type,
 * doc comment, dependency/subscriber lists, file location,
 * and a command link to open the dependency graph.
 */
export class ReactonHoverProvider implements vscode.HoverProvider {
  constructor(private readonly scanner: ReactonScanner) {}

  provideHover(
    document: vscode.TextDocument,
    position: vscode.Position,
    _token: vscode.CancellationToken
  ): vscode.Hover | undefined {
    const wordRange = document.getWordRangeAtPosition(position, /[a-zA-Z_]\w*/);
    if (!wordRange) {
      return undefined;
    }

    const word = document.getText(wordRange);
    const reacton = this.scanner.getReacton(word);
    if (!reacton) {
      return undefined;
    }

    const markdown = this.buildHoverContent(reacton);
    return new vscode.Hover(markdown, wordRange);
  }

  /**
   * Builds a rich MarkdownString for the given reacton, including
   * type badge, value type, doc comment, dependencies, subscribers,
   * file location, and a "Show in Graph" action link.
   */
  private buildHoverContent(reacton: ReactonInfo): vscode.MarkdownString {
    const md = new vscode.MarkdownString();
    md.isTrusted = true;
    md.supportHtml = true;

    const meta = TYPE_META[reacton.type] ?? { icon: '$(circle)', label: reacton.type };

    // --- Header: icon, name, and type badge ---
    md.appendMarkdown(`${meta.icon} **${reacton.name}** \u2014 _${meta.label}_\n\n`);

    // --- Value type ---
    md.appendMarkdown(`**Type:** \`${reacton.valueType}\`\n\n`);

    // --- Doc comment ---
    if (reacton.docComment) {
      md.appendMarkdown('---\n\n');
      md.appendMarkdown(`${reacton.docComment}\n\n`);
    }

    // --- Dependencies ---
    const dependencies = this.scanner.getDependencies(reacton.name);
    if (dependencies.length > 0) {
      md.appendMarkdown('---\n\n');
      md.appendMarkdown(`**Dependencies** (${dependencies.length}):\n\n`);
      for (const dep of dependencies) {
        const depMeta = TYPE_META[dep.type] ?? { icon: '$(circle)', label: dep.type };
        md.appendMarkdown(`- \`${dep.name}\` ${depMeta.icon} _${depMeta.label}_ \u2014 \`${dep.valueType}\`\n`);
      }
      md.appendMarkdown('\n');
    }

    // --- Subscribers (dependents) ---
    const subscribers = this.scanner.getDependents(reacton.name);
    if (subscribers.length > 0) {
      md.appendMarkdown('---\n\n');
      md.appendMarkdown(`**Subscribers** (${subscribers.length}):\n\n`);
      for (const sub of subscribers) {
        const subMeta = TYPE_META[sub.type] ?? { icon: '$(circle)', label: sub.type };
        md.appendMarkdown(`- \`${sub.name}\` ${subMeta.icon} _${subMeta.label}_ \u2014 \`${sub.valueType}\`\n`);
      }
      md.appendMarkdown('\n');
    }

    // --- File location ---
    const relativePath = vscode.workspace.asRelativePath(reacton.file);
    const displayLine = reacton.line + 1;
    const fileUri = reacton.file.toString();
    md.appendMarkdown('---\n\n');
    md.appendMarkdown(
      `**Defined in:** [${relativePath}:${displayLine}](${fileUri}#L${displayLine})\n\n`
    );

    // --- "Show in Graph" command link ---
    const showGraphArgs = encodeURIComponent(JSON.stringify([]));
    md.appendMarkdown(
      `[$(graph) Show in Graph](command:reacton.showGraph?${showGraphArgs} "Open the Reacton dependency graph")\n`
    );

    return md;
  }
}
