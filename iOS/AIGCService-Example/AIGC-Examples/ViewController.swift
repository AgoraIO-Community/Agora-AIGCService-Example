//
//  ViewController.swift
//  Demo
//
//  Created by ZYP on 2022/12/21.
//

import UIKit

class ViewController: UIViewController {
    
    struct Section {
        let title: String
        let rows: [Row]
    }
    
    struct Row {
        let title: String
    }
    
    let tableview = UITableView(frame: .zero, style: .grouped)
    var list = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createData()
        setupUI()
        commonInit()
    }
    
    func setupUI() {
        title = "AIGC Test"
        view.addSubview(tableview)
        tableview.translatesAutoresizingMaskIntoConstraints = false
        
        tableview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    func commonInit() {
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.reloadData()
    }
    
    func createData() {
        list = [
//            Section(title: "集成测试", rows: [.init(title: "xf+mm+ms"),
//                                          .init(title: "[no use]ms+mm+elabs"),
//                                          .init(title: "xf+(azureOpenai-gpt-4)+ms"),
//                                          .init(title: "ms+mm+ms"),
//                                          .init(title: "xf+mm+volc"),
//                                          .init(title: "xf+mm+xf"),
//                                          .init(title: "自定义")]),
//            Section(title: "模块测试", rows: [.init(title: "stt(xf)"),
//                                          .init(title: "stt(ms)"),
//                                          .init(title: "llm(mm)"),
//                                          .init(title: "tts(ms)"),
//                                          .init(title: "tts(elabs)"),
//                                          .init(title: "tts(volc)"),
//                                          .init(title: "tts(xf)")]),
            Section(title: "场景", rows: [.init(title: "语言助手")])
        ]
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        list[section].title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        list.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = list[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
//        if indexPath.section == 0 {
//            if indexPath.row == 0 {
//                let config = MainViewController.Configurate(sttProviderName: "xunfei",
//                                                            llmProviderName: "minimax-abab5.5-chat",
//                                                            ttsProviderName: "microsoft",
//                                                            roleId: "yunibobo-zh-CN",
//                                                            inputLang: .ZH_CN,
//                                                            outputLang: .ZH_CN,
//                                                            userName: "小李",
//                                                            customPrompt: nil,enableMultiTurnShortTermMemory: true,
//                                                            speechRecognitionFiltersLength:3,
//                                                            enableSTT: true,
//                                                            enableTTS: true,
//                                                            noiseEnv: .noise,
//                                                            speechRecCompLevel: .normal)
//                let vc = MainViewController(config: config)
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//            if indexPath.row == 1 {
//                let config = MainViewController.Configurate(sttProviderName: "xunfei",
//                                                            llmProviderName: "minimax-abab5.5-chat",
//                                                            ttsProviderName: "elevenLabs",
//                                                            roleId: "yunibobo-zh-CN",
//                                                            inputLang: .ZH_CN,
//                                                            outputLang: .ZH_CN,
//                                                            userName: "小李",
//                                                            customPrompt: nil,enableMultiTurnShortTermMemory: true,
//                                                            speechRecognitionFiltersLength:3,
//                                                            enableSTT: true,
//                                                            enableTTS: true,
//                                                            noiseEnv: .noise,
//                                                            speechRecCompLevel: .normal)
//                let vc = MainViewController(config: config)
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//            if indexPath.row == 2 {
//                let config = MainViewController.Configurate(sttProviderName: "xunfei",
//                                                            llmProviderName: "azureOpenai-gpt-35-turbo-16k",//"azureOpenai-gpt-4",
//                                                            ttsProviderName: "microsoft",
//                                                            roleId: "game-situation_puzzle-1-zh-CN",//"game-you_perform_and_i_guess-3-zh-CN",
//                                                            inputLang: .ZH_CN,
//                                                            outputLang: .ZH_CN,
//                                                            userName: "XiaoLi",
//                                                            customPrompt: nil,
//                                                            enableMultiTurnShortTermMemory: true,
//                                                            speechRecognitionFiltersLength:3,
//                                                            enableSTT: false,
//                                                            enableTTS: false,
//                                                            noiseEnv: .noise,
//                                                            speechRecCompLevel: .normal)
//                let vc = MainViewController(config: config)
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//            if indexPath.row == 3 {
//                let config = MainViewController.Configurate(sttProviderName: "microsoft",
//                                                            llmProviderName: "minimax-abab5.5-chat",
//                                                            ttsProviderName: "microsoft",
//                                                            roleId: "yunibobo-zh-CN",
//                                                            inputLang: .ZH_CN,
//                                                            outputLang: .ZH_CN,
//                                                            userName: "小李",
//                                                            customPrompt: nil,enableMultiTurnShortTermMemory: true,
//                                                            speechRecognitionFiltersLength:3,
//                                                            enableSTT: true,
//                                                            enableTTS: true,
//                                                            noiseEnv: .noise,
//                                                            speechRecCompLevel: .normal)
//                let vc = MainViewController(config: config)
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//            if indexPath.row == 4 {
//                let config = MainViewController.Configurate(sttProviderName: "xunfei",
//                                                            llmProviderName: "minimax-abab5.5-chat",
//                                                            ttsProviderName: "volcEngine",
//                                                            roleId: "yunibobo-zh-CN",
//                                                            inputLang: .ZH_CN,
//                                                            outputLang: .ZH_CN,
//                                                            userName: "小李",
//                                                            customPrompt: nil,enableMultiTurnShortTermMemory: true,
//                                                            speechRecognitionFiltersLength:3,
//                                                            enableSTT: true,
//                                                            enableTTS: true,
//                                                            noiseEnv: .noise,
//                                                            speechRecCompLevel: .normal)
//                let vc = MainViewController(config: config)
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//            if indexPath.row == 5 {
//                let config = MainViewController.Configurate(sttProviderName: "xunfei",
//                                                            llmProviderName: "minimax-abab5.5-chat",
//                                                            ttsProviderName: "xunfei",
//                                                            roleId: "yunibobo-zh-CN",
//                                                            inputLang: .ZH_CN,
//                                                            outputLang: .ZH_CN,
//                                                            userName: "小李",
//                                                            customPrompt: nil,enableMultiTurnShortTermMemory: true,
//                                                            speechRecognitionFiltersLength:3,
//                                                            enableSTT: true,
//                                                            enableTTS: true,
//                                                            noiseEnv: .noise,
//                                                            speechRecCompLevel: .normal)
//                let vc = MainViewController(config: config)
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//            if indexPath.row == 6 {
//                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                let vc = storyboard.instantiateViewController(withIdentifier: "ConfigSettingViewController") as! ConfigSettingViewController
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//        }
//
//        if indexPath.section == 1 {
//            if indexPath.row == 0 {
//                let vc = STTModulesTestingVC(sttProviderName:"xunfei",
//                                             llmProviderName:"minimax",
//                                             ttsProviderName:"microsoft")
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//
//            if indexPath.row == 1 {
//                let vc = STTModulesTestingVC(sttProviderName:"microsoft",
//                                             llmProviderName:"minimax",
//                                             ttsProviderName:"microsoft")
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//
//            if indexPath.row == 2 {
//                let vc = LLMModulesTestingVC(sttProviderName:"microsoft",
//                                             llmProviderName:"minimax",
//                                             ttsProviderName:"microsoft")
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//
//            if indexPath.row == 3 {
//                let vc = TTSModulesTestingVC(sttProviderName:"microsoft",
//                                             llmProviderName:"minimax",
//                                             ttsProviderName:"microsoft")
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//
//            if indexPath.row == 4 {
//                let vc = TTSModulesTestingVC(sttProviderName:"microsoft",
//                                             llmProviderName:"minimax",
//                                             ttsProviderName:"elevenLabs")
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//
//            if indexPath.row == 5 {
//                let vc = TTSModulesTestingVC(sttProviderName:"microsoft",
//                                             llmProviderName:"minimax",
//                                             ttsProviderName:"volcEngine")
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//
//            if indexPath.row == 6 {
//                let vc = TTSModulesTestingVC(sttProviderName:"microsoft",
//                                             llmProviderName:"minimax",
//                                             ttsProviderName:"xunfei")
//                navigationController?.pushViewController(vc, animated: true)
//                return
//            }
//        }
        
//        if indexPath.section == 2 {
//            if indexPath.row == 0 {
                let vc = LanguageAssistantLevelSelectedViewController()
                navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }
}
