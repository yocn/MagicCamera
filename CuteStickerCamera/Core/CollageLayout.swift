import CoreGraphics
import Foundation

public enum CollageLayout: String, CaseIterable, Identifiable, Sendable {
    case fourGrid
    case twoOverOne
    case oneOverTwo
    case verticalFour
    case verticalThree
    case bigLeft
    case twoRows
    case sixGrid
    case nineGrid

    /// 合成画布宽度，高度由 aspectRatio 推出。
    public static let canvasWidth: CGFloat = 1440

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .fourGrid: "四宫格"
        case .twoOverOne: "上二下一"
        case .oneOverTwo: "上一下二"
        case .verticalFour: "竖排四格"
        case .verticalThree: "竖排三格"
        case .bigLeft: "左大右二"
        case .twoRows: "上下二格"
        case .sixGrid: "六宫格"
        case .nineGrid: "九宫格"
        }
    }

    /// 画布宽 ÷ 画布高。
    public var aspectRatio: CGFloat {
        switch self {
        case .fourGrid, .twoOverOne, .oneOverTwo, .bigLeft, .nineGrid: 1
        case .verticalFour: 1.0 / 3.0
        case .verticalThree: 1.0 / 2.25
        case .twoRows, .sixGrid: 1.0 / 1.5
        }
    }

    public var cells: [CGRect] {
        switch self {
        case .fourGrid:
            Self.grid(columns: 2, rows: 2)
        case .twoOverOne:
            [
                CGRect(x: 0, y: 0, width: 0.5, height: 0.5),
                CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
                CGRect(x: 0, y: 0.5, width: 1, height: 0.5)
            ]
        case .oneOverTwo:
            [
                CGRect(x: 0, y: 0, width: 1, height: 0.5),
                CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5),
                CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
            ]
        case .verticalFour:
            Self.grid(columns: 1, rows: 4)
        case .verticalThree:
            Self.grid(columns: 1, rows: 3)
        case .bigLeft:
            [
                CGRect(x: 0, y: 0, width: 0.62, height: 1),
                CGRect(x: 0.62, y: 0, width: 0.38, height: 0.5),
                CGRect(x: 0.62, y: 0.5, width: 0.38, height: 0.5)
            ]
        case .twoRows:
            Self.grid(columns: 1, rows: 2)
        case .sixGrid:
            Self.grid(columns: 2, rows: 3)
        case .nineGrid:
            Self.grid(columns: 3, rows: 3)
        }
    }

    public var shotCount: Int { cells.count }

    public func canvasSize(width: CGFloat = CollageLayout.canvasWidth) -> CGSize {
        CGSize(width: width, height: width / aspectRatio)
    }

    private static func grid(columns: Int, rows: Int) -> [CGRect] {
        let width = 1 / CGFloat(columns)
        let height = 1 / CGFloat(rows)
        return (0..<rows).flatMap { row in
            (0..<columns).map { column in
                CGRect(
                    x: CGFloat(column) * width,
                    y: CGFloat(row) * height,
                    width: width,
                    height: height
                )
            }
        }
    }
}
