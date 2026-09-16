import Combine
import Foundation

public final class StickerCanvas: ObservableObject {
    @Published public private(set) var layers: [StickerLayer]
    @Published public private(set) var selectedLayerID: UUID?
    private var undoStack: [CanvasOperation] = []

    public init(layers: [StickerLayer] = []) {
        self.layers = layers
    }

    @discardableResult
    public func add(assetName: String) -> StickerLayer {
        let layer = StickerLayer(assetName: assetName)
        layers.append(layer)
        selectedLayerID = layer.id
        undoStack.append(.added(layer.id))
        return layer
    }

    public func remove(id: UUID) {
        guard let index = layers.firstIndex(where: { $0.id == id }) else { return }
        undoStack.append(.removed(layers.remove(at: index), index: index))
        if selectedLayerID == id {
            selectedLayerID = nil
        }
    }

    public func select(id: UUID) {
        guard layers.contains(where: { $0.id == id }) else { return }
        selectedLayerID = id
    }

    public func deselect() {
        selectedLayerID = nil
    }

    public func update(_ layer: StickerLayer) {
        guard let index = layers.firstIndex(where: { $0.id == layer.id }) else { return }
        layers[index] = layer
    }

    public func undo() {
        guard let operation = undoStack.popLast() else { return }
        switch operation {
        case .added(let id):
            layers.removeAll { $0.id == id }
        case .removed(let layer, let index):
            layers.insert(layer, at: min(index, layers.endIndex))
        }
    }
}

private enum CanvasOperation {
    case added(UUID)
    case removed(StickerLayer, index: Int)
}
