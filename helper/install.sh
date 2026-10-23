#!/bin/bash
# Ask Reeves Helper installer (macOS only).
# Builds a tiny app in ~/Applications that lets Ask Reeves open a file in the
# app YOU choose. Nothing is downloaded except this script, nothing is uploaded.
set -e

if [ "$(uname)" != "Darwin" ]; then echo "This helper is for Mac only."; exit 1; fi

APP="$HOME/Applications/Ask Reeves Helper.app"
SUPPORT="$HOME/Library/Application Support/AskReeves"
mkdir -p "$HOME/Applications" "$SUPPORT"
WORK="$(mktemp -d)"

# ---------- 1. the shell logic (parsing, safety checks, remembered choices) ----------
cat > "$SUPPORT/askreeves.sh" <<'SH_EOF'
#!/bin/bash
# Ask Reeves Helper - shell side. Called by the helper app; never by websites directly.
PREFS="$HOME/Library/Application Support/AskReeves/prefs.tsv"
cmd="$1"; shift

# file types that could run code if opened: never opened by the helper
BLOCKED=" app command sh bash zsh csh tcsh ksh tool pkg mpkg dmg iso scpt scptd applescript workflow action terminal jar exe bat cmd com msi scr pif lnk vbs ps1 wsf js jsx jsxbin py pl rb php url webloc inetloc fileloc prefpane saver plugin kext service dylib so command "

case "$cmd" in
  param)   # param URL NAME -> decoded value of ?NAME=...
    raw=$(printf '%s' "$1" | sed -n "s/.*[?&]$2=\([^&]*\).*/\1/p" | head -1)
    printf '%b' "$(printf '%s' "$raw" | sed 's/%/\\x/g')"
    ;;
  validate)  # validate RELPATH -> "ok" or a reason
    rel="$1"
    if [ -z "$rel" ]; then echo "The link had no file in it."; exit 0; fi
    case "$rel" in /*) echo "That file path is not allowed."; exit 0;; esac
    case "/$rel/" in */../*|*/./*) echo "That file path is not allowed."; exit 0;; esac
    if printf '%s' "$rel" | LC_ALL=C grep -q '[[:cntrl:]]'; then echo "That file path is not allowed."; exit 0; fi
    b="${rel##*/}"
    case "$b" in *.*) e="${b##*.}";; *) e="";; esac
    e=$(printf '%s' "$e" | tr 'A-Z' 'a-z')
    case "$BLOCKED" in *" $e "*) [ -n "$e" ] && { echo "For safety, Reeves never opens .$e files."; exit 0; };; esac
    echo ok
    ;;
  ext)     # ext RELPATH -> lowercase extension or "none"
    b="${1##*/}"
    case "$b" in *.*) e="${b##*.}";; *) e="";; esac
    e=$(printf '%s' "$e" | tr 'A-Z' 'a-z')
    [ -n "$e" ] && echo "$e" || echo none
    ;;
  pget)    # pget KEY
    K="$1" awk -F'\t' 'BEGIN{k=ENVIRON["K"]} $1==k{v=substr($0,length(k)+2)} END{if(v!="")print v}' "$PREFS" 2>/dev/null
    ;;
  pset)    # pset KEY VALUE
    mkdir -p "$(dirname "$PREFS")"; touch "$PREFS"
    K=$(printf '%s' "$1" | tr '\t\n\r' '   ') V=$(printf '%s' "$2" | tr '\t\n\r' '   ')
    export K
    awk -F'\t' 'BEGIN{k=ENVIRON["K"]} $1!=k' "$PREFS" > "$PREFS.tmp"
    printf '%s\t%s\n' "$K" "$V" >> "$PREFS.tmp"
    mv "$PREFS.tmp" "$PREFS"
    ;;
  pdel)    # pdel KEY
    [ -f "$PREFS" ] || exit 0
    K=$(printf '%s' "$1" | tr '\t\n\r' '   ') awk -F'\t' 'BEGIN{k=ENVIRON["K"]} $1!=k' "$PREFS" > "$PREFS.tmp"
    mv "$PREFS.tmp" "$PREFS"
    ;;
  isdir)   [ -n "$1" ] && [ -d "$1" ] && echo yes || echo no ;;
  isfile)  [ -n "$1" ] && [ -f "$1" ] && echo yes || echo no ;;
  noslash) p="$1"; while [ "${#p}" -gt 1 ] && [ "${p%/}" != "$p" ]; do p="${p%/}"; done; [ "$p" = "/" ] && echo "" || echo "$p" ;;
  openwith) /usr/bin/open -a "$1" "$2" ;;
  *) echo "unknown command"; exit 2 ;;
