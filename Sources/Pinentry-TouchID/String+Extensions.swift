import Foundation

extension String {
    // Remove a prefix
    func dropPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    // Find matches according to a regular expression
    func matches(_ regex: NSRegularExpression) -> [String] {
        let range = NSRange(self.startIndex..<self.endIndex, in: self)
        let matches = regex.matches(in: self, options: [], range: range)
        var names: [String] = []
        guard let match = matches.first else { return names }
        for rangeIndex in 0..<match.numberOfRanges {
            let matchRange = match.range(at: rangeIndex)
            if matchRange == range { continue }
            if let substringRange = Range(matchRange, in: self) {
                let capture = String(self[substringRange])
                names.append(capture)
            }
        }
        return names
    }
}
