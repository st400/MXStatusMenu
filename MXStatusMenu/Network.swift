import Cocoa
import Darwin

class Network {
	
    /// Describes a network load
	struct Load {
		let input, output: Double
	}
	
    /// Describes a network throughput
	struct Throughput {
		let input, output: UInt64
		func delta(laterValue: Throughput) -> Throughput {
			let deltaInput = input.deltaByRecognizingOverflow(laterValue.input)
			let deltaOutput = output.deltaByRecognizingOverflow(laterValue.output)
			return Throughput(input: deltaInput, output: deltaOutput)
		}
	}
	
    /// A typealias that makes our code better to read
	typealias Throughputs = Dictionary<u_short, Throughput>
	
	/// The individual throughputs of the latest check
	var latestThroughputs: Throughputs? = nil
	
	/// Timestamp of the last check of the load stats
	var lastCheckTime: CFAbsoluteTime = 0
	
	/// The maximum throughput per second that is used as the 100% mark for the network load
	let maximumThroughput: Throughput
	
	/// Initialize the network with the maximum throughput
	init(maximumThroughput: Throughput) {
		self.maximumThroughput = maximumThroughput
	}
	
	/// The request struct used for the sysctl calls
	lazy var sysctlRequest: UnsafeMutablePointer<Int32> = {
		let sysctlRequest = UnsafeMutablePointer<Int32>.alloc(6)
		sysctlRequest[0] = CTL_NET
		sysctlRequest[1] = PF_ROUTE
		sysctlRequest[2] = 0
		sysctlRequest[3] = 0
		sysctlRequest[4] = NET_RT_IFLIST2
		sysctlRequest[5] = 0
		return sysctlRequest
		}()
	
	/// The size of if_msghdr2 structs
	lazy var ifmsgSize: Int = sizeof(if_msghdr2)
	
    /// Returns the current network load
	func load() -> Load {
		let checkTime = CFAbsoluteTimeGetCurrent()
		var load: Load
		if (lastCheckTime == 0) {
			load = Load(input: 0, output: 0)
		} else {
            let timeInterval = (checkTime - lastCheckTime)
            let throughput = self.throughput()
			load = Load(
				input: min(1, Double(throughput.input) / Double(maximumThroughput.input) / timeInterval),
                output: min(1, Double(throughput.output) / Double(maximumThroughput.output) / timeInterval))
		}
		lastCheckTime = checkTime
		return load
	}
	
    /// Returns the total throughput
	func throughput() -> Throughput {
		var input: UInt64 = 0
		var output: UInt64 = 0
		let throughputs = self.throughputs()
		if let latestThroughputs = self.latestThroughputs {
			for (index, throughput) in throughputs {
				if let latestThroughput = latestThroughputs[index] {
					let delta = throughput.delta(latestThroughput)
					input += delta.input
					output += delta.output
				}
			}
		}
		latestThroughputs = throughputs
		return Throughput(input: input, output: output)
	}
	
	/// Returns the individual throughputs of all network interfaces
	func throughputs() -> Throughputs {
		var throughputs = Throughputs()
		var bufferSize = 0
		
		// get the bufferSize
		if -1 != sysctl(sysctlRequest, 6, nil, &bufferSize, nil, 0) && bufferSize > 0 {
			
			// fill the buffer
			let buffer = UnsafeMutablePointer<UInt8>.alloc(bufferSize)
			if -1 != sysctl(sysctlRequest, 6, buffer, &bufferSize, nil, 0)  {
				var bufferIndex: Int = 0
				
				// iterate the if_msghdr2 objects in the buffer to calculate the throughputs
				while bufferIndex + ifmsgSize < bufferSize {
					let ifmsg = UnsafePointer<if_msghdr2>(advance(buffer, bufferIndex))[0]
					if ifmsg.ifm_flags.bitIsSet(IFF_RUNNING) && ifmsg.ifm_flags.bitIsSet(IFF_UP) && ifmsg.ifm_addrs.bitIsSet(RTA_IFP) {
						if let throughput = throughputs[ifmsg.ifm_index] {
							throughputs[ifmsg.ifm_index] = Throughput(input: throughput.input+ifmsg.ifm_data.ifi_ibytes, output: throughput.output+ifmsg.ifm_data.ifi_obytes)
						} else {
							throughputs[ifmsg.ifm_index] = Throughput(input: ifmsg.ifm_data.ifi_ibytes, output: ifmsg.ifm_data.ifi_obytes)
						}
					}
					if ifmsg.ifm_msglen > 0 {
						bufferIndex += Int(ifmsg.ifm_msglen)
					} else {
						break
					}
				}
			}
			
			// clean up
			buffer.dealloc(bufferSize)
		}
		
		return throughputs
	}
}
