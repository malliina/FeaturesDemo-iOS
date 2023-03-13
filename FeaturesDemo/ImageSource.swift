import Foundation

class ImageSource {
    static let shared = ImageSource()
    let log = LoggerFactory.shared.vc(ImageSource.self)
    let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/3/30/%D7%A2%D7%A5_%D7%A2%D7%9C_%D7%90%D7%99_%D7%9E%D7%9C%D7%97_%D7%91%D7%90%D7%9E%D7%A6%D7%A2_%D7%99%D7%9D_%D7%94%D7%9E%D7%9C%D7%97.jpg")!
    let sharkUrl = URL(string: "https://upload.wikimedia.org/wikipedia/commons/5/56/White_shark.jpg")!
    func loadImage() async -> Data? {
        await loadImage(from: url)
    }
    
    func loadImage(from: URL) async -> Data? {
        do {
            log.info("Downloading \(url)...")
            let (data, _) = try await URLSession.shared.data(from: url)
            log.info("Download of \(url) complete.")
            return data
        } catch {
            log.error("Download of \(url) failed. \(error)")
            return nil
        }
    }
}
