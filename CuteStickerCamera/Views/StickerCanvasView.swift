import SwiftUI
import UIKit

struct StickerCanvasView: UIViewRepresentable {
    @ObservedObject var canvas: StickerCanvas
    let previewSize: CGSize
    var passthroughRect: CGRect = .null

    func makeCoordinator() -> Coordinator {
        Coordinator(canvas: canvas)
    }

    func makeUIView(context: Context) -> StickerCanvasUIKitView {
        let view = StickerCanvasUIKitView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: StickerCanvasUIKitView, context: Context) {
        uiView.coordinator = context.coordinator
        uiView.passthroughRect = passthroughRect
        uiView.sync(layers: canvas.layers, selectedLayerID: canvas.selectedLayerID)
    }

    final class Coordinator {
        let canvas: StickerCanvas

        init(canvas: StickerCanvas) {
            self.canvas = canvas
        }

        func update(_ layer: StickerLayer) {
            canvas.update(layer)
        }

        func remove(id: UUID) {
            canvas.remove(id: id)
        }

        func select(id: UUID) {
            canvas.select(id: id)
        }

        func deselect() {
            canvas.deselect()
        }
    }
}

final class StickerCanvasUIKitView: UIView, UIGestureRecognizerDelegate {
    var passthroughRect: CGRect = .null

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard super.point(inside: point, with: event) else { return false }
        // Stickers (including their handles) remain editable when placed over the small window.
        if hosts.values.contains(where: { host in
            host.point(inside: host.convert(point, from: self), with: event)
        }) { return true }
        return !passthroughRect.contains(point)
    }
    weak var coordinator: StickerCanvasView.Coordinator?
    private var hosts: [UUID: StickerHostView] = [:]
    private var layers: [StickerLayer] = []
    private var selectedLayerID: UUID?
    private lazy var backgroundTap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundTap.delegate = self
        backgroundTap.cancelsTouchesInView = false
        addGestureRecognizer(backgroundTap)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyLayers()
    }

    func sync(layers: [StickerLayer], selectedLayerID: UUID?) {
        self.layers = layers
        self.selectedLayerID = selectedLayerID
        applyLayers()
    }

    private func applyLayers() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let ids = Set(layers.map(\.id))

        for (id, host) in hosts where !ids.contains(id) {
            host.removeFromSuperview()
            hosts[id] = nil
        }

        for layer in layers {
            let host: StickerHostView
            if let existing = hosts[layer.id] {
                host = existing
            } else {
                host = StickerHostView(layer: layer)
                host.onSelect = { [weak self, weak host] in
                    guard let self, let host else { return }
                    self.coordinator?.select(id: host.stickerLayer.id)
                }
                host.onUpdate = { [weak self] layer in
                    self?.coordinator?.update(layer)
                }
                host.onDelete = { [weak self] id in
                    self?.coordinator?.remove(id: id)
                }
                addSubview(host)
                hosts[layer.id] = host
            }

            host.isSelected = layer.id == selectedLayerID
            if !host.isInteracting {
                host.apply(layer: layer, canvasSize: bounds.size)
            }
        }
    }

    @objc private func backgroundTapped() {
        coordinator?.deselect()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === backgroundTap, let view = touch.view else { return true }
        return !hosts.values.contains { view === $0 || view.isDescendant(of: $0) }
    }
}

