# Friction Log macOS

Native macOS app for tracking and eliminating daily life friction.

## Overview

SwiftUI-based macOS application that provides:
- **Dashboard** - Current friction score, trends, and analytics
- **Add Friction** - Quick entry of new friction items
- **List & Edit** - Manage friction items with status updates
- **Analytics** - Visualize friction by category and over time

## Architecture

This app uses the API contract defined in `friction-log-api-contract`. All data models are generated from the OpenAPI specification to ensure type safety and consistency with the backend.

### Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **Swift Charts** - Native charting (macOS 13+)
- **URLSession** - HTTP client for REST API
- **Codable** - JSON encoding/decoding (generated from contract)

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Setup

### 1. Clone Repository

Clone with submodules:
```bash
git clone --recurse-submodules https://github.com/nytomi90/friction-log-macos.git
cd friction-log-macos
```

### 2. Generate API Contract Models

```bash
cd Contract
./scripts/generate_swift.sh
cd ..
```

This generates Swift Codable structs in `Contract/generated/swift/`

### 3. Open in Xcode

```bash
open FrictionLog/FrictionLog.xcodeproj
```

### 4. Add Generated Files to Xcode

In Xcode:
1. Right-click on the project
2. Add Files to "FrictionLog"...
3. Navigate to `Contract/generated/swift/`
4. Select all `.swift` files
5. Choose "Create folder references" (not "Create groups")
6. Click Add

### 5. Configure Backend URL

The app connects to the backend at `http://localhost:8000` by default.

Make sure the backend is running:
```bash
cd ../friction-log-backend
uvicorn app.main:app --reload
```

### 6. Build and Run

In Xcode:
- Select "My Mac" as the destination
- Press ⌘R to build and run

## Development

### Project Structure

```
friction-log-macos/
├── Contract/                # Git submodule (API contract)
├── FrictionLog/
│   ├── FrictionLog.xcodeproj
│   ├── FrictionLog/
│   │   ├── FrictionLogApp.swift      # App entry point
│   │   ├── ContentView.swift         # Main view
│   │   ├── ViewModels/
│   │   │   └── FrictionViewModel.swift
│   │   ├── Views/
│   │   │   ├── DashboardView.swift
│   │   │   ├── AddFrictionView.swift
│   │   │   └── FrictionListView.swift
│   │   ├── Services/
│   │   │   └── APIClient.swift       # Backend API client
│   │   └── Assets.xcassets/
│   └── FrictionLogTests/
└── README.md
```

### API Client

The `APIClient` class handles all backend communication:
- Base URL configuration
- Request/response encoding/decoding
- Error handling
- Uses generated Codable models from contract

### View Models

Following MVVM pattern:
- `FrictionViewModel` - Manages friction items state
- Reactive updates using `@Published`
- Separates business logic from views

## Updating API Contract

When the API contract is updated:

1. Update submodule:
```bash
cd Contract
git checkout main
git pull
cd ..
git add Contract
```

2. Regenerate Swift models:
```bash
cd Contract
./scripts/generate_swift.sh
cd ..
```

3. Build project to check for any breaking changes
4. Update views/view models if needed
5. Test functionality
6. Commit changes

## Features

### Dashboard
- Large, prominent friction score
- Active friction item count
- 30-day trend line chart
- Category breakdown bar chart

### Add Friction
- Title and description fields
- Annoyance level slider (1-5)
- Category picker
- Save with validation

### List & Edit
- All friction items with status badges
- Filter by status (Not Fixed, In Progress, Fixed)
- Tap to edit
- Swipe to delete
- Pull to refresh

### Analytics
- Real-time score calculation
- Historical trends
- Category-based insights

## Building for Distribution

To build for distribution:

1. Archive the app (Product > Archive)
2. Export as Mac app
3. Notarize with Apple (if distributing outside App Store)

## Troubleshooting

### Xcode Project Missing Files

**Issue**: If the app won't build with errors about missing files, the Xcode project may be missing some Swift file references.

**Solution**: Add all source files to the Xcode project:

1. In Xcode, right-click on the `FrictionLog` group (the one with the file icon, not the project icon)
2. Select "Add Files to 'FrictionLog'..."
3. Navigate to and add these folders/files:
   - `ViewModels/` folder (select entire folder)
   - `Views/` folder (select entire folder)
   - `Models/` folder (select entire folder)
   - `Services/` folder (select entire folder)
4. Ensure "Copy items if needed" is **unchecked**
5. Ensure "Create groups" is selected
6. Click "Add"

**Files that should be in the project**:
- `FrictionLogApp.swift`
- `ContentView.swift`
- `ViewModels/FrictionViewModel.swift`
- `Views/DashboardView.swift`
- `Views/AddFrictionView.swift`
- `Views/EditFrictionView.swift`
- `Views/FrictionListView.swift`
- `Models/FrictionItem.swift`
- `Models/Category.swift`
- `Models/Status.swift`
- `Models/Analytics.swift`
- `Services/APIClient.swift`

### Backend Connection Issues

- Ensure backend is running on port 8000
- Check firewall settings
- Verify `localhost` resolves correctly
- Test backend health: `curl http://localhost:8000/health`

### Build Errors

- Clean build folder: ⇧⌘K
- Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Regenerate contract models
- Verify all source files are added to the project (see above)
- Restart Xcode

## Known Issues & Fixes

### Edit Modal Save Feedback (Fixed ✅)
**Issue**: Modal didn't close immediately after clicking Save, no visual feedback.
**Fix**: Removed blocking delay, added success checkmark indicator.
**Commit**: 43f1ded (2026-01-29)

If you encounter any issues, please check the [GitHub Issues](https://github.com/nytomi90/friction-log-macos/issues) page.

## License

MIT
