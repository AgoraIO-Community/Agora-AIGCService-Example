//
//  LanguageAssistantViewController.swift
//  AIGC-Examples
//
//  Created by ZYP on 2024/1/26.
//

import UIKit
import AgoraAIGCService
import RTMTokenBuilder
import AgoraRtcKit

class LanguageAssistantViewController: UIViewController {
    private var languageAssistantView: LanguageAssistantView!
    fileprivate var aigcManager: AIGCManager!
    private let rtcManager = RtcManager()
    fileprivate let promptGenerator: PromptGenerator
    fileprivate var config: MainViewController.Configurate!
    fileprivate var currentRequestType: RequestType = .none
    fileprivate var lastRecvRoundId: String = ""
    fileprivate var stringBuffer = ""
    fileprivate var currentOperationContentIndex: IndexPath = IndexPath()
    fileprivate var totalTokens: UInt = 0
    fileprivate var responseTokenDict = [String : UInt]()
    fileprivate var tokensInOneDialogDict = [String : UInt]()
    
    init(config: AIGCManager.Configurate,
         promptGenerator: PromptGenerator,
         preloadTipMessage: [String]) {
        self.aigcManager = AIGCManager(config: config)
        self.promptGenerator = promptGenerator
        self.languageAssistantView = LanguageAssistantView(frame: .zero, tipStrngs: preloadTipMessage)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("LanguageAssistantViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
        aigcManager.setupAndInitialize()
        initRtc()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(languageAssistantView)
        languageAssistantView.frame = view.bounds
        languageAssistantView.showTextField(show: true)
    }
    
    private func commonInit() {
        languageAssistantView.delegate = self
        aigcManager.delegate = self
    }
    
    private func initRtc() {
        rtcManager.delegate = self
        rtcManager.initEngine()
        rtcManager.joinChannel()
    }
    
    /// 添加开场白
    private func sendConversationStarterInView() {
        currentRequestType = .dialog
        let promptJsonString = promptGenerator.generateConversationStarterPromptString()
        let extraInfoJson = promptGenerator.extraInfoJson
        let ret = aigcManager.service.pushMessages(toLlm: promptJsonString,
                                                   extraInfoJson: extraInfoJson,
                                                   interruptDialogue: true)
        if ret != .success {
            print("sendConversationStarter fail \(ret.rawValue)")
        }
    }
    
    /// 发送对话类型的请求
    fileprivate func sendDialogPromptRequest(text: String) {
        currentRequestType = .dialog
        let item = PromptGenerator.Item(roleType: .user, content: text)
        promptGenerator.addDialog(item: item)
        let promptJsonString = promptGenerator.generateDialogPromptString(dialogShouldEndAtTime: false)
        let extraInfoJson = promptGenerator.extraInfoJson
        let ret = aigcManager.service.pushMessages(toLlm: promptJsonString,
                                                   extraInfoJson: extraInfoJson,
                                                   interruptDialogue: true)
        if ret != .success {
            print("sendDialogPromptRequest fail \(ret.rawValue)")
        }
    }
    
    /// 发送对话类型的请求(翻译)
    fileprivate func sendDialogWithTranslatedPromptRequest(content: String) {
        currentRequestType = .dialogWithTranslate
        let promptJsonString = promptGenerator.generateTranslatePromptString(content: content, lang: "中文")
        let extraInfoJson = promptGenerator.extraInfoJson
        let ret = aigcManager.service.pushMessages(toLlm: promptJsonString,
                                                   extraInfoJson: extraInfoJson,
                                                   interruptDialogue: true)
        if ret != .success {
            print("sendDialogWithTranslatedPromptRequest fail \(ret.rawValue)")
        }
    }
    
    /// 发送提示回到类型的请求
    fileprivate func sendTipPromptRequest() {
        guard promptGenerator.canSendTipPrompt else {
            return
        }
        currentRequestType = .tip
        let promptJsonString = promptGenerator.generateTipPromptString()
        let ret = aigcManager.service.pushMessages(toLlm: promptJsonString,
                                                   extraInfoJson: nil,
                                                   interruptDialogue: false)
        if ret != .success {
            print("sendTipPromptRequest fail \(ret.rawValue)")
        }
    }
    
    /// 发送润色类型的请求
    fileprivate func sendPolishPromptRequest(content: String) {
        currentRequestType = .polish
        let promptJsonString = promptGenerator.generatePolishPromptString(content: content)
        let ret = aigcManager.service.pushMessages(toLlm: promptJsonString,
                                                   extraInfoJson: nil,
                                                   interruptDialogue: false)
        if ret != .success {
            print("sendPolishPromptRequest fail \(ret.rawValue)")
        }
    }
    
    /// 发送翻译类型的请求
    fileprivate func sendTranslatedPromptRequest(content: String, indexPath: IndexPath) {
        currentRequestType = .translate
        currentOperationContentIndex = indexPath
        let promptJsonString = promptGenerator.generateTranslatePromptString(content: content)
        let ret = aigcManager.service.pushMessages(toLlm: promptJsonString,
                                                   extraInfoJson: nil,
                                                   interruptDialogue: false)
        if ret != .success {
            print("sendPolishPromptRequest fail \(ret.rawValue)")
        }
    }
    
    /// 发送引导对话结束的请求
    fileprivate func sendDialogEndIfNeed() {
        if totalTokens > 10000 {
            currentRequestType = .guideDialogEnd
            let promptJsonString = promptGenerator.generateDialogPromptString(dialogShouldEndAtTime: true)
            let extraInfoJson = promptGenerator.extraInfoJson
            let ret = aigcManager.service.pushMessages(toLlm: promptJsonString,
                                                       extraInfoJson: extraInfoJson,
                                                       interruptDialogue: false)
            if ret != .success {
                print("sendDialogEnd fail \(ret.rawValue)")
            }
        }
    }
    
    var count: UInt64 = 0
    private func genRoundId() -> String {
        if count == UInt64.max {
            count = 0
        }
        count += 1
        return "\(count)"
    }
}

extension LanguageAssistantViewController: LanguageAssistantViewDelegate {
    func languageAssistantView(_ view: LanguageAssistantView, didTapRecordingWith action: RecordingButton.RecordingStateAction) {
        switch action {
        case .start:
            aigcManager.service.pushMessages(toLlm: nil, extraInfoJson: nil, interruptDialogue: true)
            rtcManager.startRecord()
            break
        case .end, .cancel:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {[weak self] in
                guard let `self` = self else {
                    return
                }
                rtcManager.stopRecord()
            }
            break
        }
    }
    
