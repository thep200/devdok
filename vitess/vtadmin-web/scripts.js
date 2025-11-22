// VTAdmin Dashboard - Enhanced JavaScript
// API Configuration
const API_BASE = 'http://localhost:14200/api';

// Global state
let globalState = {
    clusters: [],
    keyspaces: [],
    tablets: [],
    schemas: [],
    currentTab: 'clusters',
    refreshInterval: null
};

// Tablet type mapping
const TABLET_TYPE_MAP = {
    0: 'UNKNOWN',
    1: 'PRIMARY',
    2: 'REPLICA',
    3: 'RDONLY',
    4: 'BATCH',
    5: 'SPARE',
    6: 'EXPERIMENTAL',
    7: 'BACKUP',
    8: 'RESTORE',
    9: 'DRAINED'
};

// ===================================
// API Functions
// ===================================

async function fetchAPI(endpoint) {
    try {
        const response = await fetch(`${API_BASE}${endpoint}`);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        const data = await response.json();
        return data.result || data;
    } catch (error) {
        console.error(`Error fetching ${endpoint}:`, error);
        throw error;
    }
}

// ===================================
// URL Management for Tab State
// ===================================

function getTabFromURL() {
    const params = new URLSearchParams(window.location.search);
    return params.get('tab') || 'clusters';
}

function updateURL(tab, extraParams = {}) {
    const params = new URLSearchParams();
    params.set('tab', tab);

    // Add any extra parameters
    Object.entries(extraParams).forEach(([key, value]) => {
        if (value) params.set(key, value);
    });

    const newURL = `${window.location.pathname}?${params.toString()}`;
    window.history.pushState({ tab, ...extraParams }, '', newURL);
}

function handlePopState(event) {
    if (event.state && event.state.tab) {
        showTab(event.state.tab, false);
    }
}

// ===================================
// Tab Management
// ===================================

function showTab(tabName, updateHistory = true) {
    // Update global state
    globalState.currentTab = tabName;

    // Update URL if needed
    if (updateHistory) {
        updateURL(tabName);
    }

    // Update tab buttons
    document.querySelectorAll('.tab').forEach(tab => {
        tab.classList.remove('active');
        if (tab.dataset.tab === tabName) {
            tab.classList.add('active');
        }
    });

    // Update content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });

    const targetContent = document.getElementById(tabName);
    if (targetContent) {
        targetContent.classList.add('active');
    }

    // Load data for the tab
    loadTabData(tabName);
}

function loadTabData(tabName) {
    switch(tabName) {
        case 'clusters':
            loadClusters();
            break;
        case 'keyspaces':
            loadKeyspaces();
            break;
        case 'tablets':
            loadTablets();
            break;
        case 'schemas':
            loadSchemas();
            break;
        case 'vschema':
            loadVSchemaTab();
            break;
    }
}

// ===================================
// Clusters View
// ===================================

async function loadClusters() {
    const container = document.getElementById('clusters');

    try {
        showLoading(container, 'Loading cluster information...');

        const data = await fetchAPI('/clusters');
        globalState.clusters = data.clusters || [];

        if (globalState.clusters.length === 0) {
            container.innerHTML = renderEmptyState('No clusters found', 'No Vitess clusters are currently configured.');
            return;
        }

        let html = '<h2>Cluster Overview</h2>';

        // Cluster cards
        html += '<div class="info-grid">';
        for (const cluster of globalState.clusters) {
            html += renderClusterCard(cluster);
        }
        html += '</div>';

        // Detailed cluster information
        html += '<div class="detail-section">';
        html += '<h3>Cluster Details</h3>';
        for (const cluster of globalState.clusters) {
            html += await renderClusterDetails(cluster);
        }
        html += '</div>';

        container.innerHTML = html;
    } catch (error) {
        container.innerHTML = renderError('Failed to load clusters', error.message);
    }
}

function renderClusterCard(cluster) {
    return `
        <div class="card">
            <div class="card-header">
                <h3>${cluster.name}</h3>
            </div>
            <div class="info-item">
                <div class="info-label">Cluster ID</div>
                <div class="info-value">${cluster.id}</div>
            </div>
        </div>
    `;
}

