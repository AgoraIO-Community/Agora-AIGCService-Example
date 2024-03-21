//
//  IntegrationTestingVC.swift
//
//
//  Created by ZYP on 2023/10/18.
//

import UIKit
import AgoraAIGCService
import RTMTokenBuilder
import AgoraRtcKit

class MainViewController: UIViewController, AgoraAIGCServiceDelegate, RtcManagerDelegate, MainViewDelegate {
    let mainView = MainView()
    var service: AgoraAIGCService!
    private let rtcManager = RtcManager()
    private let config: Configurate
    
    init(config: Configurate) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = config.sttProviderName + "+" + config.llmProviderName + "+" + config.ttsProviderName
        view.backgroundColor = .white
        view.addSubview(mainView)
        mainView.frame = view.bounds
        mainView.delegate = self
        
        mainView.showTextField(show: !config.enableSTT)
        
        initRtc()
        initAIGC()
    }
    
    deinit {
        service.stop()
        AgoraAIGCService.destory()
    }
    
    private func initRtc() {
        rtcManager.delegate = self
        rtcManager.initEngine()
        rtcManager.joinChannel()
    }
    
    private func initAIGC() {
        service = AgoraAIGCService.create()
        let uid = "123"
        let appId = Config.appId
        let cer = Config.certificate
        let token = TokenBuilder.buildRtmToken(appId,
                                               appCertificate: cer,
                                               userUuid: uid)
        
        let input = AgoraAIGCSceneMode(language: config.inputLang,
                                       speechFrameBits: 16,
                                       speechFrameSampleRates: 16000,
                                       speechFrameChannels: 1)
        let output = AgoraAIGCSceneMode(language: config.outputLang,
                                        speechFrameBits: 16,
                                        speechFrameSampleRates: 16000,
                                        speechFrameChannels: 1)
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cachesPath = paths.first!
        let config = AgoraAIGCConfigure(appId: appId,
                                        rtmToken: token,
                                        userId: uid,
                                        enableMultiTurnShortTermMemory: config.enableMultiTurnShortTermMemory,
                                        speechRecognitionFiltersLength: config.speechRecognitionFiltersLength,
                                        input: input,
                                        output: output,
                                        enableLog: true,
                                        enableSaveLogToFile: true,
                                        userName: config.userName,
                                        enableChatIdleTip: false,
                                        logFilePath: nil,
                                        noiseEnvironment: config.noiseEnv,
                                        speechRecognitionCompletenessLevel: config.speechRecCompLevel)
        service.delegate = self
        service.initialize(config)
    }
    
    func setupRoleAndVendor() {
        let targetRoleId = config.roleId
        guard let roles = service.getRoles() else {
            fatalError("roles is nil")
        }
        guard roles.contains(where: { $0.roleId == targetRoleId }) else {
            fatalError("no target role")
        }
        
        if let customPrompt = config.customPrompt {
            service.setPrompt(customPrompt)
        }
        let serviceVendor = findSpecificVendorGroup()
        service.setServiceVendor(serviceVendor)
        service.setRoleWithId(targetRoleId)
    }
    
    func findSpecificVendorGroup() -> AgoraAIGCServiceVendor {
        guard let vendors = service.getVendors() else {
            fatalError("getVendors ret nil")
        }
        
        var stt: AgoraAIGCSTTVendor?
        var llm: AgoraAIGCLLMVendor?
        var tts: AgoraAIGCTTSVendor?
        
        for vendor in vendors.stt {
            if vendor.id == config.sttProviderName {
                stt = vendor
                break
            }
        }
        
        for vendor in vendors.llm {
            if vendor.id == config.llmProviderName {
                llm = vendor
                break
            }
        }
        
        for vendor in vendors.tts {
            if vendor.vendorName == config.ttsProviderName {
                tts = vendor
                break
            }
        }
        let useCustomJson = false
        if useCustomJson {
            let accountInJsonSTT = "{\"vendorName\":\"microsoft\",\"key\":\"59e03d7b53714f4d8595d7590f0854a2\",\"reserved\":\"eastasia\"}"
            let sttC = AgoraAIGCSTTVendor(accountInJson: accountInJsonSTT, id: stt!.id)
            let customJosnLLM = "{\"vendorName\":\"minimax\",\"appId\":\"1682318474041774\",\"key\":\"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJOYW1lIjoiYWdvcmEtZ3B0IiwiU3ViamVjdElEIjoiMTY4MjMxODQ3NDg2MDkyNCIsIlBob25lIjoiTVRVNU5URTROelUxTlRFPSIsIkdyb3VwSUQiOiIxNjgyMzE4NDc0MDQxNzc0IiwiUGFnZU5hbWUiOiIiLCJNYWlsIjoicGF1bGR1Y2dAMTYzLmNvbSIsIkNyZWF0ZVRpbWUiOiIyMDIzLTA3LTE5IDE2OjU5OjQ1IiwiaXNzIjoibWluaW1heCJ9.qrC72KMpO3Xv6KJGR0bZc8xOx3GGCwbwh81D_cxspdQzKgDLg2tb92sipW1VtwwyVgonXjrZ8QkvRwHUW1Pw2x_I_SBypVDKSi7Pk-P-FsamXrLlNmFdJNfTi5z35ZmxTkcbfxrX8Y3qmeV5CdwUb-5FUgOOAAtJAiNh-1tAFwzycgJ59Z5E9AtW4XBObmMltwO8TWKjMf9E787MhLQLL_9MEkEoKdZnvzTdfvuA2gfuNxg6-a5ZNDG_VOe6tNo8bkmHedqd-_wcJic3hZAwhZ9EspjaOguCtnbYtcOp-ksptwyNOGHSCK1POfgpL2ZxBCk5pADqu_sUBYlxYJokyg\"}"
            let llmC = AgoraAIGCLLMVendor(accountInJson: customJosnLLM, id: llm!.id)
            
            let customJosnTTS = "{\"vendorName\":\"microsoft\",\"key\":\"59e03d7b53714f4d8595d7590f0854a2\",\"reserved\":\"eastasia\"}"
            
            let ttsC = AgoraAIGCTTSVendor(accountInJson: customJosnTTS,
                                          id: tts!.id,
                                          voiceNameValue:
                                            tts!.voiceNameValue,
                                          voiceStyle: tts!.voiceStyle)
            return AgoraAIGCServiceVendor(stt: sttC,
                                          llm: llmC,
                                          tts: ttsC)
        }
        
        return AgoraAIGCServiceVendor(stt: stt!,
                                      llm: llm!,
                                      tts: tts!)
        
    }
    
    // MARK: - AIGCServiceDelegate
    
    func onEventResult(with event: AgoraAIGCServiceEvent, code: AgoraAIGCServiceCode, message: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if event == .initialize, code == .initializeFail {
                print("====initializeFail")
                return
            }
            
            if event == .initialize, code == .success {
                print("====initialize success")
                self.setupRoleAndVendor()
                service.start()
                rtcManager.startRecord()
            }
            
        }
    }
    
    func onSpeech2Text(withRoundId roundId: String,
                       result: NSMutableString,
                       recognizedSpeech: Bool,
                       code: AgoraAIGCServiceCode) -> AgoraAIGCHandleResult {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            print("====onSpeech2Text:\(result) recognizedSpeech:\(recognizedSpeech)")
            //            result.append("123456789")
            let info = MainView.Info(uuid: roundId, content: result.copy() as! String)
            mainView.addOrUpdateInfo(info: info)
        }
        return config.enableSTT ? .continue : .discard
    }
    
    func onLLMResult(withRoundId roundId: String,
                     answer: NSMutableString,
                     isRoundEnd: Bool,
                     estimatedResponseTokens tokens: UInt,
                     code: AgoraAIGCServiceCode) -> AgoraAIGCHandleResult {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            let info = MainView.Info(uuid: "llm" + roundId, content: answer.copy() as! String)
            mainView.addOrUpdateInfo(info: info)
        }
        return config.enableTTS ? .continue : .discard
    }
    
    func onText2SpeechResult(withRoundId roundId: String,
                             voice: Data,
                             sampleRates: Int,
                             channels: Int,
                             bits: Int,
                             code: AgoraAIGCServiceCode) -> AgoraAIGCHandleResult {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            rtcManager.setPlayData(data: voice)
        }
        return .continue
    }
    
    // MARK: - MainViewDelegate
    func mainViewDidShouldSendText(text: String) {
        let info = MainView.Info(uuid: "\(UInt8.random(in: 0...200))", content: text)
        mainView.addOrUpdateInfo(info: info)
        service.pushTxtDialogue(text, interruptDialogue: false)
    }
    
    // MARK: - RtcManagerDelegate
    func rtcManagerOnCaptureAudioFrame(frame: AgoraAudioFrame) {
        guard config.enableSTT else {
            return
        }
        let count = frame.samplesPerChannel * frame.channels * frame.bytesPerSample
        let data = Data(bytes: frame.buffer!, count: count)
        DispatchQueue.main.async {
            self.service.pushSpeechDialogue(with: data, vad: .nonMute)
        }
    }
    func rtcManagerOnVadUpdate(isSpeaking: Bool) {}
    func rtcManagerOnDebug(text: String) {}
    func rtcManagerOnCreatedRenderView(view: UIView) {}
}

extension MainViewController {
    struct Configurate {
        let sttProviderName: String
        let llmProviderName: String
        let ttsProviderName: String
        let roleId: String
        let inputLang:AgoraAIGCLanguage
        let outputLang:AgoraAIGCLanguage
        let userName: String
        let customPrompt: String?
        let enableMultiTurnShortTermMemory: Bool
        let speechRecognitionFiltersLength: UInt
        let enableSTT: Bool
        let enableTTS: Bool
        let noiseEnv: AgoraNoiseEnvironment
        let speechRecCompLevel: AgoraSpeechRecognitionCompletenessLevel
    }
}
