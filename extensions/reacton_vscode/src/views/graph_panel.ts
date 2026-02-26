import * as vscode from 'vscode';
import { ReactonScanner, ReactonInfo } from '../providers/reacton_scanner';

/**
 * Webview panel that displays an interactive dependency graph
 * of all reactons in the workspace.
 */
export class ReactonGraphPanel {
  public static currentPanel: ReactonGraphPanel | undefined;
  private static readonly viewType = 'reactonGraph';

  private readonly _panel: vscode.WebviewPanel;
  private _disposables: vscode.Disposable[] = [];

  public static createOrShow(
    extensionUri: vscode.Uri,
    scanner: ReactonScanner
  ): void {
    const column = vscode.window.activeTextEditor
      ? vscode.window.activeTextEditor.viewColumn
      : undefined;

    if (ReactonGraphPanel.currentPanel) {
      ReactonGraphPanel.currentPanel._panel.reveal(column);
      ReactonGraphPanel.currentPanel.update(scanner);
      return;
    }

    const panel = vscode.window.createWebviewPanel(
      ReactonGraphPanel.viewType,
      'Reacton Dependency Graph',
      column || vscode.ViewColumn.One,
      {
        enableScripts: true,
        retainContextWhenHidden: true,
      }
    );

    ReactonGraphPanel.currentPanel = new ReactonGraphPanel(panel, scanner);
  }

  private constructor(panel: vscode.WebviewPanel, scanner: ReactonScanner) {
    this._panel = panel;
    this.update(scanner);

    this._panel.onDidDispose(() => this.dispose(), null, this._disposables);

    // Handle messages from the webview
    this._panel.webview.onDidReceiveMessage(
      async (message) => {
        switch (message.command) {
          case 'navigateToReacton': {
            const reacton = scanner.getReacton(message.reactonName);
            if (reacton) {
              const doc = await vscode.workspace.openTextDocument(reacton.file);
              await vscode.window.showTextDocument(doc, {
                selection: new vscode.Range(reacton.line, 0, reacton.line, 0),
              });
            }
            break;
          }
        }
      },
      null,
      this._disposables
    );
  }

  public update(scanner: ReactonScanner): void {
    const graph = scanner.getGraph();
    this._panel.webview.html = this._getHtmlForWebview(graph.reactons, graph.edges);
  }

  public dispose(): void {
    ReactonGraphPanel.currentPanel = undefined;
    this._panel.dispose();
    while (this._disposables.length) {
      const d = this._disposables.pop();
      if (d) {
        d.dispose();
      }
    }
  }

  private _getHtmlForWebview(
    reactons: ReactonInfo[],
    edges: { from: string; to: string }[]
  ): string {
    const reactonsJson = JSON.stringify(
      reactons.map((a) => ({
        name: a.name,
        type: a.type,
        valueType: a.valueType,
        deps: a.dependencies,
      }))
    );
    const edgesJson = JSON.stringify(edges);

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reacton Dependency Graph</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: var(--vscode-editor-background);
      color: var(--vscode-editor-foreground);
      font-family: var(--vscode-font-family);
      overflow: hidden;
    }
    #toolbar {
      padding: 8px 16px;
      border-bottom: 1px solid var(--vscode-panel-border);
      display: flex;
      gap: 12px;
      align-items: center;
    }
    #toolbar label { font-size: 12px; }
    #toolbar select, #toolbar input {
      background: var(--vscode-input-background);
      color: var(--vscode-input-foreground);
      border: 1px solid var(--vscode-input-border);
      padding: 4px 8px;
      font-size: 12px;
    }
    #canvas { width: 100%; height: calc(100vh - 40px); }
    .legend {
      position: absolute;
      bottom: 16px;
      right: 16px;
      background: var(--vscode-editor-background);
      border: 1px solid var(--vscode-panel-border);
      padding: 8px 12px;
      font-size: 11px;
      border-radius: 4px;
    }
    .legend-item { display: flex; align-items: center; gap: 6px; margin: 4px 0; }
    .legend-color {
      width: 12px; height: 12px; border-radius: 50%;
    }
    #tooltip {
      position: absolute;
      display: none;
      background: var(--vscode-editorHoverWidget-background);
      border: 1px solid var(--vscode-editorHoverWidget-border);
      padding: 8px 12px;
      border-radius: 4px;
      font-size: 12px;
      pointer-events: none;
      z-index: 100;
      max-width: 300px;
    }
  </style>
