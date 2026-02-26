import * as vscode from 'vscode';
import { ReactonScanner, ReactonInfo } from './reacton_scanner';

/**
 * Definition provider that enables "Go to Definition" for Reacton
 * declarations in Dart files.
 *
 * When the cursor is on a word that matches a known reacton name,
 * this provider returns the Location of the reacton's declaration,
 * allowing the user to jump directly to where it is defined.
 */
export class ReactonDefinitionProvider implements vscode.DefinitionProvider {
  constructor(private readonly scanner: ReactonScanner) {}

  provideDefinition(
    document: vscode.TextDocument,
    position: vscode.Position,
    _token: vscode.CancellationToken
  ): vscode.Definition | undefined {
    const wordRange = document.getWordRangeAtPosition(position, /[a-zA-Z_]\w*/);
    if (!wordRange) {
      return undefined;
    }

    const word = document.getText(wordRange);
    const reacton = this.scanner.getReacton(word);
    if (!reacton) {
      return undefined;
    }

    return new vscode.Location(
      reacton.file,
      new vscode.Position(reacton.line, reacton.column)
    );
  }
}

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
export class ReactonReferenceProvider implements vscode.ReferenceProvider {
  constructor(private readonly scanner: ReactonScanner) {}

  async provideReferences(
    document: vscode.TextDocument,
    position: vscode.Position,
    context: vscode.ReferenceContext,
    _token: vscode.CancellationToken
  ): Promise<vscode.Location[]> {
    const wordRange = document.getWordRangeAtPosition(position, /[a-zA-Z_]\w*/);
    if (!wordRange) {
      return [];
    }

    const word = document.getText(wordRange);
    const reacton = this.scanner.getReacton(word);
    if (!reacton) {
      return [];
    }

    const locations: vscode.Location[] = [];

    // Include the declaration location if requested
    if (context.includeDeclaration) {
      locations.push(
        new vscode.Location(
          reacton.file,
          new vscode.Position(reacton.line, reacton.column)
        )
      );
    }

    // Search all workspace Dart files for references to this reacton
    const dartFiles = await vscode.workspace.findFiles(
      '**/*.dart',
      '{**/.*,**/.dart_tool/**,**/build/**,**/generated/**}'
    );

    // Use a word-boundary pattern to avoid matching substrings.
    // Dart identifiers consist of word characters, so \b is appropriate.
    const pattern = new RegExp(`\\b${escapeRegExp(word)}\\b`, 'g');

    for (const fileUri of dartFiles) {
      const fileLocations = await this.findReferencesInFile(
        fileUri,
        reacton,
        pattern,
        context.includeDeclaration
      );
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
  private async findReferencesInFile(
    fileUri: vscode.Uri,
    reacton: ReactonInfo,
    pattern: RegExp,
    includeDeclaration: boolean
  ): Promise<vscode.Location[]> {
    const locations: vscode.Location[] = [];

    try {
      const content = await vscode.workspace.fs.readFile(fileUri);
      const text = Buffer.from(content).toString('utf8');
      const lines = text.split('\n');
      const isDeclarationFile = fileUri.toString() === reacton.file.toString();

      for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        const line = lines[lineIndex];

        // Reset the regex lastIndex for each line
        pattern.lastIndex = 0;
        let match: RegExpExecArray | null;

        while ((match = pattern.exec(line)) !== null) {
          // Skip the declaration site in the declaration file
          // (it was already added from scanner data if includeDeclaration is true)
          if (
            isDeclarationFile &&
            lineIndex === reacton.line &&
            match.index === reacton.column
          ) {
            continue;
          }

          locations.push(
            new vscode.Location(
              fileUri,
              new vscode.Position(lineIndex, match.index)
            )
          );
        }
      }
    } catch {
      // File might not be readable; skip silently
    }

    return locations;
  }
}

/**
 * Escapes special regex characters in a string so it can be used
 * safely inside a RegExp constructor.
 */
function escapeRegExp(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
