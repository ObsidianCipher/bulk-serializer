# Serializer Demo Project

A Flutter application that provides a user-friendly interface for serializing files and directories with configurable indexing options.

## Features

- **File/Directory Selection**: Choose between selecting individual files in order or an entire directory
- **Configurable Indexing**: Select from three indexer options for serialization:
  - Underscore (`_`)
  - Dash (`-`)
  - Space (` `)
- **Dark Mode Support**: Toggle between light and dark themes
- **Real-time Display**: View selected files/directories before processing
- **Backend Integration**: Communicates with a backend API for serialization processing
- **Error Handling**: Comprehensive error handling with user-friendly notifications

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Backend server running on `http://localhost:5000`
- Required Flutter packages:
  - `flutter/material.dart`
  - `file_selector`
  - `http`

## Installation

1. **Clone or extract the project**
   ```bash
   cd serializer_demo_prjoct1
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart          # Main application entry point
└── ...
```

## Usage

### Application Workflow

1. **Enter Serialization String** (optional)
   - Enter text in the TextField at the top of the screen

2. **Select File Indexer**
   - Choose one of three indexing methods:
     - Underscore (_)
     - Dash (-)
     - Space ( )

3. **Choose File Operation Method**
   - **Select File in order**: Pick individual files sequentially
   - **Select Directory**: Pick an entire directory

4. **Select Files/Directory**
   - Click the "Select" button to open the file/directory picker
   - Selected items will display in the list below

5. **Serialize**
   - Click the "Serialize" button to process the selected files
   - The app will send data to the backend and display the result

### UI Components

- **AppBar**: Contains title and dark mode toggle
- **Input TextField**: For entering serialization string
- **Radio Cards**: Configuration options for indexer and file operations
- **File Operations Card**: File selection and display
- **Serialize Button**: Submits data to backend

## Backend API

### Endpoint

```
POST http://localhost:5000/serialize
```

### Request Format

```json
{
  "files": ["path/to/file1", "path/to/file2"],
  "indexer": "_",
  "operation": "fop1"
}
```

### Response Format

```json
{
  "results": [...]
}
```

## State Management

The application uses Flutter's built-in `StatefulWidget` for state management:

- `MyApp`: Manages dark mode state
- `MyHomePage`: Manages UI state (selected files, options, etc.)

## Error Handling

The application handles:
- Network timeouts (10-second timeout)
- Backend errors (non-200 status codes)
- Connection failures
- Displays user-friendly error messages via SnackBar

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  file_selector: ^0.x.x
  http: ^0.x.x
```

## Theme Configuration

- **Light Theme**: Blue accent color (RGB: 117, 186, 235)
- **Dark Theme**: Same accent with dark brightness
- **Material 3**: Enabled for modern design

## Known Limitations

- Backend must be running on localhost:5000
- 10-second timeout for API requests
- File picker functionality depends on OS support

## Future Enhancements

- Add file preview functionality
- Support for multiple backend endpoints
- Progress bar for serialization
- Batch processing with queuing
- Export results to file
- Settings/configuration screen

## Troubleshooting

### "Unable to connect to backend"
- Ensure backend server is running on `http://localhost:5000`
- Check network connectivity

### "File picker not working"
- Ensure `file_selector` package is properly installed
- Run `flutter clean` and `flutter pub get`

### Theme not changing
- Ensure MaterialApp theme is properly rebuilt
- Check device theme settings

## License

[Add your license here]

## Support

For issues or questions, please contact the development team.
