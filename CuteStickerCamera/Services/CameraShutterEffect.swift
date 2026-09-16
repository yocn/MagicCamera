import AudioToolbox

enum CameraShutterEffect {
    static func playSound() {
        AudioServicesPlaySystemSound(1108)
    }
}
