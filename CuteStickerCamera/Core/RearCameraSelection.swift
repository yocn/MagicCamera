import Foundation

enum RearCameraKind: CaseIterable, Hashable {
    case triple
    case dualWide
    case dual
    case wide
}

enum RearCameraSelection {
    static func preferred(from available: Set<RearCameraKind>) -> RearCameraKind? {
        RearCameraKind.allCases.first(where: available.contains)
    }
}
