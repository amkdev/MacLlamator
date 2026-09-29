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
    var placeholder: String
    var isLoading: Bool = false
    var onClear: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // A plain NSTextView-backed view instead of SwiftUI's TextEditor:
            // it stays selectable/copyable even when read-only (a disabled
            // TextEditor blocks selection entirely), lets us hide the scroll
            // indicator until the text actually overflows, instead of always
            // showing it per the system's scroll bar preference, and draws
            // its own placeholder so that placeholder and text share one
            // layout rather than two that have to be kept in step.
            NativeTextView(
                text: $text,
                isEditable: isEditable,
                placeholder: placeholder,
                font: .systemFont(ofSize: fontSettings.size),
                lineSpacing: fontSettings.lineSpacing
            )
            .opacity(isLoading ? 0.4 : 1)
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
    var placeholder: String
    var font: NSFont
    var lineSpacing: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PlaceholderTextView()
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textColor = .labelColor
        textView.string = text
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        applyTypography(to: textView)

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? PlaceholderTextView else { return }
        textView.isEditable = isEditable
        if textView.string != text {
            textView.string = text
            // Setting the text programmatically — clearing the source pane,
            // or filling the result pane — is what makes the placeholder
            // appear or vanish, and AppKit does not know that.
            textView.needsDisplay = true
        }
        applyTypography(to: textView)
    }

    /// Font, line spacing and placeholder in one place, because they have to
    /// agree: the placeholder is drawn with the same paragraph style the text
    /// is laid out with. Re-applied to the text already on screen rather than
    /// only to `typingAttributes`, so Cmd+Plus resizes what is there instead
    /// of just what gets typed next.
    private func applyTypography(to textView: PlaceholderTextView) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        textView.font = font
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.labelColor,
        ]

        if let storage = textView.textStorage, storage.length > 0 {
            storage.addAttributes(
                [.font: font, .paragraphStyle: paragraphStyle],
                range: NSRange(location: 0, length: storage.length)
            )
        }

        textView.placeholder = placeholder
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

/// An `NSTextView` that draws its own placeholder.
///
/// The placeholder used to be a SwiftUI `Text` floating above the text view,
/// which meant guessing where the layout manager would put the first line.
/// The guess was eight points of top padding, and it showed: the placeholder
/// sat visibly lower than the text that replaced it. Drawing it here instead
/// uses the text view's own container origin, line fragment padding, font and
/// paragraph style, so the two line up by construction — at every font size,
/// rather than at the single one the padding happened to be tuned for.
private final class PlaceholderTextView: NSTextView {
    var placeholder: String = "" {
        didSet {
            if placeholder != oldValue { needsDisplay = true }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard string.isEmpty, !placeholder.isEmpty, let font else { return }

        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]
        if let paragraphStyle = defaultParagraphStyle {
            attributes[.paragraphStyle] = paragraphStyle
        }

        // The same origin the layout manager uses for the first line: the
        // container's own origin plus the padding the text container keeps
        // on either side of every line fragment.
        let origin = NSPoint(
            x: textContainerOrigin.x + (textContainer?.lineFragmentPadding ?? 0),
            y: textContainerOrigin.y
        )
        NSAttributedString(string: placeholder, attributes: attributes).draw(at: origin)
    }

    /// The placeholder appears and disappears as the field empties and
    /// fills, which is not a change AppKit would redraw for on its own.
    override func didChangeText() {
        super.didChangeText()
        needsDisplay = true
    }
}
