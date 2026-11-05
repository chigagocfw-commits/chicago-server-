OXLYN Advanced Vinewood Editor - data folder

The server stores everything it saves here:

  scene.json                 the published scene (created on the first Publish)
  scene.backup.json          the previously published scene
  upload-index.json          the register of images imported from the editor
  upload-index.backup.json   the previous register
  uploads/                   the imported images themselves

Rules:
- Keep this folder (and uploads/) writable by FXServer.
- Never edit these files while the resource is running.
- Back up the whole folder before editing anything by hand and before every update.
  Updates must keep this folder as it is.

Every write is read back and verified. If these files are changed, damaged or
unreadable outside the editor, the server stops saving to protect them
("Storage is protected") and the server console explains which file and why.

To recover:
1. Read the server console message.
2. Stop oxlyn-vinewood.
3. Repair the damaged file or move it out of this folder (for example, replace a
   broken scene.json with a copy of scene.backup.json or of your own backup).
4. Start oxlyn-vinewood again.
