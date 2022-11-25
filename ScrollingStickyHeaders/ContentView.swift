import SwiftUI

struct FramePreference: PreferenceKey {
    static var defaultValue: [CGRect] = []

    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

struct Sticky: ViewModifier {
    var stickyRects: [CGRect]
    @State var frame: CGRect = .zero

    var isSticking: Bool {
        frame.minY < 0
    }

    var offset: CGFloat {
        guard isSticking else { return 0 }
        var o = -frame.minY
        if let idx = stickyRects.firstIndex(where: { $0.minY > frame.minY && $0.minY < frame.height }) {
            let other = stickyRects[idx]
            o -= frame.height - other.minY
        }
        return o
    }

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .zIndex(isSticking ? .infinity : 0)
            .overlay(GeometryReader { proxy in
                let f = proxy.frame(in: .named("container"))
                Color.clear
                    .onAppear { frame = f }
                    .onChange(of: f) { frame = $0 }
                    .preference(key: FramePreference.self, value: [frame])
            })
    }
}

extension View {
    func sticky(_ stickyRects: [CGRect]) -> some View {
        modifier(Sticky(stickyRects: stickyRects))
    }
}

struct ContentView: View {
    @State private var frames: [CGRect] = []
    var body: some View {
        ScrollView {
            contents
        }
        .coordinateSpace(name: "container")
        .onPreferenceChange(FramePreference.self, perform: {
            frames = $0.sorted(by: { $0.minY < $1.minY
            })
        })
//        .overlay(alignment: .center) {
//            let str = frames.map {
//                "\(Int($0.minY)) - \(Int($0.height))"
//            }.joined(separator: "\n")
//            Text(str)
//                .foregroundColor(.white)
//                .background(.black)
//        }
    }

    @ViewBuilder var contents: some View {
        Image(systemName: "globe")
            .imageScale(.large)
            .foregroundColor(.accentColor)
            .padding()
        ForEach(0..<50) { ix in
            Text("Heading \(ix)")
                .font(.title)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .sticky(frames)

            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce ut turpis tempor, porta diam ut, iaculis leo. Phasellus condimentum euismod enim fringilla vulputate. Suspendisse sed quam mattis, suscipit ipsum vel, volutpat quam. Donec sagittis felis nec nulla viverra, et interdum enim sagittis. Nunc egestas scelerisque enim ac feugiat. ")
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
