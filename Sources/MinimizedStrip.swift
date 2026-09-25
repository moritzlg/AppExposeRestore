import AppKit

final class MinimizedStrip: NSObject {
    private var panel: NSPanel?
    private var windows: [MinimizedWindow] = []
    private var raiseOnRestore = true
    private var previewTask: Task<Void, Never>?
    private var previewViews: [Int: NSImageView] = [:]
    private var previewRequests: [Int: WindowPreviewRequest] = [:]
    private var previewQueue: [WindowPreviewRequest] = []
    private var requestedPreviews: Set<Int> = []
    private var scrollObserver: NSObjectProtocol?
    private weak var previewScroll: NSScrollView?
    private var previewLeftInset: CGFloat = 0
    private var generation = 0
    var onRestore: ((Bool) -> Void)?
    var onClose: (() -> Void)?
    var onBeforeAutomaticRestore: (() -> Void)?
    var onDeferredRaise: ((MinimizedWindow) -> Void)?

    var isVisible: Bool { panel?.isVisible == true }

    func show(_ windows: [MinimizedWindow], appName: String, raiseOnRestore: Bool,
              showsPreviews: Bool) {
        guard !windows.isEmpty else { hide(); return }
        hide()
        self.windows = windows
        self.raiseOnRestore = raiseOnRestore
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        guard let screen else { return }

        let cardPitch: CGFloat = 216
        let width = min(screen.visibleFrame.width - 64, max(330, CGFloat(windows.count) * cardPitch + 32))
        let frame = NSRect(x: screen.visibleFrame.midX - width / 2,
                           y: screen.visibleFrame.minY + 20,
                           width: width,
                           height: 212)
        let newPanel = NSPanel(contentRect: frame,
                               styleMask: [.borderless, .nonactivatingPanel],
                               backing: .buffered,
                               defer: false)
        newPanel.level = .screenSaver
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.hidesOnDeactivate = false

        let appearance = StripAppearance.stripBackground(size: frame.size)
        let background = appearance.content

        let heading = NSTextField(labelWithString: "Minimierte Fenster · \(appName)")
        heading.font = .systemFont(ofSize: 13, weight: .semibold)
        heading.textColor = .secondaryLabelColor
        heading.frame = NSRect(x: 18, y: 178, width: width - 72, height: 20)
        background.addSubview(heading)

        let closeButton = NSButton(title: "✕", target: self, action: #selector(closeClicked))
        closeButton.isBordered = false
        closeButton.frame = NSRect(x: width - 42, y: 174, width: 26, height: 26)
        background.addSubview(closeButton)

        let scroll = NSScrollView(frame: NSRect(x: 16, y: 12, width: width - 32, height: 150))
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = CGFloat(windows.count) * cardPitch > width - 32
        scroll.hasVerticalScroller = false
        scroll.autohidesScrollers = true
        let rowWidth = max(width - 32, CGFloat(windows.count) * cardPitch)
        let row = NSView(frame: NSRect(x: 0, y: 0, width: rowWidth, height: 146))
        let leftInset = max(0, (rowWidth - CGFloat(windows.count) * cardPitch) / 2)
        previewLeftInset = leftInset
        for (index, window) in windows.enumerated() {
            let card = StripAppearance.cardBackground(size: NSSize(width: 208, height: 144))
            card.root.frame.origin = NSPoint(x: leftInset + CGFloat(index) * cardPitch, y: 0)

            let preview = NSImageView(frame: NSRect(x: 8, y: 30, width: 192, height: 106))
            preview.image = window.application.icon
            preview.imageScaling = .scaleProportionallyDown
            preview.wantsLayer = true
            preview.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor
            preview.layer?.cornerRadius = 5
            preview.layer?.masksToBounds = true
            card.content.addSubview(preview)
            previewViews[index] = preview

            let title = NSTextField(labelWithString: window.title)
            title.font = .systemFont(ofSize: 11)
            title.alignment = .center
            title.lineBreakMode = .byTruncatingMiddle
            title.frame = NSRect(x: 6, y: 5, width: 196, height: 18)
            card.content.addSubview(title)

            let button = NSButton(frame: card.content.bounds)
            button.title = ""
            button.isBordered = false
            button.isTransparent = true
            button.lineBreakMode = .byTruncatingMiddle
            button.tag = index
            button.target = self
            button.action = #selector(windowClicked(_:))
            _ = button.sendAction(on: .leftMouseDown)
            button.toolTip = window.title
            button.setAccessibilityLabel("Fenster wiederherstellen: \(window.title)")
            card.content.addSubview(button)
            row.addSubview(card.root)
        }
        scroll.documentView = row
        background.addSubview(scroll)
        newPanel.contentView = appearance.root
        newPanel.invalidateShadow()

        panel = newPanel
        newPanel.orderFrontRegardless()

        if showsPreviews && WindowPreviewCapture.isAuthorized {
            previewRequests = Dictionary(uniqueKeysWithValues: windows.enumerated().compactMap { index, window in
                guard let frame = window.frame else { return nil }
                return (index, WindowPreviewRequest(index: index,
                                                    processID: window.application.processIdentifier,
                                                    frame: frame, title: window.title))
            })
            previewScroll = scroll
            scroll.contentView.postsBoundsChangedNotifications = true
            scrollObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification, object: scroll.contentView, queue: .main
            ) { [weak self] _ in self?.queueVisiblePreviews() }
            queueVisiblePreviews()
        }
    }

