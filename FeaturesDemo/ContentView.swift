import SwiftUI

class ContentSource: ObservableObject {
    let log = LoggerFactory.shared.vc(ContentSource.self)
    let source = ImageSource.shared
    let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/3/30/%D7%A2%D7%A5_%D7%A2%D7%9C_%D7%90%D7%99_%D7%9E%D7%9C%D7%97_%D7%91%D7%90%D7%9E%D7%A6%D7%A2_%D7%99%D7%9D_%D7%94%D7%9E%D7%9C%D7%97.jpg")!
    
    @Published var imageData: Data? = nil
    @Published var openUrl: URL? = nil
    
    func load() {
        Task {
            await loadImage()
        }
    }
    
    func loadImage() async {
        await update(data: await source.loadImage())
    }
    
    @MainActor
    func opened(from url: URL) {
        openUrl = url
    }
    
    @MainActor
    func update(data: Data?) {
        self.imageData = data
    }
}

struct ContentView: View {
    let log = LoggerFactory.shared.view(ContentView.self)
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var contentSource: ContentSource
    
    let interval = Date.now...Date().addingTimeInterval(10)
    let activities = Activities.shared
    
    var body: some View {
        VStack {
            Text(timerInterval: interval, countsDown: false)
            Button("Start live activity") {
                Task {
                    try? await activities.start()
                }
            }.padding()
            Button("End live activities") {
                Task {
                    await activities.endAll()
                }
            }.padding()
            if let openUrl = contentSource.openUrl {
                Text("Opened from \(openUrl).")
            }
            Group {
                if let imageData = contentSource.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                else {
                    Text("Loading...")
                }
            }
        }
        .padding()
        .onAppear {
            log.info("Content appears.")
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                log.info("Active scene.")
                contentSource.load()
            }
            if phase == .inactive {
                log.info("Inactive scene.")
            }
            if phase == .background {
                log.info("Background scene.")
            }
        }
        .onOpenURL { url in
            contentSource.opened(from: url)
            log.info("Open URL \(url).")
            if url == FeatureConstants.shared.widgetUrl {
                log.info("Opened from Widget!")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(contentSource: ContentSource())
    }
}
