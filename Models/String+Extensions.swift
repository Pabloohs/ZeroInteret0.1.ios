//
//  String+Extensions.swift
//  ZeroInteret0.1
//
//  Created by Vincent Grare on 02/02/2025.
//

// String+Extensions.swift
extension String {
    func maskedUID() -> String {
        guard self.count >= 4 else { return self }
        let lastFourDigits = String(self.suffix(4))
        let maskedPortion = String(repeating: "*", count: self.count - 4)
        return (maskedPortion + lastFourDigits).enumerated().map { index, char in
            index > 0 && index % 4 == 0 ? " \(char)" : String(char)
        }.joined()
    }
}
