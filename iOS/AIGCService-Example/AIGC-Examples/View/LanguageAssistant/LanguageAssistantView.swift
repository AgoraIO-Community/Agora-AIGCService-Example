//
//  LanguageAssistantView.swift
//  AIGC-Examples
//
//  Created by ZYP on 2024/1/29.
//

import UIKit

protocol LanguageAssistantViewDelegate: NSObjectProtocol {
    func languageAssistantViewShouldSendText(text: String)
    func languageAssistantViewDidTapTipBtnAt(indexPath: IndexPath, content: String)
    func languageAssistantViewDidTapPolishBtn(text: String)
    func languageAssistantViewDidTapTranslateBtn(text: String, at indexPath: IndexPath)
    func languageAssistantView(_ view: LanguageAssistantView, didTapRecordingWith action: RecordingButton.RecordingStateAction)
}

class LanguageAssistantView: UIView {
    fileprivate var dataList = [Info]()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    weak var delegate: LanguageAssistantViewDelegate?
    private var textInputViewBottomConstraint: NSLayoutConstraint?
    private var bottomView: MessageInputView!
    private var bottomConstraint: NSLayoutConstraint!
    
    init(frame: CGRect, tipStrngs: [String]) {
        super.init(frame: frame)
        bottomView = MessageInputView(tipStrngs: tipStrngs)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.backgroundColor = UIColor(hex: 0xEDEEEF)
        addSubview(tableView)
        addSubview(bottomView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
        
        bottomConstraint = bottomView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        bottomConstraint.isActive = true
        bottomView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        bottomView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        bottomView.heightAnchor.constraint(equalToConstant: 130).isActive = true
    }
    
    private func commonInit() {
        bottomView.delegate = self
        tableView.register(UINib(nibName: "MessageSelfCell", bundle: .main), forCellReuseIdentifier: "MessageSelfCell")
        tableView.register(UINib(nibName: "MessageCell", bundle: .main), forCellReuseIdentifier: "MessageCell")
        tableView.dataSource = self
        tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(noti:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(noti:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    /// return all text
    func addOrUpdateInfo(info: Info, isRoundEnd: Bool = true) -> String {
        if info.roleType == .assistant {
            print("转换前：\(info.content)")
            info.content.removeQuotationMarks2()
            print("转换后：\(info.content)")
        }
        
        for (index, obj) in dataList.enumerated().reversed() {
            if obj.roundId == info.roundId, obj.roleType == info.roleType {
                if info.roleType == .assistant { /** llm */
                    dataList[index].content = obj.content + info.content
                }
                else { /** stt */
                    dataList[index].content = info.content
                }
                let indexPath = IndexPath(row: index, section: 0)
                tableView.reloadData()
                tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                return dataList[index].content
            }
        }
        
        info.addPrefix()
        dataList.append(info)
        tableView.reloadData()
        let indexPath = IndexPath(row: dataList.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        return info.content
    }
    
    func updateTranslateText(_ text: String, at indexPath: IndexPath) {
        dataList[indexPath.row].translatedText = text
        tableView.reloadData()
    }
    
    func setTip(_ tip: String) {
        bottomView.setTip(tip)
    }
    
    func setTokenString(_ token: String) {
        bottomView.setTokenString(token)
    }
    
    func showTextField(show: Bool) {
        bottomView.isHidden = !show
    }
    
    /// keyboard
    
    @objc func keyboardWillShow(noti: Notification) {
        let kFrame = noti.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        let duration = noti.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: duration) {
            self.bottomConstraint?.constant = kFrame.size.height * -1
            self.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(noti: Notification) {
        let duration = noti.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: duration) {
            self.bottomConstraint?.constant = 0
            self.layoutIfNeeded()
        }
    }
}

extension LanguageAssistantView: UITableViewDataSource, UITableViewDelegate {
    /// UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let info = dataList[indexPath.row]
        
        if info.isMe {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageSelfCell", for: indexPath) as! MessageSelfCell
            cell.update(withTime: info.timestap, message: info.content)
            cell.update(.success)
            cell.updateTimeShow(false)
            cell.indexPath = indexPath
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as! MessageCell
            cell.update(withTime: info.timestap,
                        message: info.content,
                        username: info.roleType.description,
                        translatedText: info.translatedText)
            cell.updateTimeShow(false)
            if indexPath.row == dataList.count - 1, !info.isMe {
                cell.updateRightButtonShow(true)
            }
            else {
                cell.updateRightButtonShow(false)
            }
            cell.indexPath = indexPath
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension LanguageAssistantView: MessageInputViewDelegate {
    func messageInputView(_ view: MessageInputView, didTapRecordingWith action: RecordingButton.RecordingStateAction) {
        delegate?.languageAssistantView(self, didTapRecordingWith: action)
    }
    
    func messageInputView(_ view: MessageInputView, didTapSendBtnWith text: String) {
        delegate?.languageAssistantViewShouldSendText(text: text)
    }
    
    func messageInputView(_ view: MessageInputView, didTapPolishBtnWith text: String) {
        delegate?.languageAssistantViewDidTapPolishBtn(text: text)
    }
}

extension LanguageAssistantView: MessageCellDelegate {
    
    func messageCelldidTapButton(_ actionType: MessageCellActionType, at indexPath: IndexPath) {
        if actionType == .tip {
            let info = dataList[indexPath.row]
            delegate?.languageAssistantViewDidTapTipBtnAt(indexPath: indexPath, content: info.content)
        }
        else {
            let info = dataList[indexPath.row]
            delegate?.languageAssistantViewDidTapTranslateBtn(text: info.content, at: indexPath)
        }
    }
}
