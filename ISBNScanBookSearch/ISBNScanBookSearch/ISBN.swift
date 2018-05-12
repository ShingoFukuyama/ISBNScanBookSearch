//
//  ISBN.swift
//  ISBNScanBookSearch
//

import UIKit

struct ISBN {
    var title: String?
    var amazonURL: URL?
    var rakutenURL: URL?
    var code: String {
        didSet {
            generateAmazonURL()
        }
    }

    init(code: String) {
        self.code = code
        generateAmazonURL()
    }
//    init(code: String, title: String? = nil, rakutenURL: URL? = nil) {
//        self.code = code
//        self.title = title
//        self.rakutenURL = rakutenURL
//        generateAmazonURL()
//    }

    private mutating func generateAmazonURL() {
        amazonURL = nil
        let codeValue: Int64 = Int64(code) ?? 0
        let codePrefix: Int64 = codeValue / 10_000_000_000
        if 978...979 ~= codePrefix {
            let isbn9: Int64 = codeValue % 10_000_000_000 / 10
            var sum: Int64 = 0
            var tmp_isbn = isbn9
            for i in stride(from: 10, to: 0, by: -1) {
                let divisor = Int64(truncating: NSDecimalNumber(decimal: pow(10, i - 2)))
                sum += (tmp_isbn / divisor) * Int64(i)
                tmp_isbn %= divisor
            }
            let checkDigit = 11 - (sum % 11)
            let asin = String(format: "http://www.amazon.co.jp/exec/obidos/ASIN/%09lld%@/ref=nosim/",
                              isbn9,
                              (checkDigit == 10) ? "X" : "\(checkDigit % 11)")
            if let url = URL(string: asin) {
                amazonURL = url
            }
        }
    }
}
