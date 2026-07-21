import SwiftUI

@main
struct SoundGroveApp: App {
    @State private var groveGateReady: Bool? = nil
    private let groveSourceLink = "https://example.com"
    private let groveCheckDomain = "example"

    @StateObject private var store = GroveStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = groveGateReady {
                    if ready {
                        GroveWebPanel(urlString: groveSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else if !store.onboardingSeen {
                        OnboardingView {
                            withAnimation(.easeInOut(duration: 0.35)) { store.markOnboardingSeen() }
                        }
                        .environmentObject(store)
                        .preferredColorScheme(.dark)
                    } else {
                        RootView()
                            .environmentObject(store)
                            .preferredColorScheme(.dark)
                    }
                } else {
                    GroveLaunchScreen()
                        .preferredColorScheme(.dark)
                        .onAppear { checkGroveLink() }
                }
            }
        }
    }

    private func checkGroveLink() {
        guard let url = URL(string: groveSourceLink) else { groveGateReady = false; return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let watcher = GroveRedirectWatcher(checkDomain: groveCheckDomain)
        let session = URLSession(configuration: .default, delegate: watcher, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if watcher.foundCheckDomain { groveGateReady = false; return }
                if let finalURL = watcher.resolvedURL?.absoluteString, finalURL.contains(self.groveCheckDomain) {
                    groveGateReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse, let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.groveCheckDomain) { groveGateReady = false; return }
                if error != nil { groveGateReady = false; return }
                groveGateReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if groveGateReady == nil { groveGateReady = false }
        }
    }
}

final class GroveRedirectWatcher: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) { foundCheckDomain = true }
        resolvedURL = request.url
        completionHandler(request)
    }
}
