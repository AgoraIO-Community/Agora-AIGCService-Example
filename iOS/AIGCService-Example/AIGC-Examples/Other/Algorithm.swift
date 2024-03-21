//
//  Algorithm.swift
//  GPT-Demo
//
//  Created by ZYP on 2023/7/31.
//

import Foundation
import CommonCrypto
import CryptoKit

func calculateAuthorization(host: String,
                            date: String,
                            method: String,
                            path: String,
                            apiSecret: String,
                            apiKey: String) -> String {
    let signature_origin_str = "host: \(host)\ndate: \(date)\n\(method) \(path) HTTP/1.1"
    print(signature_origin_str)
    let signature = signature_origin_str.hmac(by: .SHA256, key: apiSecret.bytes).base64
    let authorization_raw = "api_key=\"\(apiKey)\",algorithm=\"hmac-sha256\",headers=\"host date request-line\",signature=\"\(signature)\""
    print(authorization_raw)
    let authorization = authorization_raw.base64Encoded
    return authorization
}

func getUTCTime() -> String {
    // 创建一个DateFormatter对象
    let dateFormatter = DateFormatter()

    // 设置dateFormat属性为您要求的格式字符串
    dateFormatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'UTC'"

    // 设置locale属性为英文
    dateFormatter.locale = Locale(identifier: "en_US")

    // 设置timeZone属性为UTC时区
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

    // 获取当前日期/时间
    let date = Date()

    // 使用dateFormatter对象将date转换为符合您要求的格式字符串
    let utcString = dateFormatter.string(from: date)
    return utcString
}

extension String {
    func hmac(by algorithm: Algorithm, key: [UInt8]) -> [UInt8] {
        let count = Int(algorithm.digestLength())
        var result = [UInt8](repeating: 0, count: count)
        CCHmac(algorithm.algorithm(), key, key.count, self.bytes, self.bytes.count, &result)
        return result
    }
    
    var bytes: [UInt8] {
        return [UInt8](self.utf8)
    }
}

enum Algorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    func algorithm() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:    result = kCCHmacAlgMD5
        case .SHA1:   result = kCCHmacAlgSHA1
        case .SHA224: result = kCCHmacAlgSHA224
        case .SHA256: result = kCCHmacAlgSHA256
        case .SHA384: result = kCCHmacAlgSHA384
        case .SHA512: result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    var md5: String {
        let data = Data(self.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    var base64Encoded: String {
        return self.data(using: .utf8)!.base64EncodedString()
    }
}

extension Array where Element == UInt8 {
    var base64: String {
        let data = Data(self)
        return data.base64EncodedString()
    }
}

class TextHanlde {
    /// 过滤机器相关信息
    public static func replace(of target: String,
                        with replacement: String) -> String {
        let url = Bundle.main.url(forResource: "ai_self_introduce_replace", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        let patterns = try! decoder.decode([String].self, from: data)
        
        var output = target
        for pattern in patterns {
            output = output.replacingOccurrences(of: pattern, with: replacement)
        }
            
        output = removeDuplicates(text: output, target: replacement)
        return output
    }
    
    fileprivate static func removeDuplicates(text: String, target: String) -> String {
        let items = split(text: text)
        var result = [StrItem]()
        var isFirst = true
        for item in items {
            if item.isSymble == false, item.content.contains(target) {
                if isFirst {
                    result.append(item)
                    isFirst = false
                    continue
                }
                else {
                    if result.last?.isSymble ?? false {
                        result.removeLast()
                    }
                    continue
                }
                
            }
            result.append(item)
        }
        let string = result.map({ $0.content }).reduce("", +)
        return string
    }
    
    fileprivate static func split(text: String) -> [StrItem] {
        var results = [StrItem]()
        var temp = ""
        let patterns = ",.?!:;，。？！：；"
        for character in text {
            let str = String(character)
            if patterns.contains(str) {
                results.append(StrItem(content: temp, isSymble: false))
                results.append(StrItem(content: str, isSymble: true))
                temp = ""
            }
            else {
                temp += str
            }
        }
        
        results.append(StrItem(content: temp, isSymble: false))
        
        return results
    }
    
    fileprivate struct StrItem {
        let content: String
        let isSymble: Bool
    }
    
    /// 处理整句，返回整句和剩余部分
    public static func handleWholeSentence(text: String) -> (wholeSentence: String, other: String?) {
        var items = split(text: text)
        if items.isEmpty { return (text, nil) }
        if items.count == 1 {
            if items.first!.isSymble {
                return ("", items.first!.content)
            }
            else {
                return (items.first!.content, nil)
            }
        }
        var other: String? = nil
        if items.last!.isSymble == false {
            other = items.last!.content
            items.removeLast()
        }
        let wholeSentence = items.map({ $0.content }).reduce("", +)
        return (wholeSentence, other)
    }
}

extension TextHanlde {
    
    /// 增加人名称呼
    static func addHelloName(text: String, userName: String) -> String {
        let url = Bundle.main.url(forResource: "chat_append_hello", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        let helloNameList = try! decoder.decode([String].self, from: data)
        
        var helloName = helloNameList[Int.random(in: 0..<helloNameList.count)]
        helloName = helloName.replacingOccurrences(of: "username", with: userName)
        return helloName + text
        
    }
}
