//
//  RtcManager.swift
//  GPT-Demo
//
//  Created by ZYP on 2023/7/28.
//

import AgoraRtcKit
import RTMTokenBuilder

protocol RtcManagerDelegate: NSObjectProtocol {
    func rtcManagerOnCreatedRenderView(view: UIView)
    func rtcManagerOnCaptureAudioFrame(frame: AgoraAudioFrame)
    func rtcManagerOnDebug(text: String)
}

class RtcManager: NSObject {
    fileprivate var agoraKit: AgoraRtcEngineKit!
    weak var delegate: RtcManagerDelegate?
    fileprivate var isRecord = false
    private var soundQueue = Queue<Data>()
    fileprivate let logTag = "RtcManager"
    
    deinit {
        agoraKit.leaveChannel()
        print("RtcManager deinit")
    }
    
    func initEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Config.appId
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        
        agoraKit.setChannelProfile(.liveBroadcasting)
        agoraKit.setClientRole(.broadcaster)
        agoraKit.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
        agoraKit.setAudioScenario(.gameStreaming)
        
        agoraKit.setParameters("{\"rtc.debug.enable\":true}")
        // 开启AI降噪soft模式
        agoraKit.setParameters("{\"che.audio.enable.nsng\": true}")
        agoraKit.setParameters("{\"che.audio.ains_mode\": 2}")
        agoraKit.setParameters("{\"che.audio.ns_mode\": 2}")
        agoraKit.setParameters("{\"che.audio.nsng.lowerBound\": 80}")
        agoraKit.setParameters("{\"che.audio.nsng.lowerMask\": 50}")
        agoraKit.setParameters("{\"che.audio.nsng.statisitcalbound\": 5}")
        agoraKit.setParameters("{\"che.audio.nsng.finallowermask\": 30}")
    }
    
    func joinChannel() {
        let token = TokenBuilder.rtcToken2(Config.appId,
                                           appCertificate: Config.certificate,
                                           uid: Int32(Config.hostUid),
                                           channelName: Config.channelId)
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        agoraKit.setAudioFrameDelegate(self)
        agoraKit.enableAudio()
        let ret = agoraKit.joinChannel(byToken: token,
                                       channelId: Config.channelId,
                                       uid: Config.hostUid,
                                       mediaOptions: option)
        if ret != 0 {
            let text = "joinChannel ret \(ret)"
            Log.errorText(text: text, tag: logTag)
        }
    }
    
    func startRecord() {
        isRecord = true
    }
    
    func stopRecord() {
        isRecord = false
    }
    
    func setPlayData(data: Data) {
        soundQueue.enqueue(data)
    }
}

extension RtcManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        Log.errorText(text: "didOccurError \(errorCode)", tag: logTag)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        let text = "didJoinedOfUid \(uid)"
        Log.info(text: text, tag: logTag)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        let text = "didJoinChannel withUid \(uid)"
        Log.info(text: text, tag: logTag)
    }
}

extension RtcManager: AgoraAudioFrameDelegate {
    func onEarMonitoringAudioFrame(_ frame: AgoraAudioFrame) -> Bool {
        true
    }
    
    func getEarMonitoringAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams ()
        params.sampleRate = 16000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 640
        return params
    }
    
    func getRecordAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams()
        params.sampleRate = 16000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 640
        return params
    }
    
    func onRecordAudioFrame(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        if self.isRecord {
            self.delegate?.rtcManagerOnCaptureAudioFrame(frame: frame)
        }
        return true
    }
    
    func onRecord(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        return true
    }
    
    func getPlaybackAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams()
        params.sampleRate = 16000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 640
        return params
    }
    
    func getObservedAudioFramePosition() -> AgoraAudioFramePosition {
        return [.record, .playback]
    }
    
    func onPlaybackAudioFrame(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        if let data = soundQueue.dequeue() {
            data.withUnsafeBytes { rawBufferPointer in
                let rawPtr = rawBufferPointer.baseAddress!
                let bufferPtr = UnsafeMutableRawPointer(frame.buffer)
                bufferPtr?.copyMemory(from: rawPtr, byteCount: data.count)
            }
        }
        return true
    }
    
    func onMixedAudioFrame(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        return true
    }
    
    func getMixedAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams()
        params.sampleRate = 16000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 640
        return params
    }
    
    func onPlaybackAudioFrame(beforeMixing frame: AgoraAudioFrame, channelId: String, uid: UInt) -> Bool {
        return true
    }
}

struct Queue<T> {
    private var elements: [T] = []
    private let semaphore = DispatchSemaphore(value: 1) // 创建信号量
    private let logTag = "Queue"
    
    mutating func enqueue(_ element: T) {
        semaphore.wait() // 等待信号量
        elements.append(element)
//        Log.debug(text: "enqueue count = \(elements.count)", tag: logTag)
        semaphore.signal() // 发送信号量
    }
    
    mutating func reset() {
        semaphore.wait() // 等待信号量
        elements.removeAll()
//        Log.debug(text: "reset count = \(elements.count)", tag: logTag)
        semaphore.signal() // 发送信号量
    }
    
    mutating func dequeue() -> T? {
        semaphore.wait()
        defer { semaphore.signal() } // 在方法结束前发送信号量
        let t = elements.isEmpty ? nil : elements.removeFirst()
//        let text = t == nil ? "nil" : "one"
//        Log.debug(text: "dequeue \(text)  count = \(elements.count)", tag: logTag)
        return t
    }
    
    func peek() -> T? {
        semaphore.wait()
        defer { semaphore.signal() }
        return elements.first
    }
    
    func isEmpty() -> Bool {
        semaphore.wait()
        defer { semaphore.signal() }
        return elements.isEmpty
    }
    
    func count() -> Int {
        semaphore.wait()
        defer { semaphore.signal() }
        return elements.count
    }
}

extension RtcManager {
    func invokeRtcManagerOnDebug(text: String) {
        if Thread.isMainThread {
            self.delegate?.rtcManagerOnDebug(text: text)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.rtcManagerOnDebug(text: text)
        }
    }
}
