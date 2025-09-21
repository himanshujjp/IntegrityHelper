# Integrity Helper Magisk/APatch/KernelSU Module

<div align="center">

![Integrity Helper](https://img.shields.io/badge/Integrity-Helper-blue?style=for-the-badge)
![Version](https://img.shields.io/badge/version-v1.0-green?style=flat-square)
![Compatibility](https://img.shields.io/badge/compatibility-Magisk%20%7C%20APatch%20%7C%20KernelSU-orange?style=flat-square)

**Universal web-based UI to manage and install integrity-related Magisk modules**

[📥 Download Latest Release](https://github.com/himanshujjp/IntegrityHelper/releases) • [📖 Documentation](#usage) • [🐛 Report Issues](https://github.com/himanshujjp/IntegrityHelper/issues)

</div>

---

## ✨ Features

- 🌐 **Web UI**: Lightweight web interface running on `localhost:8585`
- 📦 **Module Management**: Download, install, and track status of required modules
- 🔄 **Auto-Updates**: Always fetches latest releases from official GitHub repositories
- ⚡ **Batch Install**: "Install All" button for convenient setup
- 📊 **Status Tracking**: Persistent state of installed module versions
- 🔒 **Safety First**: Only downloads from official repos with clear disclaimer
- 🔧 **Universal Support**: Works with Magisk, APatch, and KernelSU automatically

## 🛠️ Compatibility

| Root Solution | Status | Support Level |
|---------------|--------|---------------|
| **Magisk** | ✅ Full | Complete support |
| **APatch** | ✅ Full | Complete support |
| **KernelSU** | ✅ Full | Complete support |

*The module automatically detects your root solution and configures itself accordingly.*

## 📦 Required Modules

This module manages the following integrity-related Magisk modules:

| Module | Description | Repository |
|--------|-------------|------------|
| [**PlayIntegrityFork**](https://github.com/osm0sis/PlayIntegrityFork) | Play Integrity API bypass | `osm0sis/PlayIntegrityFork` |
| [**TrickyStore**](https://github.com/5ec1cff/TrickyStore) | Advanced store restrictions bypass | `5ec1cff/TrickyStore` |
| [**PlayStoreSelfUpdateBlocker**](https://github.com/himanshujjp/PlayStoreSelfUpdateBlocker) | Blocks Play Store auto-updates | `himanshujjp/PlayStoreSelfUpdateBlocker` |
| [**yurikey**](https://github.com/YurikeyDev/yurikey) | Yuri Key integrity module | `YurikeyDev/yurikey` |
| [**ZygiskNext**](https://github.com/Dr-TSNG/ZygiskNext) | Next-generation Zygisk implementation | `Dr-TSNG/ZygiskNext` |

## 🚀 Installation

### Step 1: Download
Download `IntegrityHelper.zip` from the [latest release](https://github.com/himanshujjp/IntegrityHelper/releases)

### Step 2: Flash
Flash the ZIP via your root manager:
- **Magisk Manager** → Modules → Install from storage
- **APatch** → Install → Select ZIP
- **KernelSU** → Install → Select ZIP

### Step 3: Reboot
Reboot your device to activate the module

### Step 4: Access UI
The web UI will automatically start on boot. Access it at: `http://127.0.0.1:8585`

## 🎯 Quick Access

After installation, use these commands to open the UI:

**For Magisk/APatch:**
```bash
sh /data/adb/modules/IntegrityHelper/open_ui.sh
```

**For KernelSU:**
```bash
sh /data/adb/ksu/modules/IntegrityHelper/open_ui.sh
```

## 📖 Usage

1. **Access the Web UI** at `http://127.0.0.1:8585`
2. **View Module Status**: See all required modules with their current installation status
3. **Download Modules**: Click "Download" to fetch the latest release for a specific module
4. **Install Modules**: Click "Install" to install the downloaded module
5. **Batch Install**: Use "Install All" to download and install all modules at once
6. **View Repositories**: Click "Open Repo" to view the module's GitHub page

### UI Features

- 🔄 **Real-time Status**: Shows installed versions vs latest available
- 📥 **One-click Download**: Downloads latest releases automatically
- ⚙️ **Smart Installation**: Handles permissions and dependencies
- 📊 **Progress Tracking**: Visual feedback during operations
- 🔍 **Repository Links**: Direct access to source code

## 🔧 Technical Details

| Component | Technology | Details |
|-----------|------------|---------|
| **Backend** | Shell Scripts | Busybox utilities with CGI support |
| **Web Server** | Busybox httpd | Lightweight CGI-capable server |
| **Frontend** | HTML/JS | Bootstrap-styled responsive interface |
| **Communication** | AJAX | RESTful API calls to CGI endpoints |
| **Storage** | JSON | State saved in `/data/adb/IntegrityHelper/state.json` |
| **Downloads** | Temporary | Files stored in `/data/local/tmp/modules/` |

## ⚠️ Safety & Disclaimer

> **⚠️ Use at your own risk! This tool downloads and installs third-party modules.**

### Important Notes:
- Always backup your data before installing modules
- Review module descriptions and source code before use
- Only install modules you understand and trust
- Installing third-party modules can potentially harm your device
- May violate terms of service for certain apps/services

### What this tool does:
- ✅ Downloads from official GitHub repositories only
- ✅ Verifies module integrity during installation
- ✅ Provides clear version tracking
- ✅ Offers easy uninstallation options

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **UI not loading** | Check if module is enabled in your root manager |
| **Download fails** | Ensure internet connection and GitHub access |
| **Install fails** | Check root manager logs and module compatibility |
| **Permission issues** | Ensure proper root access and SELinux status |
| **Port conflicts** | Verify no other service uses port 8585 |

### Debug Commands

```bash
# Check if service is running
ps | grep httpd

# View service logs
cat /data/adb/IntegrityHelper/service.log

# Test API endpoints
curl http://127.0.0.1:8585/cgi-bin/api_test.sh

# Check module status
ls -la /data/adb/modules/IntegrityHelper/
```

## 📁 Module Structure

```
IntegrityHelper/
├── META-INF/com/google/android/update-binary  # Installer
├── module.prop                                # Module properties
├── service.sh                                 # Boot service
├── open_ui.sh                                 # UI launcher script
├── webroot/                                   # Web interface
│   ├── index.html                            # Main UI
│   ├── script.js                             # Frontend logic
│   ├── manifest.json                         # Module list
│   ├── httpd.conf                            # Server config
│   └── cgi-bin/                              # CGI scripts
│       ├── api_download.sh                   # Download endpoint
│       ├── api_install.sh                    # Install endpoint
│       ├── api_install_all.sh                # Batch install endpoint
│       ├── api_state.sh                      # State endpoint
│       └── api_test.sh                       # Test endpoint
└── scripts/                                   # Backend scripts
    └── httpd.conf                            # Alternative config
```

## 📋 Changelog

### v1.0 (Current)
- ✨ Initial release with full functionality
- 🌐 Web-based UI for module management
- 📦 Support for 5 essential integrity modules
- 🔄 Automatic latest version detection
- ⚡ Batch install functionality
- 🔒 CORS-enabled API endpoints
- 📊 Persistent state tracking
- 🔧 Universal root solution support (Magisk/APatch/KernelSU)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on your device
5. Submit a pull request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/himanshujjp/IntegrityHelper.git
cd IntegrityHelper

# Make your changes
# Test on device
# Submit PR
```

## 📄 License

This project is released under the **MIT License**.

Individual managed modules maintain their own licenses. Please refer to each module's repository for license information.

## 🙏 Acknowledgments

- **osm0sis** - PlayIntegrityFork
- **5ec1cff** - TrickyStore
- **YurikeyDev** - yurikey
- **Dr-TSNG** - ZygiskNext
- **Magisk/APatch/KernelSU teams** - Root solutions

## 📞 Support

- 📧 **Issues**: [GitHub Issues](https://github.com/himanshujjp/IntegrityHelper/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/himanshujjp/IntegrityHelper/discussions)
- 📖 **Documentation**: This README

---

<div align="center">

**Made with ❤️ by [himanshujjp](https://github.com/himanshujjp)**

⭐ Star this repo if you found it useful!

</div>