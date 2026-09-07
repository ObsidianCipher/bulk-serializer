import os
from pathlib import Path

from flask import Flask, jsonify, request

app = Flask(__name__)

DEFAULT_PREFIX = 'serial'
ALLOWED_INDEXERS = {'_', '-', ' '}


def _normalize_indexer(value):
    if value is None:
        return '_'

    indexer = str(value).strip()
    if indexer.lower() == 'space':
        indexer = ' '

    if indexer not in ALLOWED_INDEXERS:
        raise ValueError("indexer must be one of: '_', '-', or ' '")
    return indexer


def _normalize_prefix(value):
    prefix = str(value or DEFAULT_PREFIX).strip()
    if not prefix:
        prefix = DEFAULT_PREFIX

    cleaned_prefix = ''.join(
        char for char in prefix if char.isalnum() or char in {'-', '_', ' '}
    ).strip()
    if not cleaned_prefix:
        raise ValueError('prefix must contain letters or numbers')
    return cleaned_prefix


def _next_available_path(target_path: Path) -> Path:
    if not target_path.exists():
        return target_path

    counter = 2
    stem = target_path.stem
    suffix = target_path.suffix
    while True:
        candidate = target_path.with_name(f'{stem} ({counter}){suffix}')
        if not candidate.exists():
            return candidate
        counter += 1


def rename_single_file(file_path, indexer, index, prefix):
    """Rename a single file using a deterministic naming pattern."""
    source = Path(file_path)
    if not source.is_file():
        raise ValueError(f'{file_path} is not a file')

    target_name = f'{prefix}{indexer}{index}{source.suffix}'
    target_path = _next_available_path(source.with_name(target_name))
    os.replace(source, target_path)
    return target_path.name


def rename_files_in_directory(directory, indexer, prefix):
    """Rename all files in a directory in sorted order."""
    directory_path = Path(directory)
    if not directory_path.is_dir():
        raise ValueError(f'{directory} is not a directory')

    renamed_files = []
    files = sorted(path for path in directory_path.iterdir() if path.is_file())

    for index, file_path in enumerate(files, start=1):
        target_name = f'{prefix}{indexer}{index}{file_path.suffix}'
        target_path = _next_available_path(directory_path / target_name)
        os.replace(file_path, target_path)
        renamed_files.append({
            'old_name': file_path.name,
            'new_name': target_path.name,
            'index': index,
        })

    return renamed_files


@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'ok'}), 200


@app.route('/serialize', methods=['POST'])
def serialize():
    payload = request.get_json(silent=True) or {}
    files = payload.get('files', [])
    operation = str(payload.get('operation', 'fop1')).strip() or 'fop1'

    if not files:
        return jsonify({'error': 'No files or directories provided'}), 400

    try:
        indexer = _normalize_indexer(payload.get('indexer', '_'))
        prefix = _normalize_prefix(payload.get('prefix', payload.get('namePrefix', DEFAULT_PREFIX)))
    except ValueError as exc:
        return jsonify({'error': str(exc)}), 400

    results = []
    counter = 1

    for entry in files:
        if isinstance(entry, dict):
            file_path = entry.get('path')
            explicit_index = entry.get('index')
        else:
            file_path = entry
            explicit_index = None

        if file_path is None:
            results.append({'path': None, 'status': 'error', 'message': 'Missing file path'})
            continue

        resolved_path = str(file_path)
        if not os.path.exists(resolved_path):
            results.append({
                'path': resolved_path,
                'status': 'error',
                'message': 'Path not found',
            })
            continue

        if operation == 'fop2':
            if os.path.isdir(resolved_path):
                renamed_files = rename_files_in_directory(resolved_path, indexer, prefix)
                results.append({
                    'path': resolved_path,
                    'status': 'success',
                    'renamed_files': renamed_files,
                })
            else:
                results.append({
                    'path': resolved_path,
                    'status': 'error',
                    'message': 'Not a directory',
                })
            continue

        if os.path.isfile(resolved_path):
            idx = explicit_index if explicit_index is not None else counter
            new_name = rename_single_file(resolved_path, indexer, idx, prefix)
            results.append({
                'path': resolved_path,
                'status': 'success',
                'new_name': new_name,
                'index': idx,
            })
            if explicit_index is None:
                counter += 1
        else:
            results.append({
                'path': resolved_path,
                'status': 'error',
                'message': 'Not a file',
            })

    return jsonify({'status': 'success', 'results': results}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
