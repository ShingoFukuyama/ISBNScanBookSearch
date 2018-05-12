//
//  ScanBookModel.swift
//  ISBNScanBookSearch
//

import Foundation

class ScanBookModel: NSObject {
    var handleISBN: ((Error?) -> Void)?
    var isbn: ISBN?
    private var sessionData = Data()
    override init() {
        super.init()
        assert(!ScanBookModel.rakutenBookAppID.isEmpty, "Please set your own Rakuten Application ID. あなた個人の楽天Application IDを指定してください。楽天ブックス書籍検索API: https://webservice.rakuten.co.jp/explorer/api/BooksBook/Search/")
    }
}

extension ScanBookModel: URLSessionTaskDelegate, URLSessionDataDelegate {
    static private let rakutenBookAppID = "" /// <-- your own Application ID
    static private let rakutenBookEndPoint = "https://app.rakuten.co.jp/services/api/BooksBook/Search/20170404"
    static private func rakutenBookRequestURLString(withISBN code: String) -> String {
        return rakutenBookEndPoint + "?format=json&isbn=\(code)&applicationId=\(rakutenBookAppID)"
    }

    func fetchRakutenBookURL(code: String) {
        // https://webservice.rakuten.co.jp/explorer/api/BooksBook/Search/
        isbn = ISBN(code: code)
        guard let url = URL(string: ScanBookModel.rakutenBookRequestURLString(withISBN: code)) else {
            return
        }
        let request = URLRequest(url: url)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession.init(configuration: config, delegate: self, delegateQueue: nil)
        session.dataTask(with: request).resume()
    }

    private func success() {
        do {
            let _json = try JSONSerialization.jsonObject(with: sessionData, options: JSONSerialization.ReadingOptions.mutableContainers)
            guard
                let json = _json as? [String: Any],
                !json.isEmpty,
                let items = json["Items"] as? [Any],
                !items.isEmpty,
                let itemInfo = items.first as? [String: Any],
                let item = itemInfo["Item"] as? [String: Any]
                else {
                    enum _JSONScanError: Error, LocalizedError {
                        case unableToGetItem
                        var errorDescription: String? {
                            switch self {
                            case .unableToGetItem: return "Unable to get an item from JSON tree"
                            }
                        }
                    }
                    throw _JSONScanError.unableToGetItem
            }
            isbn?.title = item["title"] as? String
            isbn?.rakutenURL = URL(string: item["itemUrl"] as? String ?? "")
            handleISBN?(nil)
        } catch {
            handleISBN?(error)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard error == nil else {
                self?.handleISBN?(error)
                return
            }
            self?.success()
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        sessionData.removeAll()
        completionHandler(URLSession.ResponseDisposition.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        sessionData.append(data)
    }
}