</head>
<body>
  <div id="toolbar">
    <label>Filter:</label>
    <select id="typeFilter">
      <option value="all">All Types</option>
      <option value="writable">Reactons</option>
      <option value="computed">Computed</option>
      <option value="async">Async</option>
      <option value="family">Family</option>
      <option value="selector">Selector</option>
      <option value="effect">Effect</option>
      <option value="stateMachine">State Machine</option>
    </select>
    <input type="text" id="searchInput" placeholder="Search reactons..." />
  </div>
  <canvas id="canvas"></canvas>
  <div id="tooltip"></div>
  <div class="legend">
    <div class="legend-item"><div class="legend-color" style="background:#4fc3f7"></div> Reacton</div>
    <div class="legend-item"><div class="legend-color" style="background:#81c784"></div> Computed</div>
    <div class="legend-item"><div class="legend-color" style="background:#ffb74d"></div> Async</div>
    <div class="legend-item"><div class="legend-color" style="background:#ce93d8"></div> Family</div>
    <div class="legend-item"><div class="legend-color" style="background:#f06292"></div> Selector</div>
    <div class="legend-item"><div class="legend-color" style="background:#ef5350"></div> Effect</div>
    <div class="legend-item"><div class="legend-color" style="background:#7e57c2"></div> State Machine</div>
  </div>

  <script>
    const vscode = acquireVsCodeApi();
    const reactons = ${reactonsJson};
    const edges = ${edgesJson};

    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');
    const tooltip = document.getElementById('tooltip');
    const typeFilter = document.getElementById('typeFilter');
    const searchInput = document.getElementById('searchInput');

    const colors = {
      writable: '#4fc3f7',
      computed: '#81c784',
      async: '#ffb74d',
      family: '#ce93d8',
      selector: '#f06292',
      effect: '#ef5350',
      stateMachine: '#7e57c2',
    };

    // Node positions (computed via simple hierarchical layout)
    let nodes = [];
    let filteredNodes = [];
    let filteredEdges = [];
    let selectedNode = null;
    let hoveredNode = null;

    function resize() {
      canvas.width = canvas.clientWidth * window.devicePixelRatio;
      canvas.height = canvas.clientHeight * window.devicePixelRatio;
      ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
    }

    function layoutNodes() {
      // Group by level (writable=0, computed/selector=1, async=2)
      const levels = { writable: 0, computed: 1, selector: 1, async: 2, family: 0, effect: 3, stateMachine: 0 };

      const grouped = {};
      for (const reacton of filteredNodes) {
        const level = levels[reacton.type] ?? 0;
        if (!grouped[level]) grouped[level] = [];
        grouped[level].push(reacton);
      }

      const padding = 60;
      const width = canvas.clientWidth - padding * 2;
      const height = canvas.clientHeight - padding * 2;
      const levelCount = Object.keys(grouped).length;

      nodes = [];
      let levelIdx = 0;
      for (const level of Object.keys(grouped).sort()) {
        const items = grouped[level];
        const y = padding + (levelCount > 1 ? (levelIdx / (levelCount - 1)) * height : height / 2);
        for (let i = 0; i < items.length; i++) {
          const x = padding + (items.length > 1 ? (i / (items.length - 1)) * width : width / 2);
          nodes.push({ ...items[i], x, y, radius: 24 });
        }
        levelIdx++;
      }
    }

    function filterGraph() {
      const type = typeFilter.value;
      const search = searchInput.value.toLowerCase();

      filteredNodes = reactons.filter(a => {
        if (type !== 'all' && a.type !== type) return false;
        if (search && !a.name.toLowerCase().includes(search)) return false;
        return true;
      });

      const nodeNames = new Set(filteredNodes.map(n => n.name));
      filteredEdges = edges.filter(e => nodeNames.has(e.from) && nodeNames.has(e.to));

      layoutNodes();
      draw();
    }

    function draw() {
      ctx.clearRect(0, 0, canvas.clientWidth, canvas.clientHeight);

      // Draw edges
      for (const edge of filteredEdges) {
        const from = nodes.find(n => n.name === edge.from);
        const to = nodes.find(n => n.name === edge.to);
        if (!from || !to) continue;

        ctx.beginPath();
        ctx.moveTo(from.x, from.y);
        ctx.lineTo(to.x, to.y);
        ctx.strokeStyle = 'rgba(150, 150, 150, 0.4)';
        ctx.lineWidth = 1.5;
        ctx.stroke();

        // Arrowhead
        const angle = Math.atan2(to.y - from.y, to.x - from.x);
        const arrowLen = 10;
        const tx = to.x - Math.cos(angle) * to.radius;
        const ty = to.y - Math.sin(angle) * to.radius;
        ctx.beginPath();
        ctx.moveTo(tx, ty);
        ctx.lineTo(tx - arrowLen * Math.cos(angle - 0.3), ty - arrowLen * Math.sin(angle - 0.3));
        ctx.lineTo(tx - arrowLen * Math.cos(angle + 0.3), ty - arrowLen * Math.sin(angle + 0.3));
        ctx.closePath();
        ctx.fillStyle = 'rgba(150, 150, 150, 0.6)';
        ctx.fill();
      }

      // Draw nodes
      for (const node of nodes) {
        const isSelected = selectedNode === node.name;
        const isHovered = hoveredNode === node.name;
        const color = colors[node.type] || '#888';

        // Node circle
        ctx.beginPath();
        ctx.arc(node.x, node.y, node.radius, 0, Math.PI * 2);
        ctx.fillStyle = isSelected ? color : isHovered ? color + 'cc' : color + '88';
        ctx.fill();
        if (isSelected || isHovered) {
          ctx.strokeStyle = color;
          ctx.lineWidth = 2;
          ctx.stroke();
        }

        // Label
        ctx.fillStyle = 'var(--vscode-editor-foreground, #ccc)';
        ctx.font = '11px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(node.name, node.x, node.y + node.radius + 14);
      }
    }

    function getNodeAt(x, y) {
      for (const node of nodes) {
        const dx = x - node.x;
        const dy = y - node.y;
        if (dx * dx + dy * dy <= node.radius * node.radius) {
          return node;
        }
      }
      return null;
    }

    canvas.addEventListener('mousemove', (e) => {
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const node = getNodeAt(x, y);

      hoveredNode = node ? node.name : null;
      canvas.style.cursor = node ? 'pointer' : 'default';

      if (node) {
        tooltip.style.display = 'block';
        tooltip.style.left = (e.clientX + 12) + 'px';
        tooltip.style.top = (e.clientY + 12) + 'px';
        tooltip.innerHTML = '<strong>' + node.name + '</strong><br>' +
          'Type: ' + node.type + '<br>' +
          'Value: <code>' + node.valueType + '</code>' +
          (node.deps.length > 0 ? '<br>Deps: ' + node.deps.join(', ') : '');
      } else {
        tooltip.style.display = 'none';
      }

      draw();
    });

    canvas.addEventListener('click', (e) => {
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const node = getNodeAt(x, y);

      if (node) {
        selectedNode = node.name;
        draw();
      } else {
        selectedNode = null;
        draw();
      }
    });

    canvas.addEventListener('dblclick', (e) => {
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const node = getNodeAt(x, y);

      if (node) {
        vscode.postMessage({ command: 'navigateToReacton', reactonName: node.name });
      }
    });

    typeFilter.addEventListener('change', filterGraph);
    searchInput.addEventListener('input', filterGraph);
    window.addEventListener('resize', () => { resize(); layoutNodes(); draw(); });

    resize();
    filterGraph();
  </script>
</body>
</html>`;
  }
}
