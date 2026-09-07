#!/bin/bash
source /tmp/flask_env/bin/activate
cd "$(dirname "$0")"
python backend.py
