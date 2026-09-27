//
//  TranslationPaneView.swift
//  MacLlamator
//

import SwiftUI
import AppKit

/// One column of the translator (either the editable source pane or the
/// read-only result pane), styled after DeepL's layout.
struct TranslationPaneView: View {
    @EnvironmentObject private var fontSettings: EditorFontSettings

    @Binding var text: String
    var isEditable: Bool
    var placeholder: LocalizedStringKey
    var isLoading: Bool = false
    var onClear: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: fontSettings.size))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }

                // A plain NSTextView-backed view instead of SwiftUI's TextEditor:
                // it stays selectable/copyable even when read-only (a disabled
                // TextEditor blocks selection entirely), and lets us hide the
                // scroll indicator until the text actually overflows, instead of
                // always showing it per the system's scroll bar preference.
                NativeTextView(text: $text, isEditable: isEditable, font: .systemFont(ofSize: fontSettings.size))
                    .opacity(isLoading ? 0.4 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                Spacer()
                if isEditable, !text.isEmpty {
                    Button {
                        onClear?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Clear text")
                }

                Button {
                    copyToPasteboard()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(text.isEmpty)
                .help("Copy to clipboard")
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func copyToPasteboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

/// Thin `NSTextView` wrapper used for both panes. Compared to SwiftUI's
/// `TextEditor` this (a) stays selectable when `isEditable` is false, instead
/// of blocking selection like a disabled `TextEditor` would, and (b) hides
/// its scroll indicator until the content actually overflows the visible
/// area, regardless of the system's "always show scroll bars" preference.
private struct NativeTextView: NSViewRepresentable {
    @Binding var text: String
    var isEditable: Bool
    var font: NSFont

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textColor = .labelColor
        textView.font = font
        textView.string = text
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        textView.isEditable = isEditable
        textView.font = font
        if textView.string != text {
            textView.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}
