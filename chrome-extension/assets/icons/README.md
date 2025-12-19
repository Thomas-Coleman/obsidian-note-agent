# Extension Icons

This directory needs PNG icons in the following sizes:
- `icon16.png` - 16x16 pixels (toolbar icon)
- `icon48.png` - 48x48 pixels (extension management page)
- `icon128.png` - 128x128 pixels (Chrome Web Store)

## Creating Icons

### Option 1: Use an Online Tool
1. Visit [favicon.io](https://favicon.io/favicon-generator/) or similar
2. Design a simple notepad/capture icon
3. Download PNG files in required sizes
4. Rename and place them in this directory

### Option 2: Use Design Software
Use Figma, Sketch, or Photoshop to create:
- Simple notepad icon design
- Purple/violet color scheme (#7c3aed) to match the extension
- Export as PNG in 16x16, 48x48, and 128x128 sizes

### Option 3: Convert the SVG Template
An SVG template (`icon-template.svg`) is provided in this directory:

```bash
# Using ImageMagick (if installed)
convert -background none icon-template.svg -resize 16x16 icon16.png
convert -background none icon-template.svg -resize 48x48 icon48.png
convert -background none icon-template.svg -resize 128x128 icon128.png
```

## Temporary Workaround

For testing, you can use any PNG images named appropriately. The extension will work without icons, but Chrome will show a default icon instead.
