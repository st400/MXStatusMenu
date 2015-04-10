extension UInt64 {
	
	/// Returns the delta between this and a later value by recognizing overflows. The returned value is always positive.
	func deltaByRecognizingOverflow(laterValue: UInt64) -> UInt64 {
		if (self >= laterValue) {
			return self - laterValue
		}
		return self + (UInt64.max - laterValue + 1)
	}
}