    func languageAssistantViewShouldSendText(text: String) {
        let roundId = genRoundId()
        let info = LanguageAssistantView.Info(uuid: roundId, content: text, roleType: .user)
        let _ = languageAssistantView.addOrUpdateInfo(info: info)
        
        if String.isChinese(text: text) {
            sendDialogPromptRequest(text: text)
        }
        else {
            sendDialogWithTranslatedPromptRequest(content: text)
        }
    }
    
    func languageAssistantViewDidTapTipBtnAt(indexPath: IndexPath, content: String) {
        sendTipPromptRequest()
    }
    
    func languageAssistantViewDidTapPolishBtn(text: String) {
        sendPolishPromptRequest(content: text)
    }
    
    func languageAssistantViewDidTapTranslateBtn(text: String, at indexPath: IndexPath) {
        sendTranslatedPromptRequest(content: text, indexPath: indexPath)
    }
}

extension LanguageAssistantViewController: AIGCManagerDelegate {
    func onEventResult(with event: AgoraAIGCServiceEvent, code: AgoraAIGCServiceCode, message: String?) {
        print("====onEventResult:\(event) code:\(code) message:\(message ?? "")")
        if event == .start, code == .success {
            sendConversationStarterInView()
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
            let info = LanguageAssistantView.Info(uuid: roundId,
                                                  content: result.copy() as! String,
                                                  roleType: .user)
            let allText = languageAssistantView.addOrUpdateInfo(info: info)
            if recognizedSpeech {
                if String.isChinese(text: allText) {
                    sendDialogPromptRequest(text: allText)
                }
                else {
                    sendDialogWithTranslatedPromptRequest(content: allText)
                }
            }
        }
        return .discard
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
            let answerText = answer.copy() as! String
            responseTokenDict[roundId] = tokens
            let dialogRespTokens = responseTokenDict.map({ $0.value }).reduce(0, +) * 2
            let tokensInOneDialog = promptGenerator.promptToken + dialogRespTokens
            tokensInOneDialogDict[roundId] = tokensInOneDialog
            totalTokens = tokensInOneDialogDict.map({ $0.value }).reduce(0, +)
            print("=== estimatedResponseTokens:\(tokens) dialogRespTokens:\(dialogRespTokens) tokensInOneDialog:\(tokensInOneDialog) totalTokens:\(totalTokens) isRoundEnd:\(isRoundEnd) roundId:\(roundId)")
            languageAssistantView.setTokenString("\(rtcManager.channelId) \(totalTokens)")
            switch self.currentRequestType {
            case .dialog:
                let info = LanguageAssistantView.Info(uuid: roundId, content: answerText, roleType: .assistant)
                let allText = languageAssistantView.addOrUpdateInfo(info: info, isRoundEnd: isRoundEnd)
                if isRoundEnd {
                    let item = PromptGenerator.Item(roleType: .assistant, content: "”\(allText)“")
                    promptGenerator.addDialog(item: item)
                    sendDialogEndIfNeed()
                }
                break
            case .dialogWithTranslate:
                let info = LanguageAssistantView.Info(uuid: roundId,
                                                      content: answerText,
                                                      roleType: .assistant,
                                                      prifix: "你想说的应该是：")
                let allText = languageAssistantView.addOrUpdateInfo(info: info, isRoundEnd: isRoundEnd)
                if isRoundEnd {
                    var content = allText
                    content = content.replacingOccurrences(of: "你想说的应该是：", with: "")
                    let item = PromptGenerator.Item(roleType: .assistant, content: "”\(content)“")
                    promptGenerator.addDialog(item: item)
                    sendDialogPromptRequest(text: content)
                }
                break
            case .guideDialogEnd:
                let info = LanguageAssistantView.Info(uuid: roundId, content: answerText, roleType: .assistant)
                let allText = languageAssistantView.addOrUpdateInfo(info: info, isRoundEnd: isRoundEnd)
                if isRoundEnd {
                    let item = PromptGenerator.Item(roleType: .assistant, content: "”\(allText)“")
                    promptGenerator.addDialog(item: item)
                }
                break
            case .tip:
                stringBuffer += answerText
                if isRoundEnd {
                    stringBuffer.removeQuotationMarks()
                    languageAssistantView.setTip(stringBuffer)
                    stringBuffer = ""
                }
                break
            case .polish:
                stringBuffer += answerText
                if isRoundEnd {
                    stringBuffer.removeQuotationMarks()
                    languageAssistantView.setTip(stringBuffer)
                    stringBuffer = ""
                }
                break
            case .translate:
                stringBuffer += answerText
                if isRoundEnd {
                    languageAssistantView.updateTranslateText(stringBuffer, at: currentOperationContentIndex)
                    stringBuffer = ""
                }
                break
            case .none:
                break
            }
        }
        