private final class StickerHostView: UIView, UIGestureRecognizerDelegate {
    private(set) var stickerLayer: StickerLayer
    private let contentContainer = UIView()
    private let imageView = UIImageView()
    private let selectionBorder = CAShapeLayer()
    private let deleteButton = CandyHandleButton(type: .system)
    private let rotationHandle = CandyHandleButton(type: .system)
    private let scaleHandle = CandyHandleButton(type: .system)
    private let handleInset: CGFloat = 20
    private let handleSize: CGFloat = 38
    private var canvasSize = CGSize.zero
    private var panStartCenter = CGPoint.zero
    private var pinchStartScale: CGFloat = 1
    private var rotationStart: CGFloat = 0
    private var handleStartAngle: CGFloat = 0
    private var handleStartDistance: CGFloat = 1
    private lazy var selectionTap = UITapGestureRecognizer(target: self, action: #selector(tapped))

    var onSelect: (() -> Void)?
    var onUpdate: ((StickerLayer) -> Void)?
    var onDelete: ((UUID) -> Void)?
    var isInteracting = false

    var isSelected = false {
        didSet {
            selectionBorder.isHidden = !isSelected
            deleteButton.isHidden = !isSelected
            rotationHandle.isHidden = !isSelected
            scaleHandle.isHidden = !isSelected
        }
    }

    init(layer: StickerLayer) {
        stickerLayer = layer
        super.init(frame: .zero)

        isUserInteractionEnabled = true
        clipsToBounds = false

        contentContainer.clipsToBounds = false
        addSubview(contentContainer)

        imageView.contentMode = .scaleAspectFit
        imageView.image = StickerImageProvider.image(named: layer.assetName)
        imageView.isUserInteractionEnabled = false
        contentContainer.addSubview(imageView)

        selectionBorder.strokeColor = UIColor.white.cgColor
        selectionBorder.fillColor = UIColor.clear.cgColor
        selectionBorder.lineWidth = 3
        selectionBorder.lineDashPattern = [7, 5]
        selectionBorder.shadowColor = UIColor.black.cgColor
        selectionBorder.shadowOpacity = 0.25
        selectionBorder.shadowRadius = 2
        self.layer.addSublayer(selectionBorder)

        deleteButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        deleteButton.tintColor = .white
        deleteButton.backgroundColor = .clear
        deleteButton.layer.cornerRadius = 13
        deleteButton.layer.shadowColor = UIColor.black.cgColor
        deleteButton.layer.shadowOpacity = 0.14
        deleteButton.layer.shadowRadius = 3
        deleteButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        addSubview(deleteButton)

        configureHandle(rotationHandle, imageName: "arrow.triangle.2.circlepath", label: "旋转贴纸")
        configureHandle(scaleHandle, imageName: "arrow.up.left.and.arrow.down.right.circle", label: "缩放贴纸")
        applyButtonStyle(rotationHandle)
        applyButtonStyle(scaleHandle)
        addSubview(rotationHandle)
        addSubview(scaleHandle)

        selectionTap.delegate = self
        addGestureRecognizer(selectionTap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinched(_:)))
        pinch.delegate = self
        addGestureRecognizer(pinch)
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(rotated(_:)))
        rotation.delegate = self
        addGestureRecognizer(rotation)

