//
//  MessageInputView.swift
//  AIGC-Examples
//
//  Created by ZYP on 2024/2/28.
//

import UIKit

protocol MessageInputViewDelegate: NSObjectProtocol {
    func messageInputView(_ view: MessageInputView, didTapSendBtnWith text: String)
    func messageInputView(_ view: MessageInputView, didTapPolishBtnWith text: String)
    func messageInputView(_ view: MessageInputView, didTapRecordingWith action: RecordingButton.RecordingStateAction)
}

class MessageInputView: UIView {
    private var inputTipSelectedView: TipSelectedView!
    private let textField = UITextView()
    private let recordingButton = RecordingButton()
    private let polishBtn = UIButton()
    private let inputSwitchButton = UIButton()
    private let tokenLabel = UILabel()
    weak var delegate: MessageInputViewDelegate?
    
    init(tipStrngs: [String]) {
        super.init(frame: .zero)
        inputTipSelectedView = TipSelectedView(frame: .zero, dataArray: tipStrngs)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(inputTipSelectedView)
        inputTipSelectedView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(recordingButton)
        recordingButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(polishBtn)
        polishBtn.translatesAutoresizingMaskIntoConstraints = false
        addSubview(inputSwitchButton)
        inputSwitchButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tokenLabel)
        tokenLabel.translatesAutoresizingMaskIntoConstraints = false
        
//        textField.borderStyle = .roundedRect
//        textField.placeholder = "请输入内容"
        textField.layer.cornerRadius = 5
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 1
        textField.returnKeyType = .send
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .black
        polishBtn.isHidden = true
        polishBtn.setTitle("润色", for: .normal)
        polishBtn.setTitleColor(.white, for: .normal)
        polishBtn.backgroundColor = .orange
        polishBtn.showsTouchWhenHighlighted = true
        recordingButton.isHidden = true
        inputSwitchButton.setImage(UIImage(named: "键盘"), for: .selected)
        inputSwitchButton.setImage(UIImage(named: "语音"), for: .normal)
        
        inputTipSelectedView.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
        inputTipSelectedView.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
        inputTipSelectedView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        inputTipSelectedView.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        inputSwitchButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        inputSwitchButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor).isActive = true
        inputSwitchButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        inputSwitchButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        textField.leftAnchor.constraint(equalTo: inputSwitchButton.rightAnchor, constant: 0).isActive = true
        textField.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
        textField.topAnchor.constraint(equalTo: inputTipSelectedView.bottomAnchor).isActive = true
        textField.bottomAnchor.constraint(equalTo: polishBtn.topAnchor, constant: -5).isActive = true
        
        recordingButton.leftAnchor.constraint(equalTo: textField.leftAnchor).isActive = true
        recordingButton.rightAnchor.constraint(equalTo: textField.rightAnchor).isActive = true
        recordingButton.topAnchor.constraint(equalTo: textField.topAnchor).isActive = true
        recordingButton.bottomAnchor.constraint(equalTo: textField.bottomAnchor).isActive = true
        
        polishBtn.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
        polishBtn.widthAnchor.constraint(equalToConstant: 60).isActive = true
        polishBtn.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 5).isActive = true
        polishBtn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        
        tokenLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        tokenLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    private func commonInit() {
        polishBtn.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        inputSwitchButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        inputTipSelectedView.delegate = self
        textField.delegate = self
        recordingButton.delegate = self
//        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        if sender == polishBtn {
            if let content = textField.text {
                delegate?.messageInputView(self, didTapPolishBtnWith: content)
            }
        } else {
            if inputSwitchButton.isSelected {
                inputSwitchButton.isSelected = false
                textField.isHidden = false
                recordingButton.isHidden = true
            } else {
                inputSwitchButton.isSelected = true
                textField.isHidden = true
                recordingButton.isHidden = false
            }
        }
    }
    
    func setTip(_ tip: String) {
        if inputSwitchButton.isSelected {
            inputSwitchButton.isSelected = false
            textField.isHidden = false
            recordingButton.isHidden = true
        }
        textField.text = tip
        polishBtn.isHidden = true
    }
    
    func setTokenString(_ tokenString: String) {
        tokenLabel.text = tokenString
        tokenLabel.font = .systemFont(ofSize: 11)
        tokenLabel.textColor = .gray
    }
}

extension MessageInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        polishBtn.isHidden = textView.text?.count ?? 0 == 0
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 检查 replacementText 是否为换行符，即用户按下了 return 键
        if text == "\n" {
            // 在这里处理 return 键点击事件
            textView.resignFirstResponder() // 隐藏键盘
            delegate?.messageInputView(self, didTapSendBtnWith: textField.text ?? "")
            textField.text = ""
            polishBtn.isHidden = true
            return false // 阻止插入换行符，如果你不想在文本视图中添加新行
        }
        return true // 允许其他文本更改
    }
}

//extension MessageInputView: UITextFieldDelegate {
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        delegate?.messageInputView(self, didTapSendBtnWith: textField.text ?? "")
//        textField.text = ""
//        polishBtn.isHidden = true
//        return true
//    }
//
//    /// 监听 textField的输入text变化
//    @objc func textFieldDidChange(_ textField: UITextField) {
//        polishBtn.isHidden = textField.text?.count ?? 0 == 0
//    }
//}

extension MessageInputView: TipSelectedViewDelegate {
    func tipSelectedView(_ view: TipSelectedView, didSelectContent content: String) {
        if inputSwitchButton.isSelected {
            inputSwitchButton.isSelected = false
            textField.isHidden = false
            recordingButton.isHidden = true
        }
        textField.text = content
        textField.becomeFirstResponder()
        polishBtn.isHidden = false
    }
}

extension MessageInputView: RecordingButtonDelegate {
    func recordingDidTap(_ button: RecordingButton, action: RecordingButton.RecordingStateAction) {
        delegate?.messageInputView(self, didTapRecordingWith: action)
    }
}
