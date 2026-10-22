# Ask Reeves

Private, browser-based catalogue for Gunpowder Studios' purchased artwork, fonts and layout files. Ask Reeves — if he can't find it, nobody can!

## Setup
1. In GitHub, go to **Settings → Pages** and select **Deploy from a branch**, branch **main**, folder **/(root)**, then Save.
2. Open `https://gunpowderstudios.github.io/ask-reeves/` once Pages reports that the site is ready.
3. In Chrome, choose a local folder (a Dropbox-synced folder is fine). Scan may take some time for 13,000+ images.
4. The app stores small thumbnails, filenames, notes, favourites and AI image vectors in the browser's **IndexedDB**; originals stay in their source folder and are **never uploaded** to GitHub or any external service.
5. On reopening, click **Reopen saved folder** to refresh or access full-resolution originals. Chrome may request permission again.

## Features
- Catalogues **every file** in the chosen folder: images, Photoshop (PSD/PSB), InDesign (INDD/IDML…), Illustrator/EPS, fonts, PDFs, documents and more. Previews come from the images themselves, the preview embedded in PSD/INDD/AI/PDF files, and a specimen drawn from each font; other files get a coloured type icon. Junk such as .DS_Store is skipped. A file-type filter sits beside the search box, and files over 300 MB are catalogued without a preview.
- Search by filename, folder, file type and notes (with synonyms such as armour/armor, trousers/pants)
- Folder icons across the top (click a folder to see a row of its subfolders, and so on); choosing one shows its artwork including deeper subfolders, and there is a Favourites icon
- Persistent favourites and keywords, stored separately for each chosen folder (switching folders never mixes them, and they return when you choose that folder again)
- Lazy-loaded infinite-scroll gallery
- Indexed thumbnail cache; re-selecting the same folder only checks for new, changed and deleted images
- Visual HTML catalogue export
- Contact-sheet printing (filter down to about 250 images at a time)
- **3D models:** GLB, glTF, OBJ, STL, PLY, FBX, 3MF and DAE files get a rendered thumbnail and a spin-around viewer (three.js, loaded from the CDN; models are rendered locally and never uploaded). Other 3D formats (Blender, STEP, Cinema 4D, etc.) are catalogued and searchable with a placeholder. Use the "3D models" type filter to list them.
- **Reeves AI visual search (Beta):** a CLIP model runs entirely in your browser to index your cached thumbnails and search by description. The model files (about 150 MB) are downloaded once from the internet and cached; your artwork is never uploaded. Reeves remembers that he was enabled and restores himself on your next visit. His eyes glow green: slow blink when ready, fast when analysing or searching.

**Important:** Clearing Chrome's website data erases saved thumbnails, favourites and notes (there is no backup feature). Browser quota limits may apply for large libraries. Do not add purchased art assets to this public repo.