        rotationHandle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(rotatedByHandle(_:))))
        scaleHandle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(scaledByHandle(_:))))

        isSelected = false
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentContainer.frame = contentRect
        imageView.frame = contentContainer.bounds
        selectionBorder.frame = bounds
        selectionBorder.path = UIBezierPath(roundedRect: contentRect.insetBy(dx: 2, dy: 2), cornerRadius: 14).cgPath
        positionHandles()
    }

    func apply(layer: StickerLayer, canvasSize: CGSize) {
        transform = .identity
        contentContainer.transform = .identity
        deleteButton.transform = .identity
        rotationHandle.transform = .identity
        scaleHandle.transform = .identity
        stickerLayer = layer
        self.canvasSize = canvasSize
        imageView.image = StickerImageProvider.image(named: layer.assetName)

        let side = min(canvasSize.width, canvasSize.height) * layer.scale
        bounds.size = CGSize(width: side + handleInset * 2, height: side + handleInset * 2)
        center = CGPoint(x: layer.center.x * canvasSize.width, y: layer.center.y * canvasSize.height)
        setNeedsLayout()
        layoutIfNeeded()
        applyVisualTransform(scale: 1, rotation: 0)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === selectionTap || isSelected
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else { return true }
        let controls = [deleteButton, rotationHandle, scaleHandle]
        return !controls.contains { view === $0 || view.isDescendant(of: $0) }
    }

    @objc private func tapped() {
        onSelect?()
    }

    @objc private func deleteTapped() {
        onDelete?(stickerLayer.id)
    }

    @objc private func panned(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            isInteracting = true
            panStartCenter = center
            onSelect?()
        case .changed:
            let translation = gesture.translation(in: superview)
            center = CGPoint(x: panStartCenter.x + translation.x, y: panStartCenter.y + translation.y)
        case .ended, .cancelled, .failed:
            isInteracting = false
            let translation = gesture.translation(in: superview)
            onUpdate?(stickerLayer.moved(
                by: CGSize(width: translation.x, height: translation.y),
                in: canvasSize
            ))
        default:
            break
        }
    }

    @objc private func pinched(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isInteracting = true
            pinchStartScale = stickerLayer.scale
            onSelect?()
        case .changed:
            applyVisualTransform(scale: gesture.scale, rotation: 0)
        case .ended, .cancelled, .failed:
            isInteracting = false
            var updated = stickerLayer
            updated.scale = min(0.8, max(0.08, pinchStartScale * gesture.scale))
            onUpdate?(updated)
        default:
            break
        }
    }

    @objc private func rotated(_ gesture: UIRotationGestureRecognizer) {
        switch gesture.state {
        case .began:
            isInteracting = true
            rotationStart = stickerLayer.rotation
            onSelect?()
        case .changed:
            applyVisualTransform(scale: 1, rotation: gesture.rotation)
        case .ended, .cancelled, .failed:
            isInteracting = false
            var updated = stickerLayer
            updated.rotation = rotationStart + gesture.rotation
            onUpdate?(updated)
        default:
            break
        }
    }

    private func applyVisualTransform(scale: CGFloat, rotation: CGFloat) {
        transform = .identity
        contentContainer.transform = .identity
        deleteButton.transform = .identity
        rotationHandle.transform = .identity
        scaleHandle.transform = .identity
        let side = min(canvasSize.width, canvasSize.height) * stickerLayer.scale * scale
        bounds.size = CGSize(width: side + handleInset * 2, height: side + handleInset * 2)
        setNeedsLayout()
        layoutIfNeeded()
        let selectionTransform = CGAffineTransform(rotationAngle: stickerLayer.rotation + rotation)
        transform = selectionTransform
    }

    private var contentRect: CGRect {
        bounds.insetBy(dx: handleInset, dy: handleInset)
    }

    private func positionHandles() {
        position(deleteButton, at: CGPoint(x: contentRect.maxX, y: contentRect.minY))
        position(rotationHandle, at: CGPoint(x: contentRect.minX, y: contentRect.maxY))
        position(scaleHandle, at: CGPoint(x: contentRect.maxX, y: contentRect.maxY))
    }

    private func position(_ button: UIButton, at point: CGPoint) {
        button.bounds = CGRect(x: 0, y: 0, width: handleSize, height: handleSize)
        button.center = point
    }

    private func configureHandle(_ handle: UIButton, imageName: String, label: String) {
        handle.setImage(UIImage(systemName: imageName), for: .normal)
        handle.accessibilityLabel = label
        handle.tintColor = .systemPink
        handle.backgroundColor = .white
        handle.layer.cornerRadius = 13
        handle.layer.shadowColor = UIColor.black.cgColor
        handle.layer.shadowOpacity = 0.14
        handle.layer.shadowRadius = 3
        handle.layer.shadowOffset = CGSize(width: 0, height: 1)
    }

    private func applyButtonStyle(_ handle: UIButton) {
        handle.tintColor = .white
        handle.backgroundColor = .clear
    }

    @objc private func rotatedByHandle(_ gesture: UIPanGestureRecognizer) {
        let angle = angleToGesture(gesture)

        switch gesture.state {
        case .began:
            isInteracting = true
            rotationStart = stickerLayer.rotation
            handleStartAngle = angle
            onSelect?()
        case .changed:
            applyVisualTransform(scale: 1, rotation: normalizedAngle(angle - handleStartAngle))
        case .ended, .cancelled, .failed:
            isInteracting = false
            onUpdate?(stickerLayer.rotated(by: normalizedAngle(angle - handleStartAngle)))
        default:
            break
        }
    }

    @objc private func scaledByHandle(_ gesture: UIPanGestureRecognizer) {
        let distance = distanceToGesture(gesture)

        switch gesture.state {
        case .began:
            isInteracting = true
            handleStartDistance = max(distance, 1)
            onSelect?()
        case .changed:
            let scaleFactor = distance / handleStartDistance
            applyVisualTransform(scale: scaleFactor, rotation: 0)
            onUpdate?(stickerLayer.scaled(by: scaleFactor))
        case .ended, .cancelled, .failed:
            isInteracting = false
            onUpdate?(stickerLayer.scaled(by: distance / handleStartDistance))
        default:
            break
        }
    }

    private func angleToGesture(_ gesture: UIPanGestureRecognizer) -> CGFloat {
        let point = gesture.location(in: superview)
        return atan2(point.y - center.y, point.x - center.x)
    }

    private func distanceToGesture(_ gesture: UIPanGestureRecognizer) -> CGFloat {
        let point = gesture.location(in: superview)
        return hypot(point.x - center.x, point.y - center.y)
    }

    private func normalizedAngle(_ angle: CGFloat) -> CGFloat {
        atan2(sin(angle), cos(angle))
    }
}

private final class CandyHandleButton: UIButton {
    private let candyLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(candyLayer, at: 0)
        candyLayer.fillColor = UIColor.systemPink.cgColor
        candyLayer.zPosition = -1
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = min(bounds.width, bounds.height)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let lobeRadius = size * 0.27
        let orbitRadius = size * 0.25
        let path = UIBezierPath()

        for index in 0..<6 {
            let angle = CGFloat(index) * .pi / 3
            let lobeCenter = CGPoint(
                x: center.x + cos(angle) * orbitRadius,
                y: center.y + sin(angle) * orbitRadius
            )
            path.append(UIBezierPath(
                ovalIn: CGRect(
                    x: lobeCenter.x - lobeRadius,
                    y: lobeCenter.y - lobeRadius,
                    width: lobeRadius * 2,
                    height: lobeRadius * 2
                )
            ))
        }

        candyLayer.frame = bounds
        candyLayer.path = path.cgPath
        layer.cornerRadius = 0
        layer.shadowPath = path.cgPath
    }
}