        if currentRequestType == .dialogWithTranslate,
           lastRecvRoundId != roundId {
            /// 接收到dialogWithTranslate的第一个结果
            answer.insert("你想说的应该是：", at: 0)
        }
        lastRecvRoundId = roundId
        return (currentRequestType == .dialog || currentRequestType == .guideDialogEnd) ? .continue : .discard
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
            print("setPlayData roundId=\(roundId)")
            rtcManager.setPlayData(data: voice)
        }
        return .continue
    }
}

extension LanguageAssistantViewController: RtcManagerDelegate {
    func rtcManagerOnCaptureAudioFrame(frame: AgoraAudioFrame) {
        let count = frame.samplesPerChannel * frame.channels * frame.bytesPerSample
        let data = Data(bytes: frame.buffer!, count: count)
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            aigcManager.service.pushSpeechDialogue(with: data, vad: .nonMute)
        }
    }
    func rtcManagerOnCreatedRenderView(view: UIView) {}
    func rtcManagerOnDebug(text: String) {}
}

extension String {
    /// 移除字符串中前后的中、英文双引号
    mutating func removeQuotationMarks() {
        if first == "“" && last == "”" {
            removeFirst()
            removeLast()
        }
        if first == "\"" && last == "\"" {
            removeFirst()
            removeLast()
        }
    }
    
    mutating func removeQuotationMarks2() {
        if first == "“" {
            removeFirst()
        }
        
        if last == "”" {
            removeLast()
        }
        
        if first == "\""  {
            removeFirst()
        }
        
        if last == "\"" {
            removeLast()
        }
    }
    
    static func isChinese(text: String) -> Bool {
        // 创建中文字符和中文标点符号的正则表达式
        let chinesePattern = "[\\p{Script=Han}\\p{P}\\p{Z}，。？！“”‘’；：—「」『』（）【】《》〈〉]"
        let chineseRegex = try! NSRegularExpression(pattern: chinesePattern)
        
        // 遍历字符串中的每个字符
        for scalar in text.unicodeScalars {
            let str = String(scalar)
            
            // 检查字符是否匹配中文字符或中文标点符号
            let chineseMatches = chineseRegex.matches(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count))
            
            // 检查字符是否是阿拉伯数字
            let isDigit = scalar.isASCII && scalar.value >= 48 && scalar.value <= 57 // ASCII中的数字范围是'0'到'9'
            
            // 如果字符既不是中文字符也不是中文标点符号，也不是阿拉伯数字，返回false
            if chineseMatches.isEmpty && !isDigit {
                return false
            }
        }
        
        // 如果所有字符都通过了检查，返回true
        return true
    }
    
    static func testCase() {
        assert(String.isChinese(text: "测试") == true)
        assert(String.isChinese(text: "test") == false)
        assert(String.isChinese(text: "好啊！今天去，怎么样？") == true)
        assert(String.isChinese(text: "好啊!今天去,怎么样?") == true)
        assert(String.isChinese(text: "好啊aa") == false)
        assert(String.isChinese(text: "what is your name?") == false)
        assert(String.isChinese(text: "what is your name？") == false)
        assert(String.isChinese(text: "我有1000元") == true)
        assert(String.isChinese(text: "1000") == true)
    }
}
