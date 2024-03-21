//
//  PromptGenerator.swift
//  AIGC-Examples
//
//  Created by ZYP on 2024/2/27.
//

import Foundation

class PromptGenerator {
    private var historyDialogs = [Item]()
    /// 和你对话的同学名称
    private let teacherName: String
    /// 学生的名称
    private let userName: String
    /// 场景对话prompt
    private let promptDialog: String
    /// 提示部分
    private let promptTipSlic: String
    /// 润色部分
    private let promptPolishSlic: String
    /// 翻译部分
    private let promptTranslateSlic: String
    private let promptDialogEnd: String
    /// 当前prompt消耗的token数量
    let promptToken: UInt
    let extraInfoJson: String
    
    init(teacherName: String,
         userName: String,
         promptDialog: String,
         promptTipSlic: String,
         promptPolishSlic: String,
         promptTranslateSlic: String,
         promptDialogEnd: String,
         promptToken: UInt,
         extraInfoJson: String) {
        self.teacherName = teacherName
        self.userName = userName
        self.promptDialog = promptDialog
        self.promptTipSlic = promptTipSlic
        self.promptPolishSlic = promptPolishSlic
        self.promptTranslateSlic = promptTranslateSlic
        self.promptDialogEnd = promptDialogEnd
        self.promptToken = promptToken
        self.extraInfoJson = extraInfoJson
    }
    
    func addDialog(item: Item) {
        historyDialogs.append(item)
    }
    
    var canSendTipPrompt: Bool {
        if historyDialogs.isEmpty {
            return true
        }
        let last = historyDialogs.last!
        return last.roleType == .assistant
    }
    
    /// 产生开场白的PromptString
    /// - Note: 逻辑：读取原始prompt，最后把“占位符替换”
    func generateConversationStarterPromptString() -> String {
        /// 字符串转dict
        let data = promptDialog.data(using: .utf8)!
        let messages = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String : Any]]
        
        /// dict转字符串
        let jsonData = try! JSONSerialization.data(withJSONObject: messages, options: .prettyPrinted)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        /// 替换名词
        let result = jsonString
            .replacingOccurrences(of: "{{teacher}}", with: teacherName)
            .replacingOccurrences(of: "{{user}}", with: userName)
        return result
    }
    
    /// 产生用户对话的PromptString
    /// - Note: 逻辑：1.读取原始prompt；2.移除原始prompt中最后一个开场白数据； 3.插入历史消息；4.把“占位符替换”；
    /// - Parameter dialogShouldEndAtTime: 是否要插入引导结束信息
    func generateDialogPromptString(dialogShouldEndAtTime: Bool) -> String {
        /// 字符串转dict
        var data = promptDialog.data(using: .utf8)!
        var messages = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String : Any]]
        
        /// 插入对话历史
        let historyArray = historyDialogs.map({ $0.dict })
        
        /// 移除最后一个产生开场白的数据
        messages.removeLast()
        messages.insert(contentsOf: historyArray, at: messages.count - 1)

        if dialogShouldEndAtTime {
            /// 加入引导对话结束prompt
            data = promptDialogEnd.data(using: .utf8)!
            let promptTipSlicDict = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String : Any]
            messages.append(promptTipSlicDict)
        }
        
        /// dict转字符串
        let jsonData = try! JSONSerialization.data(withJSONObject: messages, options: .prettyPrinted)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        /// 替换名词
        let result = jsonString
            .replacingOccurrences(of: "{{teacher}}", with: teacherName)
            .replacingOccurrences(of: "{{user}}", with: userName)
        return result
    }
    
    /// 产生提示功能的PromptString
    /// - Note: 逻辑：1.读取原始prompt；2.移除原始prompt中最后一个开场白数据； 3.插入历史消息；4.加入提示类型prompt； 5.把“占位符替换”；
    func generateTipPromptString() -> String {
        /// 字符串转dict
        var data = promptDialog.data(using: .utf8)!
        var messages = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String : Any]]
        
        /// 插入对话历史
        let historyArray = historyDialogs.map({ $0.dict })
        /// 移除最后一个产生开场白的数据
        messages.removeLast()
        messages.insert(contentsOf: historyArray, at: messages.count - 1)
        
        /// 加入提示类型prompt
        data = promptTipSlic.data(using: .utf8)!
        let promptTipSlicDict = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String : Any]
        messages.append(promptTipSlicDict)

        /// dict转字符串
        let jsonData = try! JSONSerialization.data(withJSONObject: messages, options: .prettyPrinted)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        /// 替换名词
        let result = jsonString
            .replacingOccurrences(of: "{{teacher}}", with: teacherName)
            .replacingOccurrences(of: "{{user}}", with: userName)
        return result
    }
    
    
    /// 产生润色提示的PromptString
    /// - Note: 逻辑：1.读取原始prompt；2.移除原始prompt中最后一个开场白数据； 3.插入历史消息；4.加入polish类型prompt； 5.把“占位符替换”；
    /// - Parameter content: 润色内容
    func generatePolishPromptString(content: String) -> String {
        /// 字符串转dict
        var data = promptDialog.data(using: .utf8)!
        var messages = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String : Any]]
        
        /// 移除最后一个产生开场白的数据
        messages.removeLast()
        /// 插入对话历史
        let historyArray = historyDialogs.map({ $0.dict })
        messages.insert(contentsOf: historyArray, at: messages.count - 1)
        
        /// 加入polish prompt
        data = promptPolishSlic.data(using: .utf8)!
        let promptTipSlicDict = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String : Any]
        messages.append(promptTipSlicDict)

        /// dict转字符串
        let jsonData = try! JSONSerialization.data(withJSONObject: messages, options: .prettyPrinted)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        /// 替换名词
        let result = jsonString
            .replacingOccurrences(of: "{{teacher}}", with: teacherName)
            .replacingOccurrences(of: "{{user}}", with: userName)
            .replacingOccurrences(of: "{{last_response}}", with: content)
    
        return result
    }
    
    /// 产生翻译提示的PromptString
    /// - Note: 逻辑：1.加入翻译类型的prompt 2.把“占位符替换”；
    /// - Parameters:
    ///   - content: 需要翻译的内容
    ///   - lang: 需要翻译的目标语言
    func generateTranslatePromptString(content: String, lang: String = "英文") -> String {
        var messages = [[String : Any]]()
        
        /// 加入translate prompt
        let data = promptTranslateSlic.data(using: .utf8)!
        let promptTipSlicDict = try! JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String : Any]
        messages.append(promptTipSlicDict)

        /// dict转字符串
        let jsonData = try! JSONSerialization.data(withJSONObject: messages, options: .prettyPrinted)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        /// 替换名词
        let result = jsonString
            .replacingOccurrences(of: "{{teacher}}", with: teacherName)
            .replacingOccurrences(of: "{{user}}", with: userName)
            .replacingOccurrences(of: "{{last_response}}", with: content)
            .replacingOccurrences(of: "{{language}}", with: lang)
    
        return result
    }
}

extension PromptGenerator {
    enum RoleType {
        case assistant
        case user
        
        var name: String {
            switch self {
            case .assistant:
                return "assistant"
            case .user:
                return "user"
            }
        }
    }
    
    struct Item {
        let roleType: RoleType
        let content: String
        let timestap: TimeInterval = Date().timeIntervalSince1970
        
        var dict: [String : Any] {
            switch roleType {
            case .assistant:
                return ["role" : roleType.name, "name" : "{{teacher}}", "content" : "\(content)"]
            case .user:
                return ["role" : roleType.name, "name" : "{{user}}", "content" : "“\(content)”"]
            }
        }
    }
}
