import Foundation

extension Array {
    /// Partitions an array into two arrays based on a predicate
    /// - Parameter predicate: A closure that returns true for elements that should be in the first partition
    /// - Returns: A tuple containing matching and non-matching elements
    func partition(by predicate: (Element) -> Bool) -> (matching: [Element], notMatching: [Element]) {
        var matching: [Element] = []
        var notMatching: [Element] = []
        
        for element in self {
            if predicate(element) {
                matching.append(element)
            } else {
                notMatching.append(element)
            }
        }
        
        return (matching, notMatching)
    }
}