    private func queueVisiblePreviews() {
        guard let scroll = previewScroll, !previewRequests.isEmpty else { return }
        let indices = PreviewViewport.indices(total: windows.count, pitch: 216,
                                              leftInset: previewLeftInset,
                                              visible: scroll.contentView.bounds)
        for index in indices where !requestedPreviews.contains(index) {
            guard let request = previewRequests[index] else { continue }
            requestedPreviews.insert(index)
            previewQueue.append(request)
        }
        if previewQueue.count > 12 {
            for discarded in previewQueue.dropLast(12) { requestedPreviews.remove(discarded.index) }
            previewQueue = Array(previewQueue.suffix(12))
        }
        startNextPreviewBatch()
    }

    private func startNextPreviewBatch() {
        guard previewTask == nil, !previewQueue.isEmpty else { return }
        let batch = Array(previewQueue.prefix(8))
        previewQueue.removeFirst(batch.count)
        let currentGeneration = generation
        previewTask = WindowPreviewCapture.start(requests: batch, onImage: { [weak self] index, image in
            guard let self, self.generation == currentGeneration else { return }
            self.previewViews[index]?.image = NSImage(cgImage: image,
                                                       size: NSSize(width: image.width, height: image.height))
            self.previewViews[index]?.imageScaling = .scaleProportionallyUpOrDown
        }, onFinished: { [weak self] in
            guard let self, self.generation == currentGeneration else { return }
            self.previewTask = nil
            self.startNextPreviewBatch()
        })
    }

    func hide() {
        generation += 1
        if let scrollObserver { NotificationCenter.default.removeObserver(scrollObserver) }
        scrollObserver = nil
        previewScroll = nil
        previewTask?.cancel()
        previewTask = nil
        previewRequests = [:]
        previewQueue = []
        requestedPreviews = []
        panel?.close()
        panel = nil
        windows = []
        previewViews = [:]
    }

    @objc private func closeClicked() { hide(); onClose?() }

    @objc private func windowClicked(_ sender: NSButton) {
        guard windows.indices.contains(sender.tag) else { return }
        RestoreTrace.mark("card action")
        let selected = windows[sender.tag]
        let shouldRaise = raiseOnRestore
        hide()
        RestoreTrace.mark("panel closed")
        if !shouldRaise { onBeforeAutomaticRestore?() }
        // Let AppKit flush the panel dismissal before the system's window-raise
        // animation blocks this event handler.
        DispatchQueue.main.async { [weak self] in
            RestoreTrace.mark("restore started")
            let restored = AccessibilityWindows.restore(selected, raise: shouldRaise)
            RestoreTrace.mark("restore returned")
            if restored && !shouldRaise { self?.onDeferredRaise?(selected) }
            self?.onRestore?(restored)
        }
    }
}
