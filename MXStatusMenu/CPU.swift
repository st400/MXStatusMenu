import Cocoa
import Darwin

class CPU {
	
	/// The ticks of the latest check
	var latestTicks = [processor_cpu_load_info]()
    
    /// The number of cpu threads
    var numberOfThreads: Int {
    return latestTicks.count
    }
	
	/// Initialize the latestTicks so that we know the number of cpu threads
	init() {
		latestTicks = ticks()
	}
	
	/// Returns the current cpu load as an array of percentages for each cpu thread
	func load() -> [Double] {
		let ticks = self.ticks()
		var load = [Double](count: ticks.count, repeatedValue: 0)
		if ticks.count == latestTicks.count {
			for (i, loadInfo) in enumerate(ticks) {
				let delta = loadInfo.delta(latestTicks[i])
				let total = delta.cpu_ticks.0 + delta.cpu_ticks.1 + delta.cpu_ticks.2
				if total > 0 {
					load[i] = Double(delta.cpu_ticks.0 + delta.cpu_ticks.1) / Double(total)
				}
			}
		}
		latestTicks = ticks
		return load.sorted({$0 > $1})
	}
	
	/// Returns the current ticks of each cpu thread
	func ticks() -> [processor_cpu_load_info] {
		var ticks = [processor_cpu_load_info]()
		var processorCount = UnsafeMutablePointer<natural_t>.alloc(1)
		var loadInfos = UnsafeMutablePointer<processor_cpu_load_info_t>.alloc(1)
		var infoCount = UnsafeMutablePointer<mach_msg_type_number_t>.alloc(1)
		
		// get the ticks
		if KERN_SUCCESS == host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, processorCount, UnsafeMutablePointer<processor_info_array_t>(loadInfos), infoCount) {
			for i in 0..<Int(processorCount[0]) {
                ticks.append(loadInfos[0][i])
			}
		} else {
			ticks = latestTicks
		}
		
		// clean up
		processorCount.dealloc(1)
		loadInfos.dealloc(1)
		infoCount.dealloc(1)
		return ticks
	}
}

/// note: processor_cpu_load_info.cpu_ticks contains four load infos: (user, system, idle, nice)
extension processor_cpu_load_info {
	
	/// Returns the delta of two load values
	func delta(laterValue: processor_cpu_load_info) -> processor_cpu_load_info {
		let userDelta = cpu_ticks.0.deltaByRecognizingOverflow(laterValue.cpu_ticks.0)
		let systemDelta = cpu_ticks.1.deltaByRecognizingOverflow(laterValue.cpu_ticks.1)
		let idleDelta = cpu_ticks.2.deltaByRecognizingOverflow(laterValue.cpu_ticks.2)
		let niceDelta = cpu_ticks.3.deltaByRecognizingOverflow(laterValue.cpu_ticks.3)
		return processor_cpu_load_info(cpu_ticks: (userDelta, systemDelta, idleDelta, niceDelta))
	}
}
