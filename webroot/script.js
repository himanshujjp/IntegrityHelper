// script.js - Frontend logic for Integrity Helper UI

document.addEventListener('DOMContentLoaded', function() {
    // Check if API server is running
    checkAPIServer();

    loadModules();
    document.getElementById('installAllBtn').addEventListener('click', installAllModules);
    document.getElementById('testBtn').addEventListener('click', testCGI);
});

async function checkAPIServer() {
    const statusIndicator = document.createElement('div');
    statusIndicator.id = 'apiStatus';
    statusIndicator.className = 'alert alert-warning';
    statusIndicator.innerHTML = '<small>Checking API server...</small>';

    const container = document.querySelector('.container');
    container.insertBefore(statusIndicator, container.firstChild);

    try {
        const response = await fetch('http://127.0.0.1:8585/api_test.sh', {
            method: 'GET',
            signal: AbortSignal.timeout(5000)
        });

        if (response.ok) {
            statusIndicator.className = 'alert alert-success';
            statusIndicator.innerHTML = '<small>✓ API server is running</small>';
            setTimeout(() => statusIndicator.remove(), 3000);
        } else {
            throw new Error(`HTTP ${response.status}`);
        }
    } catch (e) {
        statusIndicator.className = 'alert alert-danger';
        statusIndicator.innerHTML = '<small>✗ API server not responding. Please restart the module.</small>';
        console.error('API server check failed:', e);
    }
}

async function loadModules() {
    // Load manifest
    const response = await fetch('manifest.json');
    const modules = await response.json();

    // Load state
    let state = {};
    try {
        const stateResponse = await fetch('http://127.0.0.1:8585/api_state.sh');
        state = await stateResponse.json();
    } catch (e) {
        console.log('No state file yet');
    }

    const container = document.getElementById('modulesContainer');
    container.innerHTML = '';

    for (const module of modules) {
        // Fetch latest release info from GitHub API
        const releaseInfo = await fetchLatestRelease(module.repo);

        const card = createModuleCard(module, releaseInfo, state[module.name]);
        container.appendChild(card);
    }
}

async function fetchLatestRelease(repoUrl) {
    // Extract owner/repo from URL
    const match = repoUrl.match(/github\.com\/([^\/]+)\/([^\/]+)/);
    if (!match) return null;

    const apiUrl = `https://api.github.com/repos/${match[1]}/${match[2]}/releases/latest`;
    try {
        const response = await fetch(apiUrl);
        if (!response.ok) throw new Error('Failed to fetch');
        return await response.json();
    } catch (e) {
        console.error('Error fetching release:', e);
        return null;
    }
}

function createModuleCard(module, releaseInfo, installedVersion) {
    const card = document.createElement('div');
    card.className = 'col-md-6 mb-4';

    const isInstalled = installedVersion && releaseInfo && installedVersion === releaseInfo.tag_name;
    const status = isInstalled ? 'Installed' : 'Not Installed';

    card.innerHTML = `
        <div class="card">
            <div class="card-body">
                <h5 class="card-title">${module.name}</h5>
                <p class="card-text">${module.description}</p>
                <p class="text-muted">Author: <a href="${module.repo}" target="_blank">${module.author}</a></p>
                <p class="text-muted">License: ${module.license}</p>
                ${releaseInfo ? `
                    <p>Latest: ${releaseInfo.tag_name} (${new Date(releaseInfo.published_at).toLocaleDateString()})</p>
                ` : '<p>Unable to fetch latest release</p>'}
                <p>Status: <span class="${isInstalled ? 'text-success' : 'text-warning'}">${status}</span></p>
                <div class="btn-group">
                    <button class="btn btn-outline-primary btn-sm download-btn" data-repo="${module.repo}" data-name="${module.name}">Download</button>
                    <button class="btn btn-outline-success btn-sm install-btn" data-name="${module.name}" ${isInstalled ? 'disabled' : ''}>Install</button>
                    <button class="btn btn-outline-info btn-sm repo-btn" data-repo="${module.repo}">Open Repo</button>
                </div>
            </div>
        </div>
    `;

    // Add event listeners
    card.querySelector('.download-btn').addEventListener('click', (e) => downloadModule(module.name, module.repo, e));
    card.querySelector('.install-btn').addEventListener('click', (e) => installModule(module.name, e));
    card.querySelector('.repo-btn').addEventListener('click', () => window.open(module.repo, '_blank'));

    return card;
}

async function downloadModule(name, repo, event) {
    const statusContainer = document.getElementById('statusContainer');
    const statusText = document.getElementById('statusText');
    const btn = event.target;
    const originalText = btn.textContent;
    btn.disabled = true;
    btn.textContent = 'Downloading...';
    statusContainer.style.display = 'block';
    statusText.textContent = `Downloading ${name}...`;

    try {
        const formData = new URLSearchParams();
        formData.append('name', name);
        formData.append('repo', repo);

        const response = await fetch('http://127.0.0.1:8585/api_download.sh', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: formData.toString()
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const result = await response.text();
        statusText.textContent = result;
        loadModules(); // Refresh
    } catch (e) {
        statusText.textContent = 'Download failed: ' + e.message;
        console.error('Download error:', e);
    } finally {
        btn.disabled = false;
        btn.textContent = originalText;
    }
}

async function installModule(name, event) {
    const statusContainer = document.getElementById('statusContainer');
    const statusText = document.getElementById('statusText');
    const btn = event.target;
    const originalText = btn.textContent;
    btn.disabled = true;
    btn.textContent = 'Installing...';
    statusContainer.style.display = 'block';
    statusText.textContent = `Installing ${name}...`;

    try {
        const formData = new URLSearchParams();
        formData.append('name', name);

        const response = await fetch('http://127.0.0.1:8585/api_install.sh', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: formData.toString()
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const result = await response.text();
        statusText.textContent = result;
        loadModules(); // Refresh
    } catch (e) {
        statusText.textContent = 'Install failed: ' + e.message;
        console.error('Install error:', e);
    } finally {
        btn.disabled = false;
        btn.textContent = originalText;
    }
}

async function installAllModules() {
    const statusContainer = document.getElementById('statusContainer');
    const statusText = document.getElementById('statusText');
    const btn = document.getElementById('installAllBtn');

    btn.disabled = true;
    btn.textContent = 'Installing...';
    statusContainer.style.display = 'block';
    statusText.textContent = 'Installing all modules...';

    try {
        const response = await fetch('http://127.0.0.1:8585/api_install_all.sh', {
            method: 'POST'
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const result = await response.text();
        statusText.textContent = result;
        loadModules(); // Refresh
    } catch (e) {
        statusText.textContent = 'Install All failed: ' + e.message;
        console.error('Install All error:', e);
    } finally {
        btn.disabled = false;
        btn.textContent = 'Install All Modules';
    }
}

async function testCGI() {
    const statusContainer = document.getElementById('statusContainer');
    const statusText = document.getElementById('statusText');
    const btn = document.getElementById('testBtn');

    btn.disabled = true;
    btn.textContent = 'Testing...';
    statusContainer.style.display = 'block';
    statusText.textContent = 'Testing API server...';

    try {
        const response = await fetch('http://127.0.0.1:8585/api_test.sh', {
            method: 'GET'
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const result = await response.text();
        statusText.textContent = result;
    } catch (e) {
        statusText.textContent = 'API Test Failed: ' + e.message;
        console.error('API test error:', e);
    } finally {
        btn.disabled = false;
        btn.textContent = 'Test API';
    }
}
