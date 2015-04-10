extension UInt32 {
	
	/// Returns the delta between this and a later value by recognizing overflows. The returned value is always positive.
	func deltaByRecognizingOverflow(laterValue: UInt32) -> UInt32 {
		if (self >= laterValue) {
			return self - laterValue
		}
		return self + (UInt32.max - laterValue + 1)
	}
}
