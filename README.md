# MacLlamator

A native macOS translation app that runs entirely against your own [Ollama](https://ollama.com) server — no cloud service, no API key, no text leaving your machine.

Two panes side by side, translation as you type, and a menu bar icon to summon it over whatever you are working in. Think DeepL's window, but the model is yours.

![Platform: macOS 14+](https://img.shields.io/badge/platform-macOS%2014%2B-black)
![Swift 5](https://img.shields.io/badge/Swift-5-orange)
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
| To build | Xcode 26 or newer — the project file uses format `objectVersion = 110`, which earlier Xcode releases cannot open |

The app is sandboxed and requests outgoing network connections only. It reads and writes nothing outside its own preferences.

### Setting up Ollama

```sh
brew install ollama          # or download from ollama.com
ollama serve                 # starts the server on 127.0.0.1:11434
ollama pull llama3.1         # any instruction-following model works
```

Larger models follow the translation format more reliably. MacLlamator degrades gracefully if a model ignores the requested `LANG:`/`TEXT:` structure — you still get the translation, just without the detected-language badge.

## Installation

### Build it yourself

```sh
git clone git@github.com:amkdev/MacLlamator.git
cd MacLlamator
open MacLlamator.xcodeproj
```

Then press <kbd>⌘</kbd><kbd>R</kbd>. Or from the command line:

```sh
xcodebuild -project MacLlamator.xcodeproj -scheme MacLlamator -configuration Release build
```

### Running a downloaded build

Builds of MacLlamator are ad-hoc signed and **not notarized by Apple**, because notarization requires a paid Apple Developer account. macOS will therefore refuse to open the app on the first attempt, reporting that it "cannot be opened because Apple cannot check it for malicious software." This is expected for any independently distributed app, and here is how to get past it.

**On macOS 15 (Sequoia) and newer** — including macOS 26 — the old Control-click trick no longer works. Use:

1. Move `MacLlamator.app` to `/Applications`.
2. Double-click it once and dismiss the warning.
3. Open **System Settings → Privacy & Security**, scroll to the Security section, and click **Open Anyway** next to the message about MacLlamator.
4. Confirm with Touch ID or your password.

**On macOS 14 (Sonoma):**

1. Move `MacLlamator.app` to `/Applications`.
2. Control-click (or right-click) the app and choose **Open**.
3. Click **Open** in the dialog that appears.

**Or, from the Terminal** — this removes the quarantine flag that triggers the check in the first place:

```sh
xattr -d com.apple.quarantine /Applications/MacLlamator.app
```

You only need to do this once per installed version. Only run that command on software you actually trust; it is the mechanism Gatekeeper relies on to know a file came from the internet.

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

## Current limitations

Worth knowing before you try it:

- **No streaming.** The translation appears when the model is done rather than word by word, so long inputs sit on a spinner for a while.
- **No history.** Closing the window keeps the current text, quitting the app discards it.
- **No tests yet.**
- Translation quality is entirely the model's. A small model will produce small-model translations.

## License

Not yet licensed, which under copyright law means all rights reserved. A license needs picking before this becomes useful to anyone else — MIT is the conventional choice for an app of this size.
