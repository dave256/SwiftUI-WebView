import SwiftUI
import Combine
import WebKit

@available(iOS 13.0, *)
public class WebViewStore: ObservableObject {
  @Published public var webView: WKWebView {
    didSet {
      setupObservers()
    }
  }
  
  public init(webView: WKWebView = WKWebView()) {
    self.webView = webView
    setupObservers()
  }
  
  private func setupObservers() {
    func subscriber<Value>(for keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
      return webView.observe(keyPath, options: [.prior]) { _, change in
        if change.isPrior {
          self.objectWillChange.send()
        }
      }
    }
    // Setup observers for all KVO compliant properties
    observers = [
      subscriber(for: \.title),
      subscriber(for: \.url),
      subscriber(for: \.isLoading),
      subscriber(for: \.estimatedProgress),
      subscriber(for: \.hasOnlySecureContent),
      subscriber(for: \.serverTrust),
      subscriber(for: \.canGoBack),
      subscriber(for: \.canGoForward)
    ]
  }
  
  private var observers: [NSKeyValueObservation] = []
  
  deinit {
    observers.forEach {
      // Not even sure if this is required?
      // Probably wont be needed in future betas?
      $0.invalidate()
    }
  }
}

/// A container for using a WKWebView in SwiftUI
@available(iOS 13.0, *)
public struct WebView: View, UIViewRepresentable {
  /// The WKWebView to display
  public let webView: WKWebView
  
  public typealias UIViewType = UIViewContainerView<WKWebView>
  
  public init(webView: WKWebView) {
    self.webView = webView
  }
  
  public func makeUIView(context: UIViewRepresentableContext<WebView>) -> WebView.UIViewType {
    return UIViewContainerView()
  }
  
  public func updateUIView(_ uiView: WebView.UIViewType, context: UIViewRepresentableContext<WebView>) {
    // If its the same content view we don't need to update.
    if uiView.contentView !== webView {
      uiView.contentView = webView
    }
  }
}

/// A UIView which simply adds some view to its view hierarchy
@available(iOS 13.0, *)
public class UIViewContainerView<ContentView: UIView>: UIView {
  var contentView: ContentView? {
    willSet {
      contentView?.removeFromSuperview()
    }
    didSet {
      if let contentView = contentView {
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
          contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
          contentView.topAnchor.constraint(equalTo: topAnchor),
          contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
      }
    }
  }
}
