//
//  LoginViewController.swift
//  AIGC-Examples
//
//  Created by ZYP on 2023/11/13.
//

import UIKit
import AgoraAIGCService

class ConfigSettingViewController: UIViewController {
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var langBtn: UIButton!
    @IBOutlet weak var sttTextField: UITextField!
    @IBOutlet weak var llmTextField: UITextField!
    @IBOutlet weak var ttsTextField: UITextField!
    @IBOutlet weak var speechRecognitionFiltersLengthTextField: UITextField!
    @IBOutlet weak var customPromptTextField: UITextField!
    @IBOutlet weak var enableMultiTurnShortTermMemorySwitch: UISwitch!
    @IBOutlet weak var roleIdTextField: UITextField!
    @IBOutlet weak var enableSTTSwitch: UISwitch!
    @IBOutlet weak var enableTTSSwitch: UISwitch!
    @IBOutlet weak var noiseEnvTextField: UITextField!
    @IBOutlet weak var speechRecCompTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.text = "小李"
        roleIdTextField.text = "yunibobo-zh-CN"
        langBtn.setTitle("中文", for: .normal)
        sttTextField.text = "xunfei"
        llmTextField.text = "minimax-abab5.5-chat"
        ttsTextField.text = "microsoft"
        speechRecognitionFiltersLengthTextField.text = "3"
        enableMultiTurnShortTermMemorySwitch.isOn = true
        noiseEnvTextField.text = "2"
        speechRecCompTextField.text = "1"
    }
    
    @IBAction func btnOnclick(_ sender: UIButton) {
        if sender == langBtn {
            let newTitle = sender.title(for: .normal) == "中文" ? "英文" : "中文"
            sender.setTitle(newTitle, for: .normal)
            return
        }
        
        let language: AgoraAIGCLanguage = langBtn.title(for: .normal) == "中文" ? .ZH_CN : .EN_US
        let customPrompt: String? = customPromptTextField.text?.isEmpty ?? false ? nil : customPromptTextField.text!
        let config = MainViewController.Configurate(sttProviderName: sttTextField.text!,
                                                    llmProviderName: llmTextField.text!,
                                                    ttsProviderName: ttsTextField.text!,
                                                    roleId: roleIdTextField.text!,
                                                    inputLang: language,
                                                    outputLang: language,
                                                    userName: userNameTextField.text!,
                                                    customPrompt: customPrompt,
                                                    enableMultiTurnShortTermMemory: enableMultiTurnShortTermMemorySwitch.isOn,
                                                    speechRecognitionFiltersLength: UInt(speechRecognitionFiltersLengthTextField.text!) ?? 3,
                                                    enableSTT: enableSTTSwitch.isOn,
                                                    enableTTS: enableTTSSwitch.isOn,
                                                    noiseEnv: AgoraNoiseEnvironment(rawValue: UInt(noiseEnvTextField.text ?? "2")!)!,
                                                    speechRecCompLevel: AgoraSpeechRecognitionCompletenessLevel(rawValue: UInt(speechRecCompTextField.text ?? "1")!)!)
        let vc = MainViewController(config: config)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
