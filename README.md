# Serializer Demo Project

A polished Flutter + Flask utility for renaming files and directories with consistent naming patterns. The interface lets you choose a name prefix, a separator, and either a file list or a directory target before sending the request to the backend API.

## Highlights

- File or directory selection flow
- Custom prefix support, such as `serial`, `project`, or `batch`
- Three separator styles: underscore, dash, or space
- Dark-mode toggle for the desktop app shell
- Safe backend processing with validation and collision avoidance
- Clear success and error messaging

## Prerequisites

- Flutter SDK
- Dart SDK
- Python 3.10+
- Flask installed in the environment used for the backend

## Quick start

1. Install the Flutter dependencies:

   ```bash
   flutter pub get
   ```

2. Start the backend:

   ```bash
   python backend.py
   ```

3. Run the app:

   ```bash
   flutter run
   ```

4. In the app, enter a prefix like `serial`, choose a separator, pick one or more files or a directory, and hit Serialize.

## Backend API

### Health check

```http
GET http://localhost:5000/health
```

### Serialize files

```http
POST http://localhost:5000/serialize
Content-Type: application/json
```

Example payload:

```json
{
  "files": [
    "C:/Example/report.pdf",
    "C:/Example/notes.txt"
  ],
  "prefix": "serial",
  "indexer": "_",
  "operation": "fop1"
}
```

Example directory payload:

```json
{
  "files": ["C:/Example/photos"],
  "prefix": "batch",
  "indexer": "-",
  "operation": "fop2"
}
```

Response example:

```json
{
  "status": "success",
  "results": [
    {
      "path": "C:/Example/report.pdf",
      "status": "success",
      "new_name": "serial_1.pdf",
      "index": 1
    }
  ]
}
```

## Current project structure

```text
.
├── backend.py
├── lib/
│   └── main.dart
├── test/
│   └── widget_test.dart
├── pubspec.yaml
├── README.md
└── run_backend.sh
```

## Improvements applied

- Replaced the starter Flutter UI with a more intentional, user-friendly workflow
- Connected the name prefix to actual backend payloads
- Added validation for backend requests and safer file renaming
- Added unique-name collision protection so existing files are not overwritten silently
- Improved error feedback with clearer snackbars and status handling
- Reworked widget tests from the default template to meaningful app-level checks

## Notes

- The backend currently expects the Flask server to be running locally on port 5000.
- File names are created in a deterministic pattern such as `serial_1.pdf`, `batch-2.txt`, and so on.
- When a target name already exists, the backend creates a unique alternative like `serial_1 (2).pdf`.

## License

This project is provided as a local development demo. Add a proper license if you plan to distribute it publicly.
