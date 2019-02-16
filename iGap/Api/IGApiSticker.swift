/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */

import Foundation
import Alamofire
import SwiftyJSON

public class IGApiSticker {
    
    static let shared = IGApiSticker()
    private let urlStickerList = "https://sticker.igap.net/stickers"
    private let urlMySticker = "https://sticker.igap.net/stickers"
    
    private func getHeaders() -> HTTPHeaders {
        let path = Bundle.main.path(forResource: "stickerPublicKey", ofType: "txt")
        let publicKey : String = try! NSString(contentsOfFile: path!, encoding: String.Encoding.utf8.rawValue) as String
        let authorization = "Bearer " + String(describing: IGAppManager.sharedManager.userID()).aesEncrypt(publicKey: publicKey)
        let headers: HTTPHeaders = ["Authorization": authorization]
        return headers
    }
    
    func stickerList(offset: Int, limit: Int, completion: @escaping ((_ stickers :[StickerTab]) -> Void)) {
        let parameters: Parameters = ["skip" : offset, "limit" : limit]
        Alamofire.request(urlStickerList, parameters: parameters, headers: getHeaders()).responseStickerApi { response in
            if let stickerApi = response.result.value {
                completion(stickerApi.data)
            }
        }
    }
    
    func mySticker(){
        Alamofire.request(urlMySticker, headers: getHeaders()).responseStickerApi { response in
            if let stickerApi = response.result.value {
                IGFactory.shared.addSticker(stickers: stickerApi.data)
            }
        }
    }
    
    func addSticker(groupId: String, completion: @escaping ((_ success :Bool) -> Void)) {
        let urlSticker = urlMySticker + "/" + groupId + "/favorite"
        Alamofire.request(urlSticker, method: .post, headers: getHeaders()).responseJSON { response in
            completion(response.result.isSuccess)
        }
    }
    
    func removeSticker(groupId: String, completion: @escaping ((_ success :Bool) -> Void)) {
        let urlSticker = urlMySticker + "/" + groupId + "/favorite"
        Alamofire.request(urlSticker, method: .delete, headers: getHeaders()).responseJSON { response in
            completion(response.result.isSuccess)
        }
    }
    
    func newJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            decoder.dateDecodingStrategy = .iso8601
        }
        return decoder
    }
    
    func newJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            encoder.dateEncodingStrategy = .iso8601
        }
        return encoder
    }
}

extension DataRequest {
    fileprivate func decodableResponseSerializer<T: Decodable>() -> DataResponseSerializer<T> {
        return DataResponseSerializer { _, response, data, error in
            guard error == nil else { return .failure(error!) }
            
            guard let data = data else {
                return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
            }
            
            return Result { try JSONDecoder().decode(T.self, from: data) }
        }
    }
    
    @discardableResult
    fileprivate func responseDecodable<T: Decodable>(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: decodableResponseSerializer(), completionHandler: completionHandler)
    }
    
    @discardableResult
    func responseStickerApi(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<StickerApi>) -> Void) -> Self {
        return responseDecodable(queue: queue, completionHandler: completionHandler)
    }
}
