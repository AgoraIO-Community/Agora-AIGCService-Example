//
//  LanguageAssistantLevelSelectedViewController.swift
//  AIGC-Examples
//
//  Created by ZYP on 2024/2/29.
//

import UIKit

class LanguageAssistantLevelSelectedViewController: UIViewController {
    struct Section {
        let title: String
        let rows: [Row]
    }
    
    struct Row {
        let title: String
    }
    
    struct LevelItem: Codable {
        let level: String
        let prompt: String
        let preloadTipMessage: [String]
        let userName: String
        let teacherName: String
        let promptToken: UInt
        let llmExtraInfoJson: String
        let topic: String
    }
    
    let tableview = UITableView(frame: .zero, style: .grouped)
    var list = [Section]()
    
    /// 提示部分
    var promptTipSlic: String!
    /// 润色部分
    var promptPolishSlic: String!
    /// 翻译部分
    var promptTranslateSlic: String!
    /// 引导对话结束
    var promptDialogEnd: String!
    
    var levelItems = [LevelItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createData()
        setupUI()
        commonInit()
    }
    
    func setupUI() {
        title = "分级选择"
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
        list = [Section(title: "GPT3.5", rows: [.init(title: "A"),
                                                .init(title: "B"),
                                                .init(title: "C"),
                                                .init(title: "D")]),
                Section(title: "GPT4", rows: [.init(title: "A"),
                                              .init(title: "B"),
                                              .init(title: "C"),
                                              .init(title: "D")])]
        
        
        let path = Bundle.main.path(forResource: "teacher_level.json", ofType: nil)
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        levelItems = try! JSONDecoder().decode([LevelItem].self, from: data)
        
        promptTipSlic = """
      {  \"role\": \"system\",  \"content\": \"[将您的下一条回复从{{user}}的角度写出。请以迄今为止的聊天记录作为指导，模仿{{user}}的写作风格，参照本次对话的语言水平，来回答{{teacher}}的这句话:{{last_response}}。请以{{user}}的身份回复。]\"}
"""
        
        promptPolishSlic = """
    {  \"role\": \"system\",  \"content\": \"[请你润色、改善{{user}}的这一句发言:{{last_response}}。你应当以迄今为止的聊天记录作为指导，参照本次对话的语言水平进行润色。请以{{user}}的身份回复]\"}
"""
        
        promptTranslateSlic = """
    {    \"role\": \"system\",    \"content\": \"请你将以下文本翻译成{{language}}后直接输出结果。你翻译后的结果必须通顺、地道且符合该语言的表达方式:{{last_response}}\"}
"""
        
        promptDialogEnd = """
 {    \"role\": \"system\",    \"content\": \"你扮演的角色{{teacher}}现在需要离开，请在回复中编造一个要离开的理由，并相约回头继续聊刚刚的话题，最后说再见。\"}
"""
    }
    
}

extension LanguageAssistantLevelSelectedViewController: UITableViewDelegate, UITableViewDataSource {
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
        
        let config = AIGCManager.Configurate(sttProviderName: "microsoft",
                                             llmProviderName: indexPath.section == 0 ? "azureOpenai-gpt-35-turbo-16k" : "azureOpenai-gpt-4",
                                             ttsProviderName: "microsoft",
                                             roleId: "ai_teaching_assistant-zh-CN",
                                             inputLang: .ZH_CN,
                                             outputLang: .ZH_CN,
                                             userName: "XiaoLi",
                                             customPrompt: nil,
                                             enableMultiTurnShortTermMemory: true,
                                             speechRecognitionFiltersLength:3,
                                             enableSTT: false,
                                             enableTTS: false,
                                             noiseEnv: .noise,
                                             speechRecCompLevel: .normal,
                                             continueToHandleLLM: true,
                                             continueToHandleTTS: true)
        let promptGenerator = PromptGenerator(teacherName: levelItems[indexPath.row].teacherName,
                                              userName: levelItems[indexPath.row].userName,
                                              promptDialog: levelItems[indexPath.row].prompt,
                                              promptTipSlic: promptTipSlic,
                                              promptPolishSlic: promptPolishSlic,
                                              promptTranslateSlic: promptTranslateSlic,
                                              promptDialogEnd: promptDialogEnd,
                                              promptToken: levelItems[indexPath.row].promptToken,
                                              extraInfoJson: levelItems[indexPath.row].llmExtraInfoJson)
        
        let vc = LanguageAssistantViewController(config: config,
                                                 promptGenerator: promptGenerator,
                                                 preloadTipMessage: levelItems[indexPath.row].preloadTipMessage)
        
        let llmName = indexPath.section == 0 ? "(GPT3.5)" : "(GPT4)"
        let topic = "(\(levelItems[indexPath.row].topic))"
        vc.title = "级别" + levelItems[indexPath.row].level + llmName + topic
        navigationController?.pushViewController(vc, animated: true)
    }
}
