//
//  AIGCManager.swift
//  AIGC-Examples
//
//  Created by ZYP on 2024/1/26.
//

import UIKit
import AgoraAIGCService
import RTMTokenBuilder
typealias AIGCManagerDelegate = AgoraAIGCServiceDelegate

extension AIGCManager {
    struct Configurate {
        /// stt供应商名称 如果用微软：microsoft
        let sttProviderName: String
        /// llm供应商名称 如果用GPT3：azureOpenai-gpt-35-turbo-16k，如果用GPT4：azureOpenai-gpt-4-16k
        let llmProviderName: String
        /// tts供应商名称 如果用微软：microsoft
        let ttsProviderName: String
        /// 指定role id，此字段无用，内部默认选择最后一个role
        let roleId: String
        /// 输入语言 选中文即可
        let inputLang:AgoraAIGCLanguage
        /// 输出语言 选中文即可
        let outputLang:AgoraAIGCLanguage
        /// 用户名称，这里随便给
        let userName: String
        /// 自定义prompt，这里不需要
        let customPrompt: String?
        /// 是否开启多轮短期记忆 true
        let enableMultiTurnShortTermMemory: Bool
        /// 语音识别过滤器长度 3
        let speechRecognitionFiltersLength: UInt
        /// 无用参数
        let enableSTT: Bool
        /// 无用参数
        let enableTTS: Bool
        /// 噪音环境 用：noise
        let noiseEnv: AgoraNoiseEnvironment
        /// 语音识别完整度 用：normal
        let speechRecCompLevel: AgoraSpeechRecognitionCompletenessLevel
        /// 是否继续处理LLM true
        let continueToHandleLLM: Bool
        /// 是否继续处理LLM true
        let continueToHandleTTS: Bool
    }
}

class AIGCManager: NSObject {
    var service: AgoraAIGCService!
    weak var delegate: AIGCManagerDelegate?
    private let sttProviderName: String
    private let llmProviderName: String
    private let ttsProviderName: String
    
    var continueToHandleLLM = true
    var continueToHandleTTS = true
    
    init(config: Configurate) {
        self.sttProviderName = config.sttProviderName
        self.llmProviderName = config.llmProviderName
        self.ttsProviderName = config.ttsProviderName
        self.continueToHandleLLM = config.continueToHandleLLM
        self.continueToHandleTTS = config.continueToHandleTTS
        super.init()
    }
    
    deinit {
        service.stop()
        AgoraAIGCService.destory()
        print("AIGCManager deinit")
    }
    
    public func setupAndInitialize() {
        service = AgoraAIGCService.create()
        let uid = "123"
        let appId = Config.appId
        let cer = Config.certificate
        let token = TokenBuilder.buildRtmToken(appId,
                                               appCertificate: cer,
                                               userUuid: uid)
        
        let input = AgoraAIGCSceneMode(language: .ZH_CN,
                                       speechFrameBits: 16,
                                       speechFrameSampleRates: 16000,
                                       speechFrameChannels: 1)
        let output = AgoraAIGCSceneMode(language: .ZH_CN,
                                        speechFrameBits: 16,
                                        speechFrameSampleRates: 16000,
                                        speechFrameChannels: 1)
        
        let config = AgoraAIGCConfigure(appId: appId,
                                        rtmToken: token,
                                        userId: uid,
                                        enableMultiTurnShortTermMemory: false,
                                        speechRecognitionFiltersLength: 3,
                                        input: input,
                                        output: output,
                                        enableLog: true,
                                        enableSaveLogToFile: true,
                                        userName: "小李",
                                        enableChatIdleTip: false,
                                        logFilePath: nil,
                                        noiseEnvironment: .normal,
                                        speechRecognitionCompletenessLevel: .normal)
        service.delegate = self
        service.initialize(config)
    }

    fileprivate func setupRoleAndVendor() {
        let roles = service.getRoles()
        service.setRoleWithId(roles!.last!.roleId)
        let serviceVendor = findSpecificVendorGroup()
        service.setServiceVendor(serviceVendor)
    }
    
    private func findSpecificVendorGroup() -> AgoraAIGCServiceVendor {
        guard let vendors = service.getVendors() else {
            fatalError("getVendors ret nil")
        }
        
        var stt: AgoraAIGCSTTVendor?
        var llm: AgoraAIGCLLMVendor?
        var tts: AgoraAIGCTTSVendor?
        
        for vendor in vendors.stt {
            if vendor.id == sttProviderName {
                stt = vendor
                break
            }
        }
        
        for vendor in vendors.llm {
            if vendor.id == llmProviderName {
                llm = vendor
                break
            }
        }
        
        for vendor in vendors.tts {
            if vendor.vendorName == ttsProviderName {
                tts = vendor
                break
            }
        }
        
        return AgoraAIGCServiceVendor(stt: stt!, llm: llm!, tts: tts!)
    }
}

extension AIGCManager: AgoraAIGCServiceDelegate {
    func onEventResult(with event: AgoraAIGCServiceEvent, code: AgoraAIGCServiceCode, message: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if event == .initialize, code == .initializeFail {
                print("====initializeFail")
                return
            }
            
            if event == .initialize, code == .licenseExpire {
                print("====licenseExpire")
                return
            }
            
            if event == .initialize, code == .success {
                print("====initialize success")
                self.setupRoleAndVendor()
                service.start()
            }
            
            delegate?.onEventResult(with: event, code: code, message: message)
        }
    }
    
    func onSpeech2Text(withRoundId roundId: String,
                       result: NSMutableString,
                       recognizedSpeech: Bool,
                       code: AgoraAIGCServiceCode) -> AgoraAIGCHandleResult {
        return delegate?.onSpeech2Text(withRoundId: roundId,
                                       result: result,
                                       recognizedSpeech: recognizedSpeech,
                                       code: code) ?? .continue
    }
    
    func onLLMResult(withRoundId roundId: String,
                     answer: NSMutableString,
                     isRoundEnd: Bool,
                     estimatedResponseTokens tokens: UInt,
                     code: AgoraAIGCServiceCode) -> AgoraAIGCHandleResult {
        return delegate?.onLLMResult(withRoundId: roundId,
                                     answer: answer,
                                     isRoundEnd: isRoundEnd,
                                     estimatedResponseTokens: tokens,
                                     code: code) ?? .continue
    }
    
    func onText2SpeechResult(withRoundId roundId: String,
                             voice: Data,
                             sampleRates: Int,
                             channels: Int,
                             bits: Int,
                             code: AgoraAIGCServiceCode) -> AgoraAIGCHandleResult {
        return delegate?.onText2SpeechResult(withRoundId: roundId,
                                             voice: voice,
                                             sampleRates: sampleRates,
                                             channels: channels,
                                             bits: bits,
                                             code: code) ?? .continue
    }
}

