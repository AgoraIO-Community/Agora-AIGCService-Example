//
//  Statistic.swift
//  GPT-Demo
//
//  Created by ZYP on 2023/8/31.
//

import Foundation

class Statistic {
    enum Domain: Int {
        case stt
        case gpt
        case tts
    }
    
    static let share = Statistic()
    private var dict = [Int : Int]()
    
    func start(domain: Domain) {
        Log.debug(text: "start \(domain.rawValue)", tag: "Statistic")
        let startTime = Int(DispatchTime.now().uptimeNanoseconds / 1_000_000)
        dict[domain.rawValue] = startTime
        if domain == .stt {
            Log.info(text: "== start:\(startTime)", tag: "Statistic")
        }
        
    }
    
    /// stop Statistic
    /// - Returns: gap between start and stop
    func stop(domain: Domain) -> Int? {
        Log.debug(text: "stop \(domain.rawValue)", tag: "Statistic")
        guard let startTime = dict[domain.rawValue] else {
            return nil
        }
        dict.removeValue(forKey: domain.rawValue)
        let endTime = Int(DispatchTime.now().uptimeNanoseconds / 1_000_000)
        let time = endTime - startTime
        
        if domain == .stt {
            Log.info(text: "== endTime:\(endTime)", tag: "Statistic")
            Log.info(text: "== gap \(endTime) - \(startTime) = \(time)", tag: "Statistic")
        }
        
        return time
    }
}
