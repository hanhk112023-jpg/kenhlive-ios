import SwiftUI
import WebKit

struct VodWebPlayerView: View {
    let film: FilmItem
    let episode: EpisodeItem

    @Environment(\.dismiss) private var dismiss
    @State private var startTime: Date = Date()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NguoncWebView(embedUrl: episode.embed)
                .ignoresSafeArea()

            // Dismiss Header Bar
            VStack {
                HStack(alignment: .top) {
                    Button {
                        saveProgress()
                        dismiss()
                    } label: {
                        Text("ĐÓNG")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.70))
                            .cornerRadius(8)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(film.name)
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(episode.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(KLTheme.brandOrange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                Spacer()
            }
        }
        .onAppear {
            startTime = Date()
        }
        .onDisappear {
            saveProgress()
        }
    }

    private func saveProgress() {
        let watchedSeconds = Date().timeIntervalSince(startTime)
        let posMs = Int64(watchedSeconds * 1000)
        let estDurationMs: Int64 = 45 * 60 * 1000

        let progress = WatchProgress(
            filmSlug: film.slug,
            filmName: film.name,
            posterUrl: film.posterUrl.isEmpty ? film.thumbUrl : film.posterUrl,
            episodeName: episode.name,
            episodeSlug: episode.slug,
            embedUrl: episode.embed,
            positionMs: posMs,
            durationMs: estDurationMs,
            updatedAt: Date()
        )
        StorageManager.shared.saveWatchProgress(progress)
    }
}

// MARK: - Native WebKit Embed with Custom Referer
private struct NguoncWebView: UIViewRepresentable {
    let embedUrl: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        if let url = URL(string: embedUrl) {
            var req = URLRequest(url: url)
            req.setValue("https://phim.nguonc.com/", forHTTPHeaderField: "Referer")
            req.setValue("https://phim.nguonc.com", forHTTPHeaderField: "Origin")
            webView.load(req)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }
}
