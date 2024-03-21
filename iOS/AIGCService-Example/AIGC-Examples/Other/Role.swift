//
//  Role.swift
//  GPT-Demo
//
//  Created by ZYP on 2023/8/25.
//

import Foundation

struct Role: Codable {
    let chatBotRoleId: String
    let chatBotName: String
    let profession: String
    let gender: String
    let chatBotUserName: String
    let chatBotPrompt: String
    let selfIntroduce: String
    /// TTS 欢迎词 切换角色&进房间播放
    fileprivate let welcomeMessage: String
    let avatar: Avatar
    let voiceNames: [VoiceName]
    
    func getWelcomeMessage() -> String {
        var temp = welcomeMessage
        temp = temp.replacingOccurrences(of: "chatBotName", with: chatBotName)
        temp = temp.replacingOccurrences(of: "profession", with: profession)
        return temp
    }
    
    func getVoiceNameValue() -> String {
        return voiceNames.filter({ $0.platformName == "ms" }).first!.voiceNameValue
    }
}

extension Role {
    static func getRoles() -> [Role] {
        let url = Bundle.main.url(forResource: "chat_bot_role", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        do {
            let roles = try decoder.decode([Role].self, from: data)
            return roles
        } catch let e {
            Log.errorText(text: e.localizedDescription, tag: "Role")
            fatalError()
        }
    }
}

struct Avatar: Codable {
    let name: String
    let bgFilePath: String
}

/// TTS voice选项
struct VoiceName: Codable {
    let platformName: String
    let voiceName: String
    let voiceNameValue: String
    let voiceNameStyle: String
}
