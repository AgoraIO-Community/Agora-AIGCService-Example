//
//  LanguageAssistantView+Info.swift
//  AIGC-Examples
//
//  Created by ZYP on 2024/2/28.
//

import UIKit

extension LanguageAssistantView {
    class Info {
        enum RoleType: CustomStringConvertible {
            case user
            case assistant
            
            var description: String {
                switch self {
                case .user:
                    return "User"
                case .assistant:
                    return "AI"
                }
            }
        }
        let roundId: String
        var content: String
        let timestap: Int
        var translatedText: String?
        let roleType: RoleType
        let prifix: String?
        
        init(uuid: String, content: String, roleType: RoleType, prifix: String? = nil) {
            self.roundId = uuid
            self.content = content
            self.timestap = Int(Date().timeIntervalSince1970)
            self.roleType = roleType
            self.prifix = prifix
        }
        
        var isMe: Bool {
            roleType == .user
        }
        
        func addPrefix() {
            if prifix != nil, content.hasPrefix(prifix!) {
                return
            }
            
            self.content = (prifix ?? "") + self.content
        }
    }
}
