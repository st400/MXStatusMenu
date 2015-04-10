import Cocoa

/// The StatusController manages the status item in the menu bar
class StatusController {
	
	/// The cpu stats
	let cpu = CPU()
	
	/// The latest cpu load
	var cpuLoad: [Double]
	
	/// The network stats
	let network = Network(maximumThroughput: MaximumNetworkThroughput)

	/// The latest network load
	var networkLoad = Network.Load(input: 0, output: 0)
	
	/// The status item in the menu bar
	let statusItem: NSStatusItem
	
	/// The timer updates the statusView
	var timer: Timer?
	
	/// Lazy load the statusView. We can't do this in init() because the statusView needs a reference to the StatusController.
	lazy var statusView: StatusView = StatusView(frame: NSZeroRect, statusController: self)
	
	/// Initialize the values, add the statusItem to the menu bar, and start the timer
	init() {
		let statusItemWidth = StatusView.widthOfCPUCount(cpu.numberOfThreads)
        
        cpuLoad = cpu.load()
        networkLoad = network.load()
		statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(statusItemWidth)
		statusItem.view = statusView
		timer = Timer.repeatEvery(UpdateInterval) { [weak self] inTimer in
			if let strongSelf = self {
				strongSelf.updateStatusItem()
			}
		}
	}
	
	/// Get the current load values and update the statusView
	func updateStatusItem() {
		cpuLoad = cpu.load()
		networkLoad = network.load()
		statusView.setNeedsDisplayInRect(statusView.bounds)
	}
}
