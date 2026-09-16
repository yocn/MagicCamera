import Photos
import UIKit

enum PhotoLibrarySaverError: LocalizedError {
    case denied
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .denied: "需要允许添加照片，才能保存拍摄结果。"
        case .saveFailed: "照片保存失败，请再试一次。"
        }
    }
}

struct PhotoLibrarySaver {
    func save(_ image: UIImage) async throws {
        let status = await requestAuthorizationIfNeeded()
        guard status == .authorized || status == .limited else { throw PhotoLibrarySaverError.denied }
        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                success ? continuation.resume() : continuation.resume(throwing: error ?? PhotoLibrarySaverError.saveFailed)
            }
        }
    }

    private func requestAuthorizationIfNeeded() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard current == .notDetermined else { return current }
        return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
}
