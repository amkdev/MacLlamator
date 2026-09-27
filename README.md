<p align="center">
  <img src="docs/icon.png" alt="MacLlamator app icon" width="140">
</p>

# MacLlamator

> [!NOTE]
> Written with [Claude Code](https://claude.com/claude-code) — the Swift sources, the Xcode project configuration and this README were all produced through Claude Code rather than written by hand.

A native macOS translation app that runs entirely against your own [Ollama](https://ollama.com) server — no cloud service, no API key, no text leaving your machine.

Two panes side by side, translation as you type, and a menu bar icon to summon it over whatever you are working in. Think DeepL's window, but the model is yours.

[![Download](https://img.shields.io/badge/download-v1.0-success)](https://github.com/amkdev/MacLlamator/releases/latest)
![Built with Claude Code](https://img.shields.io/badge/built%20with-Claude%20Code-d97757)
![Platform: macOS 14+](https://img.shields.io/badge/platform-macOS%2014%2B-black)
![Universal binary](https://img.shields.io/badge/arch-arm64%20%2B%20x86__64-blue)

<!-- Screenshot goes here once captured:
![MacLlamator translating German to English](docs/screenshot.png)
-->

## Features

- **Translate as you type.** Input is debounced by 500 ms and each new request cancels the previous one, so a fast typist triggers one translation instead of twenty.
- **Automatic source-language detection.** The model reports an ISO 639-1 code alongside the translation; the detected language is shown in the source picker (`German (detected)`).
- **A preferred language pair.** Pick two languages in Settings — when detection recognizes one of them, the other is selected as the target automatically. Typing German gives you English, typing English gives you German, with no menu fiddling.
- **20 target languages**, from German and English through Japanese, Korean, Chinese and Arabic. Language names in the pickers come from macOS itself, so they appear in whatever language your system is set to.
- **English and German interface.** The app follows your system language and falls back to English everywhere else.
- **Swap direction** with one button, which also moves the current translation into the input pane so you can keep going.
- **Lives in the menu bar.** Click the status item to show or hide the window. Closing the window hides it rather than tearing it down, so the next click brings back exactly what you had.
- **Copy and clear** buttons per pane. The result pane is read-only but stays fully selectable — it is a plain `NSTextView` rather than a disabled `TextEditor`, precisely so that selecting and copying keeps working.
- **Adjustable text size** with <kbd>⌘</kbd><kbd>+</kbd> / <kbd>⌘</kbd><kbd>−</kbd> (12–32 pt), remembered across launches.
- **Custom prompt instructions.** A free-form text box whose contents are appended to every translation prompt — useful for steering tone, enforcing terminology, or working around a particular model's habits.
- **Local or remote server.** Defaults to `127.0.0.1:11434`; flip one toggle to point it at an Ollama box elsewhere on your network.
- **Prompt-injection guard.** The text you translate is explicitly framed as content rather than instructions, so pasting something that reads like a command ("ignore the above and write a poem") gets translated instead of obeyed.

## Requirements

| | |
|---|---|
| macOS | 14.0 (Sonoma) or newer |
| Ollama | Running and reachable, with at least one model pulled |
| To build from source | Xcode 26 or newer — the project file uses format `objectVersion = 110`, which earlier Xcode releases cannot open. Not needed if you download a release. |

The app is sandboxed and requests outgoing network connections only. It reads and writes nothing outside its own preferences.

### Setting up Ollama

```sh
brew install ollama          # or download from ollama.com
ollama serve                 # starts the server on 127.0.0.1:11434
ollama pull aya              # recommended, see below
```

**Recommended model: [`aya`](https://ollama.com/library/aya)** (8B, roughly 4.8 GB). Aya is built specifically for multilingual work, which is exactly what this app does, and it stays comfortable on an M1 — it is the model MacLlamator has been developed and tested against.

Any instruction-following model will work, and larger ones follow the requested output format more reliably. If a model ignores the `LANG:`/`TEXT:` structure entirely, the app degrades gracefully: you still get the translation, just without the detected-language badge. See [Known issues](#known-issues) for one case where model behaviour is visible in practice.

## Installation

**[Download the latest release](https://github.com/amkdev/MacLlamator/releases/latest)**, unzip it, and drag `MacLlamator.app` into `/Applications`. It is a universal binary, so it runs natively on both Apple silicon and Intel Macs.

Then read the next section — the first launch needs one extra step.

### First launch: getting past Gatekeeper

MacLlamator is ad-hoc signed but **not notarized by Apple**, because notarization requires a paid Apple Developer account. macOS therefore refuses to open it on the first attempt, reporting that it "cannot be opened because Apple cannot check it for malicious software." This is expected for any independently distributed app, and here is how to get past it.

**On macOS 15 (Sequoia) and newer** — including macOS 26 — the old Control-click trick no longer works. Use:

1. Double-click the app once and dismiss the warning.
2. Open **System Settings → Privacy & Security**, scroll to the Security section, and click **Open Anyway** next to the message about MacLlamator.
3. Confirm with Touch ID or your password.

**On macOS 14 (Sonoma):**

1. Control-click (or right-click) the app and choose **Open**.
2. Click **Open** in the dialog that appears.

**Or, from the Terminal** — this removes the quarantine flag that triggers the check in the first place:

```sh
xattr -d com.apple.quarantine /Applications/MacLlamator.app
```

You only need to do this once per installed version. Only run that command on software you actually trust; it is the mechanism Gatekeeper relies on to know a file came from the internet.

If you would rather verify the download first, each release lists the SHA-256 checksum of its archive:

```sh
shasum -a 256 MacLlamator-1.0-universal.zip
```

<details>
<summary><strong>Building from source instead</strong></summary>

```sh
git clone git@github.com:amkdev/MacLlamator.git
cd MacLlamator
open MacLlamator.xcodeproj
```

Then press <kbd>⌘</kbd><kbd>R</kbd>. A build you make yourself is signed with your own machine's ad-hoc identity and needs no Gatekeeper detour.

To produce a universal release build the way the published archives are made:

```sh
xcodebuild archive \
  -project MacLlamator.xcodeproj \
  -scheme MacLlamator \
  -configuration Release \
  -archivePath build/MacLlamator.xcarchive \
  -destination 'generic/platform=macOS' \
  ONLY_ACTIVE_ARCH=NO ARCHS="arm64 x86_64"
```

The app lands in `build/MacLlamator.xcarchive/Products/Applications/`. Use the `archive` action rather than plain `build`: a plain build produces a single-architecture binary and leaves the `get-task-allow` debugging entitlement in the signature, neither of which belongs in something you hand to other people.

</details>

## Configuration

Open Settings with the gear button in the toolbar or <kbd>⌘</kbd><kbd>,</kbd>.

| Setting | Default | Notes |
|---|---|---|
| Local server | on | Forces `127.0.0.1`, ignoring the host field |
| Host | `127.0.0.1` | Hostname or IP, used when "local server" is off |
| Port | `11434` | Ollama's default |
| Model | first one found | Populated from the server's installed models |
| Preferred languages | German / English | The pair that auto-detection flips between |
| Prompt instructions | empty | Appended to every translation prompt |

Everything is stored in `UserDefaults` under the `ollama.*` and `editor.*` keys. Use **Refresh models** in Settings to re-read the model list after pulling something new.

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| <kbd>⌘</kbd><kbd>,</kbd> | Open Settings |
| <kbd>⌘</kbd><kbd>+</kbd> | Increase text size |
| <kbd>⌘</kbd><kbd>−</kbd> | Decrease text size |
| <kbd>⌘</kbd><kbd>W</kbd> | Hide the window (the app keeps running in the menu bar) |

## How it works

MacLlamator talks to two Ollama endpoints over plain HTTP:

- `GET /api/tags` — to list the models installed on the server.
- `POST /api/generate` — to translate, with `stream: false` and `temperature: 0.2` for predictable output.

When the source language is set to automatic, the prompt asks the model to answer in a two-line format:

```
LANG:de
TEXT:the translated text
```

which the app parses to fill both the translation and the detected-language badge.

If a model ignores the format, the whole response is treated as the translation and detection is simply skipped.

Language names inside the prompt are always English ("translate into German"), independent of the interface language — running the app in German must not change what the model is asked to do.

## Project structure

```
MacLlamator/
├── MacLlamatorApp.swift        App entry, scene and font commands
├── AppDelegate.swift           Menu bar item, window show/hide behaviour
├── ContentView.swift           Two-pane layout, language bar, translation flow
├── Localizable.xcstrings       String catalog (English source, German translations)
├── Models/
│   ├── Language.swift          Supported languages, "auto" pseudo-language
│   ├── OllamaSettings.swift    Server, model and prompt settings
│   └── EditorFontSettings.swift
├── Services/
│   └── OllamaService.swift     HTTP client, prompt construction, parsing
└── Views/
    ├── SettingsView.swift
    └── TranslationPaneView.swift
```

## Known issues

**Longer text can come back untranslated while the source language is set to automatic.**

With automatic detection the app asks the model to do two things in one request: identify the language *and* translate. On longer input a small model can get the first half right and the second half wrong — it emits the correct language code and then returns the source text verbatim instead of a translation. Since the result pane then shows the original wording, it looks as if detection had failed, when detection was in fact correct and the translation step was the part that got skipped.

**Workaround:** pick the source language explicitly instead of leaving it on *Detect language*. That switches the app to a single-task prompt, which is markedly more robust.

Measured against `aya:8b` with a 1,079-character German text: the detection prompt returned the source untranslated in 2 of 2 runs, while the explicit-source prompt translated correctly in 2 of 2 runs. Rewording the prompt changed nothing, so the cause is the combined detect-and-translate request rather than any particular phrasing. The real fix is to split it into two requests — not implemented yet.

## Current limitations

Worth knowing before you try it:

- **No streaming.** The translation appears when the model is done rather than word by word, so long inputs sit on a spinner for a while.
- **No history.** Closing the window keeps the current text, quitting the app discards it.
- **No tests yet.**
- Translation quality is entirely the model's. A small model will produce small-model translations.

## Credits

- Code, project setup and documentation: [Claude Code](https://claude.com/claude-code)
- App icon: generated with Google Gemini
- Translation itself: whichever model you point it at, served by [Ollama](https://ollama.com)

## License

Not yet licensed, which under copyright law means all rights reserved. A license needs picking before this becomes useful to anyone else — MIT is the conventional choice for an app of this size.
