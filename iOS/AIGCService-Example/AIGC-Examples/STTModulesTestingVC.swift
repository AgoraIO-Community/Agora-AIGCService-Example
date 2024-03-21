//
//  ModulesTestingVC.swift
//
//
//  Created by ZYP on 2023/10/18.
//

import UIKit
import AgoraAIGCService
import RTMTokenBuilder
import AgoraRtcKit

class STTModulesTestingVC: UIViewController, AgoraAIGCServiceDelegate, RtcManagerDelegate {
    let mainView = MainView()
    var service: AgoraAIGCService!
    private let rtcManager = RtcManager()
    private let sttProviderName: String
    private let llmProviderName: String
    private let ttsProviderName: String
    
    init(sttProviderName: String,
         llmProviderName: String,
         ttsProviderName: String) {
        self.sttProviderName = sttProviderName
        self.llmProviderName = llmProviderName
        self.ttsProviderName = ttsProviderName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "stt:" + sttProviderName
        view.backgroundColor = .white
        view.addSubview(mainView)
        mainView.frame = view.bounds
        
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
    
    func setupRoleAndVendor() {
        let roles = service.getRoles()
        service.setRoleWithId(roles!.first!.roleId)
        let serviceVendor = findSpecificVendorGroup()
        service.setServiceVendor(serviceVendor)
    }
    
    func findSpecificVendorGroup() -> AgoraAIGCServiceVendor {
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
            if vendor.vendorName == llmProviderName {
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
            let info = MainView.Info(uuid: roundId, content: result.copy() as! String)
            mainView.addOrUpdateInfo(info: info)
        }
        return .discard
    }
    
    func onLLMResult(withRoundId roundId: String,
                     answer: NSMutableString,
                     isRoundEnd: Bool,
                     estimatedResponseTokens tokens: UInt,
                     code: AgoraAIGCServiceCode) -> AgoraAIGCHandleResult {
        return .discard
    }
    
    func onText2SpeechResult(withRoundId roundId: String,
                             voice: Data,
                             sampleRates: Int,
                             channels: Int,
                             bits: Int,
                             code: AgoraAIGCServiceCode) -> AgoraAIGCHandleResult {
        return .discard
    }
    
    // MARK: - RtcManagerDelegate
    func rtcManagerOnCaptureAudioFrame(frame: AgoraAudioFrame) {
        let count = frame.samplesPerChannel * frame.channels * frame.bytesPerSample
        let data = Data(bytes: frame.buffer!, count: count)
        service.pushSpeechDialogue(with: data, vad: .nonMute)
    }
    func rtcManagerOnVadUpdate(isSpeaking: Bool) {}
    func rtcManagerOnDebug(text: String) {}
    func rtcManagerOnCreatedRenderView(view: UIView) {}
}