async function renderClusterDetails(cluster) {
    try {
        // Fetch related data
        const keyspacesData = await fetchAPI('/keyspaces');
        const tabletsData = await fetchAPI('/tablets');

        const clusterKeyspaces = keyspacesData.keyspaces?.filter(ks => ks.cluster.id === cluster.id) || [];
        const clusterTablets = tabletsData.tablets?.filter(t => t.cluster.id === cluster.id) || [];

        return `
            <div class="card">
                <h3>${cluster.name} - Details</h3>

                ${clusterKeyspaces.length > 0 ? `
                    <div class="card-section">
                        <h4>Keyspaces</h4>
                        <div class="info-grid">
                            ${clusterKeyspaces.map(ks => `
                                <div class="info-item">
                                    <div class="info-label">${ks.keyspace.name}</div>
                                    <div class="info-value">${Object.keys(ks.shards || {}).length} shard(s)</div>
                                    <div style="margin-top: 8px;">
                                        ${Object.keys(ks.shards || {}).map(shard =>
                                            `<span class="badge badge-info">${shard}</span>`
                                        ).join('')}
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                ` : ''}
            </div>
        `;
    } catch (error) {
        return `<div class="error">Failed to load cluster details: ${error.message}</div>`;
    }
}

// ===================================
// Keyspaces View
// ===================================

async function loadKeyspaces() {
    const container = document.getElementById('keyspaces');

    try {
        showLoading(container, 'Loading keyspaces...');

        const data = await fetchAPI('/keyspaces');
        globalState.keyspaces = data.keyspaces || [];

        // Update keyspace select in VSchema tab
        updateKeyspaceSelect();

        if (globalState.keyspaces.length === 0) {
            container.innerHTML = renderEmptyState('No keyspaces found', 'No keyspaces are currently configured in the cluster.');
            return;
        }

        let html = '<h2>Keyspaces</h2>';

        // Keyspace cards
        for (const ks of globalState.keyspaces) {
            html += await renderKeyspaceCard(ks);
        }

        container.innerHTML = html;
    } catch (error) {
        container.innerHTML = renderError('Failed to load keyspaces', error.message);
    }
}

async function renderKeyspaceCard(ks) {
    const shards = Object.keys(ks.shards || {});

    let html = `
        <div class="card">
            <div class="card-header">
                <h3>${ks.keyspace.name}</h3>
                <div>
                    <span class="badge badge-primary">${ks.cluster.name}</span>
                    <span class="badge badge-success">${shards.length} shard(s)</span>
                </div>
            </div>

            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Keyspace Type</div>
                    <div class="info-value">${shards.length > 1 ? 'Sharded' : 'Unsharded'}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Shards</div>
                    <div class="info-value">${shards.join(', ') || 'None'}</div>
                </div>
            </div>
    `;

    // Shard details
    if (shards.length > 0) {
        html += '<div class="card-section"><h4>Shard Details</h4>';

        for (const shardName of shards) {
            const shard = ks.shards[shardName];
            html += `
                <div class="info-item" style="margin-bottom: 10px;">
                    <div class="info-label">Shard ${shardName}</div>
                    <div style="margin-top: 8px;">
                        ${shard.shard.is_primary_serving ?
                            '<span class="badge badge-success">Primary Serving</span>' :
                            '<span class="badge badge-warning">Not Primary Serving</span>'}
                        ${shard.shard.key_range ?
                            `<span class="badge badge-info">Range: ${shard.shard.key_range.start || '0'}-${shard.shard.key_range.end || 'max'}</span>` :
                            ''}
                    </div>
                </div>
            `;
        }

        html += '</div>';
    }

    html += '</div>';
    return html;
}

// ===================================
// Tablets View
// ===================================

async function loadTablets() {
    const container = document.getElementById('tablets');

    try {
        showLoading(container, 'Loading tablets...');

        const data = await fetchAPI('/tablets');
        globalState.tablets = data.tablets || [];

        if (globalState.tablets.length === 0) {
            container.innerHTML = renderEmptyState('No tablets found', 'No tablets are currently running in the cluster.');
            return;
        }

        let html = '<h2>Tablets</h2>';

        // Group tablets by keyspace
        const tabletsByKeyspace = {};
        globalState.tablets.forEach(t => {
            const keyspace = t.tablet.keyspace;
            if (!tabletsByKeyspace[keyspace]) {
                tabletsByKeyspace[keyspace] = [];
            }
            tabletsByKeyspace[keyspace].push(t);
        });

        // Render tablets by keyspace
        for (const [keyspace, tablets] of Object.entries(tabletsByKeyspace)) {
            html += renderTabletsTable(keyspace, tablets);
        }

        container.innerHTML = html;
    } catch (error) {
        container.innerHTML = renderError('Failed to load tablets', error.message);
    }
}

function renderTabletsTable(keyspace, tablets) {
    let html = `
        <div class="card">
            <div class="card-header">
                <h3>${keyspace}</h3>
                <div>
                    <span class="badge badge-primary">${tablets.length} tablet(s)</span>
                </div>
            </div>
            <div class="table-container">
                <table class="table">
                    <thead>
                        <tr>
                            <th>Alias</th>
                            <th>Shard</th>
                            <th>Type</th>
                            <th>State</th>
                            <th>Hostname</th>
                            <th>Port</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
    `;

    tablets.forEach(t => {
        const alias = `${t.tablet.alias.cell}-${String(t.tablet.alias.uid).padStart(10, '0')}`;
        const type = TABLET_TYPE_MAP[t.tablet.type] || t.tablet.type;
        const typeClass = type === 'PRIMARY' ? 'badge-primary' : type === 'REPLICA' ? 'badge-replica' : 'badge-info';
        const state = t.state === 1 ? 'SERVING' : 'NOT_SERVING';
        const stateClass = t.state === 1 ? 'badge-success' : 'badge-warning';
        const statusIndicator = t.state === 1 ? 'serving' : 'not-serving';

        html += `
            <tr>
                <td>
                    <strong>${alias}</strong>
                </td>
                <td>${t.tablet.shard}</td>
                <td><span class="badge ${typeClass}">${type}</span></td>
                <td>
                    <span class="status-indicator ${statusIndicator}"></span>
                    <span class="badge ${stateClass}">${state}</span>
                </td>
                <td>${t.tablet.hostname}</td>
                <td>${t.tablet.port_map?.vt || 'N/A'}</td>
                <td>
                    ${t.tablet.port_map?.vt ?
                        `<a href="http://${t.tablet.hostname}:${t.tablet.port_map.vt}/debug/status" target="_blank" class="btn btn-small btn-secondary">View</a>` :
                        ''}
                </td>
            </tr>
        `;
    });

    html += `
                    </tbody>
                </table>
            </div>
        </div>
    `;

    return html;
}

// ===================================
// Schemas View
// ===================================

async function loadSchemas() {
    const container = document.getElementById('schemas');

    try {
        showLoading(container, 'Loading schemas...');

        const data = await fetchAPI('/schemas');
        globalState.schemas = data.schemas || [];

        if (globalState.schemas.length === 0) {
            container.innerHTML = renderEmptyState('No schemas found', 'Schema information is not available or no tables are defined.');
            return;
        }

        let html = '<h2>Schemas</h2>';

        for (const schema of globalState.schemas) {
            html += renderSchemaCard(schema);
        }

        container.innerHTML = html;
    } catch (error) {
        container.innerHTML = renderError('Failed to load schemas', error.message);
    }
}

function renderSchemaCard(schema) {
    const tables = schema.table_definitions || [];

    let html = `
        <div class="card">
            <div class="card-header">
                <h3>${schema.keyspace}</h3>
                <div>
                    <span class="badge badge-primary">${schema.cluster.name}</span>
                    <span class="badge badge-success">${tables.length} table(s)</span>
                </div>
            </div>
    `;

    if (tables.length > 0) {
        html += '<div class="table-container"><table class="table">';
        html += '<thead><tr><th>Table Name</th><th>Columns</th><th>Schema</th></tr></thead>';
        html += '<tbody>';

        tables.forEach(table => {
            const columnCount = (table.schema?.match(/`\w+`/g) || []).length;
            html += `
                <tr>
                    <td><strong>${table.name}</strong></td>
                    <td>${columnCount} columns</td>
                    <td>
                        <details>
                            <summary style="cursor: pointer; color: #3498db;">View Schema</summary>
                            <pre style="margin-top: 10px; font-size: 12px;">${escapeHtml(table.schema || 'No schema available')}</pre>
                        </details>
                    </td>
                </tr>
            `;
        });

        html += '</tbody></table></div>';
    }

    html += '</div>';
    return html;
}

// ===================================
// VSchema View
// ===================================

async function loadVSchemaTab() {
    // Just update the select if keyspaces are loaded
    if (globalState.keyspaces.length > 0) {
        updateKeyspaceSelect();
        // Auto-load first keyspace
        if (globalState.keyspaces.length > 0) {
            const firstKs = globalState.keyspaces[0];
            document.getElementById('keyspaceSelect').value = `${firstKs.cluster.id}/${firstKs.keyspace.name}`;
            loadVSchema();
        }
    } else {
        // Load keyspaces first
        try {
            const data = await fetchAPI('/keyspaces');
            globalState.keyspaces = data.keyspaces || [];
            updateKeyspaceSelect();
            // Auto-load first keyspace
            if (globalState.keyspaces.length > 0) {
                const firstKs = globalState.keyspaces[0];
                document.getElementById('keyspaceSelect').value = `${firstKs.cluster.id}/${firstKs.keyspace.name}`;
                loadVSchema();
            }
        } catch (error) {
            console.error('Failed to load keyspaces for VSchema tab:', error);
        }
    }
}

function updateKeyspaceSelect() {
    const select = document.getElementById('keyspaceSelect');
    if (!select) return;

    select.innerHTML = '<option value="">Select keyspace...</option>';
    globalState.keyspaces.forEach(ks => {
        select.innerHTML += `<option value="${ks.cluster.id}/${ks.keyspace.name}">${ks.keyspace.name} (${ks.cluster.name})</option>`;
    });
}

async function loadVSchema() {
    const select = document.getElementById('keyspaceSelect');
    const container = document.getElementById('vschemaContent');
    const value = select.value;

    if (!value) {
        container.innerHTML = '';
        return;
    }

    const [clusterId, keyspace] = value.split('/');

    try {
        showLoading(container, 'Loading VSchema...');

        const data = await fetchAPI(`/vschema/${clusterId}/${keyspace}`);

        container.innerHTML = renderVSchema(keyspace, data);
    } catch (error) {
        container.innerHTML = renderError('Failed to load VSchema', error.message);
    }
}

function renderVSchema(keyspace, vschema) {
    let html = `<div class="detail-section"><h3>VSchema for ${keyspace}</h3>`;

    // Check if we have table definitions
    if (vschema.tables || vschema.v_schema?.tables) {
        const tables = vschema.tables || vschema.v_schema?.tables || {};

        // Render each table's vschema
        for (const [tableName, tableConfig] of Object.entries(tables)) {
            html += renderVSchemaTable(tableName, tableConfig);
        }
    } else {
        html += '<div class="warning">No table definitions found in VSchema.</div>';
    }

    // Show raw VSchema
    html += `
        <div class="card-section">
            <h4>Raw VSchema (JSON)</h4>
            <details>
                <summary style="cursor: pointer; color: #3498db; margin-bottom: 10px;">Show/Hide Full VSchema</summary>
                <pre>${JSON.stringify(vschema, null, 2)}</pre>
            </details>
        </div>
    `;

    html += '</div>';
    return html;
}

function renderVSchemaTable(tableName, config) {
    let html = `
        <div class="card vschema-table">
            <h4>${tableName}</h4>
    `;

    // Column vindexes
    if (config.column_vindexes && config.column_vindexes.length > 0) {
        html += '<div class="info-item">';
        html += '<div class="info-label">Vindexes</div>';

        config.column_vindexes.forEach(vindex => {
            html += `
                <div style="margin: 10px 0; padding: 10px; background: #f8f9fa; border-radius: 6px;">
                    <div><strong>Column:</strong> ${vindex.column || vindex.columns?.join(', ') || 'N/A'}</div>
                    <div><strong>Name:</strong> ${vindex.name}</div>
                    ${vindex.is_unique ? '<span class="badge badge-success">Unique</span>' : ''}
                </div>
            `;
        });

        html += '</div>';
    }

    // Auto increment
    if (config.auto_increment) {
        html += `
            <div class="info-item">
                <div class="info-label">Auto Increment</div>
                <div class="info-value">${JSON.stringify(config.auto_increment)}</div>
            </div>
        `;
    }

    // Show full config
    html += `
        <details style="margin-top: 15px;">
            <summary style="cursor: pointer; color: #3498db;">View Full Configuration</summary>
            <pre style="margin-top: 10px; font-size: 12px;">${JSON.stringify(config, null, 2)}</pre>
        </details>
    `;

    html += '</div>';
    return html;
}

// ===================================
// Utility Functions
// ===================================

function showLoading(container, message = 'Loading...') {
    container.innerHTML = `
        <div class="loading">
            <div class="spinner"></div>
            <p>${message}</p>
        </div>
    `;
}

function renderError(title, message) {
    return `
        <h2>${title}</h2>
        <div class="error">
            <strong>Error:</strong> ${escapeHtml(message)}
        </div>
    `;
}

function renderEmptyState(title, message) {
    return `
        <div class="empty-state">
            <div class="empty-state-icon">=�</div>
            <div class="empty-state-message">${title}</div>
            <p>${message}</p>
        </div>
    `;
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

// ===================================
// Auto-refresh functionality
// ===================================

function enableAutoRefresh(intervalSeconds = 30) {
    if (globalState.refreshInterval) {
        clearInterval(globalState.refreshInterval);
    }

    globalState.refreshInterval = setInterval(() => {
        loadTabData(globalState.currentTab);
    }, intervalSeconds * 1000);
}

function disableAutoRefresh() {
    if (globalState.refreshInterval) {
        clearInterval(globalState.refreshInterval);
        globalState.refreshInterval = null;
    }
}

// ===================================
// Initialization
// ===================================

function initializeTabs() {
    // Set up tab click handlers
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
            const tabName = tab.dataset.tab;
            showTab(tabName);
        });
    });

    // Handle browser back/forward
    window.addEventListener('popstate', handlePopState);

    // Load initial tab from URL
    const initialTab = getTabFromURL();
    showTab(initialTab, false);
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    initializeTabs();

    // Optional: Enable auto-refresh (uncomment to enable)
    // enableAutoRefresh(30);
});
