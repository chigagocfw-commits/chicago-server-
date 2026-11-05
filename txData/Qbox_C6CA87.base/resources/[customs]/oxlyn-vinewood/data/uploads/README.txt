Images imported from the editor are stored here as server-generated <32 lowercase hex characters>.png files.
Keep this directory writable by FXServer. The server verifies every PNG and its saved bytes before registering it in ../upload-index.json.
Back up this directory together with upload-index.json, upload-index.backup.json and scene.json. Resource updates must preserve existing uploaded files and index data.
Files are never named from user input and are never deleted automatically.
