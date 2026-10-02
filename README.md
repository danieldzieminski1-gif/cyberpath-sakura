# CyberPath 🌸 Twilight Sakura Edition

Learn cybersecurity with a dreamy anime-twilight UI, live threat news, and lessons that keep working offline.

## Get the APK on your phone (no computer needed)
1. Push this folder to a GitHub repo (the GitHub mobile website works).
2. Open the **Actions** tab. The *Build Android APK* workflow starts on every push (~6-10 min).
3. When it finishes, open **Releases** in your repo on your phone and tap the `.apk` to install
   (allow "install unknown apps" for your browser once).
   You can also grab it from the run page under **Artifacts**.

## Build locally
`./build_apk.sh` (needs Flutter stable, Android SDK, Java 17).

## Live data
- **Threat Pulse** on Home: cyber news (Hacker News search API) and newly exploited vulnerabilities (CISA KEV). Both are key-less public endpoints, cached on the device and replaced by built-in tips when you have never been online.
- **Remote lessons**: edit `remote/lessons.json` and push. The workflow points the app at it automatically
  (`--dart-define=LESSONS_URL=...`). New lessons are merged in; local lessons always win, so the app never breaks offline.
  Private repo? Set your own public URL in the workflow.
- Pull down on Home to refresh.

## Design tokens (`lib/core/theme/app_theme.dart`)
Twilight Midnight `#161528`, Sakura Pink `#FFB7C5`, Sunset Peach `#FFDAC1`, Soft Cream `#FFF5F6`, Soft Lavender `#D8B4FE`. Quicksand headings, Poppins body, 22px glass cards.
