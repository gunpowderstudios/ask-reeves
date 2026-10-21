# Image Finder

Private, browser-based catalogue for Gunpowder Studios' purchased artwork.

## Setup
1. In GitHub, go to **Settings → Pages** and select **Deploy from a branch**, branch **main**, folder **/(root)**, then Save.
2. Open `https://gunpowderstudios.github.io/image-finder/` once Pages reports that the site is ready.
3. In Chrome, choose a local folder (a Dropbox-synced folder is fine). Scan may take some time for 13,000+ images.
4. The app stores small thumbnails, filenames, notes and favourites in the browser's **IndexedDB**; originals stay in their source folder and are **never uploaded** to GitHub.
5. On reopening, click **Reopen saved folder** to refresh or access full-resolution originals. Chrome may request permission again.

## Features
- Search by filename, folder and notes
- Persistent favourites and keywords
- Lazy-loaded infinite-scroll gallery
- Indexed thumbnail cache to avoid full rescan on every visit
- CSV export and JSON backups/restores of favourites and notes
- Contact-sheet printing (filter down to about 250 images at a time)

**Important:** Clearing Chrome's website data can erase saved thumbnails and preferences; export backups regularly. Browser quota limits may apply for large libraries. Do not add purchased art assets to this public repo.
