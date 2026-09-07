import os
import shutil
from flask import Flask, request, jsonify
from pathlib import Path

app = Flask(__name__)

@app.route('/serialize', methods=['POST'])
def serialize():
    """
    Serializes files either individually (custom order) or all files in a directory.
    
    - `fop1` (file operation): you supply a list of individual file paths in the order you
      want them serialized. The server will rename each file using the supplied order
      (index passed by client).
    - `fop2` (directory operation): you supply one or more directory paths. Each directory
      is processed in its filesystem order; the server iterates the contained files in
      sorted order and renames them sequentially.

    Expected JSON:
    {
        "files": [
            // for fop1: simple strings or objects with explicit index
            
            "/path/to/file1",
            {"path": "/path/to/file2", "index": 5},
            "/path/to/file3"
        ],
        "indexer": "_" or "-" or " ",
        "operation": "fop1" (files) or "fop2" (directory)
    }

    When using `fop1`, you may supply an ordered list of files; they will be
    serialized in the order presented. If you need to skip or assign a specific
    position, provide each entry as an object with a `path` and numeric `index`.
    """
    try:
        data = request.json
        files = data.get('files', [])
        indexer = data.get('indexer', '_')
        operation = data.get('operation', 'fop1')
        
        if not files:
            return jsonify({'error': 'No files or directories provided'}), 400
        
        results = []
        counter = 1

        for entry in files:
            # entries can be either a path string or a dict with explicit index
            if isinstance(entry, dict):
                file_path = entry.get('path')
                explicit_index = entry.get('index')
            else:
                file_path = entry
                explicit_index = None

            if not file_path or not os.path.exists(file_path):
                results.append({'path': file_path, 'status': 'error', 'message': 'Path not found'})
                continue

            if operation == 'fop2':  # Directory operation
                if os.path.isdir(file_path):
                    renamed_files = rename_files_in_directory(file_path, indexer)
                    results.append({
                        'path': file_path,
                        'status': 'success',
                        'renamed_files': renamed_files
                    })
                else:
                    results.append({'path': file_path, 'status': 'error', 'message': 'Not a directory'})
            else:  # fop1 - single file operation
                if os.path.isfile(file_path):
                    idx = explicit_index if explicit_index is not None else counter
                    new_name = rename_single_file(file_path, indexer, idx)
                    results.append({
                        'path': file_path,
                        'status': 'success',
                        'new_name': new_name,
                        'index': idx
                    })
                    if explicit_index is None:
                        counter += 1
                else:
                    results.append({'path': file_path, 'status': 'error', 'message': 'Not a file'})
        
        return jsonify({'status': 'success', 'results': results}), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def rename_files_in_directory(directory, serializer):
    """Rename all files in a directory with the serializer pattern"""
    files = os.listdir(directory)
    renamed_files = []
    counter = 1
    
    for file in sorted(files):
        file_path = os.path.join(directory, file)
        
        if os.path.isfile(file_path):
            file_ext = os.path.splitext(file)[1]
            new_name = f"{serializer}{counter}{file_ext}"
            new_path = os.path.join(directory, new_name)
            
            try:
                os.rename(file_path, new_path)
                renamed_files.append({'old_name': file, 'new_name': new_name})
                counter += 1
            except Exception as e:
                renamed_files.append({'old_name': file, 'status': 'error', 'message': str(e)})
    
    return renamed_files

def rename_single_file(file_path, serializer, index):
    """Rename a single file"""
    directory = os.path.dirname(file_path)
    filename = os.path.basename(file_path)
    file_ext = os.path.splitext(filename)[1]
    new_name = f"{serializer}{index}{file_ext}"
    new_path = os.path.join(directory, new_name)
    
    os.rename(file_path, new_path)
    return new_name

if __name__ == '__main__':
    app.run(debug=True, port=5000)
