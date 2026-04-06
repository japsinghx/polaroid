import AVFoundation
import AudioToolbox

@MainActor
@Observable
final class SoundManager {
    // System sound IDs
    // 1108 = camera shutter (same sound iPhone Camera app uses)
    // 1103 = short beep (used as print eject)
    private let shutterSoundID: SystemSoundID = 1108
    private let ejectSoundID: SystemSoundID = 1103

    func prepare() {
        // Configure audio session to play alongside other audio
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playShutter() {
        AudioServicesPlaySystemSound(shutterSoundID)
    }

    func playPrintEject() {
        AudioServicesPlaySystemSound(ejectSoundID)
    }
}
