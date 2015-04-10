import Cocoa

// Visual Parameters
let BarWidth: CGFloat = 7.0
let GapBetweenBars: CGFloat = 6.0
let LeftMargin: CGFloat = 5.5
let RightMargin: CGFloat = 5.5

// Update interval in seconds
let UpdateInterval = 0.5

/// The maximum throughput per second that is used as the 100% mark for the network load
let MaximumNetworkThroughput = Network.Throughput(input: 1_258_291 /* Download: 1,2 MB/s */, output: 133_120 /* Upload: 120 Kb/s */)

/// Our app delegate only holds a reference to the StatusController, nothing more
class App: NSObject, NSApplicationDelegate {
    let statusController = StatusController()
}
