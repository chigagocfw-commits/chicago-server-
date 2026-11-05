OXLYN Advanced Vinewood Editor - local images

Put PNG, JPG or WebP images here (PNG or WebP for a transparent background).

- Open Source edition: add them to web/src/images, then build the interface
  (cd web && bun run build, or node build.mjs).
- Either edition: you can also put them directly in web/dist/images.
  The build never deletes files you added there.

In the editor, reference an image as:  images/file-name.png
File names may use letters, numbers, _, - and . only.

Restart the resource (restart oxlyn-vinewood) after adding files.

oxlyn.png and oxlyn-logotipo.png are examples you can replace.
oxlyn-logotipo.png is the logo used by /vinewood showcase.
