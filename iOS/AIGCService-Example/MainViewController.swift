//
//  MainViewController.swift
//
//
//  Created by ZYP on 2023/10/18.
//

import UIKit
import AIGCService
import RTMTokenBuilder
import AgoraRtcKit

class MainViewController: UIViewController, AIGCServiceDelegate, RtcManagerDelegate {
    let mainView = MainView()
    var service: AIGCService!
    private let rtcManager = RtcManager()
    private let sttProviderName: String
    private let llmProviderName: String
    private let ttsProviderName: String
    
    init(sttProviderName: String, llmProviderName: String, ttsProviderName: String) {
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
        title = sttProviderName + "+" + llmProviderName + "+" + ttsProviderName
        view.backgroundColor = .white
        view.addSubview(mainView)
        mainView.frame = view.bounds
        
        initRtc()
        initAIGC()
    }
    
    deinit {
        service.stop()
        AIGCService.destory()
    }
    
    private func initRtc() {
        rtcManager.delegate = self
        rtcManager.initEngine()
        rtcManager.joinChannel()
    }
    
    private func initAIGC() {
        service = AIGCService.create()
        let uid = "123"
        let appId = Config.appId
        let cer = Config.certificate
        let token = TokenBuilder.buildRtmToken(appId,
                                               appCertificate: cer,
                                               userUuid: uid)
        
        let input = AIGCSceneMode(language: "zh-CN",
                                  speechFrameBits: 16,
                                  speechFrameSampleRates: 16000,
                                  speechFrameChannels: 1)
        let output = AIGCSceneMode(language: "zh-CN",
                                   speechFrameBits: 16,
                                   speechFrameSampleRates: 16000,
                                   speechFrameChannels: 1)
        
        let config = AIGCConfigure(appId: appId,
                                   rtmToken: token,
                                   userId: uid,
                                   enableMultiTurnShortTermMemory: false,
                                   speechRecognitionFiltersLength: 3,
                                   input: input,
                                   output: output,
                                   enableLog: true,
                                   enableSaveLogToFile: true,
                                   userName: "小李")
        service.delegate = self
        service.initialize(config)
    }
    
    func setupRoleAndVendor() {
        let roles = service.getRoles()
        service.setRoleWithId(roles!.first!.roleId)
        let serviceVendor = findSpecificVendorGroup()
        service.setServiceVendor(serviceVendor)
    }
    
    func findSpecificVendorGroup() -> AIGCServiceVendor {
        guard let vendors = service.getVendors() else {
            fatalError("getVendors ret nil")
        }
        
        var stt: AIGCSTTVendor?
        var llm: AIGCLLMVendor?
        var tts: AIGCTTSVendor?
        
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
        
        return AIGCServiceVendor(stt: stt!, llm: llm!, tts: tts!)
    }
    
    // MARK: - AIGCServiceDelegate

    func onEventResult(with event: AIGCServiceEvent, code: AIGCServiceCode, message: String?) {
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
                       result: String,
                       recognizedSpeech: Bool) -> AIGCHandleResult {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            print("====onSpeech2Text:\(result) recognizedSpeech:\(recognizedSpeech)")
            let info = MainView.Info(uuid: roundId, content: result)
            mainView.addOrUpdateInfo(info: info)
        }
        return .continue
    }
    
    func onLLMResult(withRoundId roundId: String, answer: String) -> AIGCHandleResult {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            let info = MainView.Info(uuid: "llm" + roundId, content: answer)
            mainView.addOrUpdateInfo(info: info)
        }
        return .continue
    }
    
    func onText2SpeechResult(withRoundId roundId: String, voice: Data, sampleRates: Int, channels: Int, bits: Int) -> AIGCHandleResult {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            rtcManager.setPlayData(data: voice)
        }
        return .continue
    }
    
    // MARK: - RtcManagerDelegate
    func rtcManagerOnCaptureAudioFrame(frame: AgoraAudioFrame) {
        let count = frame.samplesPerChannel * frame.channels * frame.bytesPerSample
        let data = Data(bytes: frame.buffer!, count: count)
        service.pushSpeechDialogue(with: data, vad: 0)
    }
    func rtcManagerOnVadUpdate(isSpeaking: Bool) {}
    func rtcManagerOnDebug(text: String) {}
    func rtcManagerOnCreatedRenderView(view: UIView) {}
}
