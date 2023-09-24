import SwiftUI
import AppKit

protocol AppKitTouchesViewDelegate: AnyObject {
    func touchesView(_ view: AppKitTouchesView, didUpdateTouchingTouches touches: Set<NSTouch>)
}

final class AppKitTouchesView: NSView {
    weak var delegate: AppKitTouchesViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        allowedTouchTypes = [.indirect]
        wantsRestingTouches = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func handleTouches(with event: NSEvent) {
        let touches = event.touches(matching: .touching, in: self)
        delegate?.touchesView(self, didUpdateTouchingTouches: touches)
    }

    override func touchesBegan(with event: NSEvent) {
        handleTouches(with: event)
    }

    override func touchesEnded(with event: NSEvent) {
        handleTouches(with: event)
    }

    override func touchesMoved(with event: NSEvent) {
        handleTouches(with: event)
    }

    override func touchesCancelled(with event: NSEvent) {
        handleTouches(with: event)
    }
}

struct Touch: Identifiable {
    let id: Int
    let normalizedX: CGFloat
    let normalizedY: CGFloat

    init(_ nsTouch: NSTouch) {
        normalizedX = nsTouch.normalizedPosition.x
        normalizedY = 1.0 - nsTouch.normalizedPosition.y
        id = nsTouch.hash
    }
}

struct TouchesView: NSViewRepresentable {
    @Binding var touches: [Touch]
    @Binding var singleTouch: Touch?

    func updateNSView(_ nsView: AppKitTouchesView, context: Context) {
    }

    func makeNSView(context: Context) -> AppKitTouchesView {
        let view = AppKitTouchesView()
        view.delegate = context.coordinator
        return view
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AppKitTouchesViewDelegate {
        let parent: TouchesView
        
        init(_ view: TouchesView) {
            parent = view
        }
        
        func touchesView(_ view: AppKitTouchesView, didUpdateTouchingTouches touches: Set<NSTouch>) {
            parent.touches = touches.map(Touch.init)
            
            if let singleTouch = touches.first.map(Touch.init) {
                parent.singleTouch = singleTouch
                
//                if let mainWindow = NSApp.mainWindow {
//                    let windowFrame = mainWindow.frame
////                    let windowX = windowFrame.origin.x
////                    let windowY = windowFrame.origin.y
////                    print("Window X: \(windowX), Window Y: \(windowY)")
////                    // 여기에서 마우스 커서 위치 변경 작업을 수행합니다.
////                    print(view.frame.width, view.frame.height)
////                    let cursorLocation = CGPoint(
////                        x: singleTouch.normalizedX * view.frame.width + windowX,
////                        y: windowFrame.origin.y + singleTouch.normalizedY * view.frame.height + windowY
////                    )
//
////                    //마우스 위치 변경
////                    let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: cursorLocation, mouseButton: .left)
////                    event?.post(tap: .cghidEventTap)
//                }

                
            } else {
                parent.singleTouch = nil
            }
        }
    }

}

struct TrackPadView: View {
    private let touchViewSize: CGFloat = 25

    @State var touches: [Touch] = []
    @State var singleTouch: Touch?

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                TouchesView(touches: self.$touches, singleTouch: self.$singleTouch)

                if let singleTouch = self.singleTouch {
                    Circle()
                        .foregroundColor(Color.black)
                        .frame(width: self.touchViewSize, height: self.touchViewSize)
                        .offset(
                            x: proxy.size.width * singleTouch.normalizedX - self.touchViewSize / 2.0,
                            y: proxy.size.height * singleTouch.normalizedY - self.touchViewSize / 2.0
                        )
                }
            }
        }
//         추가: View의 onMouseDown 이벤트를 사용하여 마우스 클릭 시 커서 위치 출력
        .onAppear {
                    // 추가: View가 나타날 때 마우스 이벤트 모니터링 시작
            NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { event in
                        // 마우스 클릭 이벤트가 발생한 위치를 얻어옴
                        let mouseLocation = NSEvent.mouseLocation
                        print("Mouse click location: \(mouseLocation)")
                        return event
                    }
                }
    }
}

class TransparentWindowView: NSView {
    override func viewDidMoveToWindow() {
        let redWithAlpha = NSColor.darkGray.withAlphaComponent(0.7)
              window?.backgroundColor = redWithAlpha
              super.viewDidMoveToWindow()
    }
}

struct TransparentWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        return TransparentWindowView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update if needed
    }
}

struct ContentView: View {
    var body: some View {
        TransparentWindow()
            .frame(minWidth: 900, idealWidth: 900, minHeight: 600, idealHeight: 600)
            .background(TransparentWindow())
    }
}