esac
SH_EOF
chmod +x "$SUPPORT/askreeves.sh"

# ---------- 2. the app (receives ask-reeves:// links from Ask Reeves) ----------
cat > "$WORK/helper.applescript" <<'AS_EOF'
on helperPath()
	return (POSIX path of (path to application support folder from user domain)) & "AskReeves/askreeves.sh"
end helperPath

on sh(args)
	return do shell script (quoted form of helperPath()) & " " & args
end sh

on run
	activate
	display dialog "Ask Reeves Helper is installed." & return & return & "Go back to Ask Reeves, click a file and press Open with... The first time, it asks which folder you chose and which app should open that kind of file. It remembers your answers." buttons {"OK"} default button "OK" with title "Ask Reeves Helper"
end run

on open location theURL
	try
		handleLink(theURL)
	on error errMsg number errNum
		if errNum is not -128 then
			activate
			display dialog "Reeves could not open that file." & return & return & errMsg buttons {"OK"} default button "OK" with icon caution with title "Ask Reeves Helper"
		end if
	end try
end open location

on handleLink(theURL)
	set rootName to sh("param " & quoted form of theURL & " root")
	set relPath to sh("param " & quoted form of theURL & " rel")
	set changeWhat to sh("param " & quoted form of theURL & " change")
	if rootName is "" then error "The link did not say which folder the file is in."
	set verdict to sh("validate " & quoted form of relPath)
	if verdict is not "ok" then error verdict
	
	-- 1. Where is the folder on this Mac? (asked once, then remembered)
	set rootKey to "root:" & rootName
	set fullPath to ""
	repeat 2 times
		set rootDir to sh("pget " & quoted form of rootKey)
		set justAsked to false
		if changeWhat is "folder" or rootDir is "" or (sh("isdir " & quoted form of rootDir) is not "yes") then
			set rootDir to askForFolder(rootName)
			sh("pset " & quoted form of rootKey & " " & quoted form of rootDir)
			set justAsked to true
			set changeWhat to ""
		end if
		set candidate to rootDir & "/" & relPath
		if sh("isfile " & quoted form of candidate) is "yes" then
			set fullPath to candidate
			exit repeat
		end if
		sh("pdel " & quoted form of rootKey)
		if justAsked then error "I could not find that file inside the folder you chose. Was it the right folder? Try again and choose the folder called " & rootName & "."
	end repeat
	if fullPath is "" then error "I could not find that file on this Mac."
	
	-- 2. Which app opens this kind of file? (asked once per file type, then remembered)
	set ext to sh("ext " & quoted form of relPath)
	set appKey to "app:" & ext
	set appPath to sh("pget " & quoted form of appKey)
	if changeWhat is "app" or appPath is "" or (sh("isdir " & quoted form of appPath) is not "yes") then
		set appPrompt to "Which app should open ." & ext & " files? Reeves will remember your choice."
		activate
		set pickedApp to choose file with prompt appPrompt of type {"com.apple.application-bundle"} default location (path to applications folder)
		set appPath to sh("noslash " & quoted form of (POSIX path of pickedApp))
		sh("pset " & quoted form of appKey & " " & quoted form of appPath)
	end if
	
	-- 3. Open it
	sh("openwith " & quoted form of appPath & " " & quoted form of fullPath)
end handleLink

on askForFolder(rootName)
	set folderPrompt to "Ask Reeves wants to open a file from your folder called " & quote & rootName & quote & ". Please choose that folder on this Mac. Reeves will remember it."
	activate
	set picked to choose folder with prompt folderPrompt
	set p to sh("noslash " & quoted form of (POSIX path of picked))
	if p is "" then error "That folder is not allowed. Please choose the folder called " & rootName & "."
	return p
end askForFolder
AS_EOF

rm -rf "$APP"
osacompile -o "$APP" "$WORK/helper.applescript"

PL="$APP/Contents/Info.plist"
PB=/usr/libexec/PlistBuddy
$PB -c "Set :CFBundleIdentifier com.gunpowderstudios.askreeveshelper" "$PL" 2>/dev/null || $PB -c "Add :CFBundleIdentifier string com.gunpowderstudios.askreeveshelper" "$PL"
$PB -c "Delete :CFBundleURLTypes" "$PL" 2>/dev/null || true
$PB -c "Add :CFBundleURLTypes array" \
    -c "Add :CFBundleURLTypes:0 dict" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLName string Ask Reeves" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string ask-reeves" "$PL"

codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" >/dev/null 2>&1 || true
rm -rf "$WORK"

echo "Installed: $APP"
open "$APP"
