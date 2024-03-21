//
//  LLMModulesTestingView.swift
//  GPT-Demo
//
//  Created by ZYP on 2023/10/31.
//

import UIKit

protocol LLMModulesTestingViewDelegate: NSObjectProtocol {
    func llmModulesTestingViewDidUpdateText(text: String)
}

class LLMModulesTestingView: UIView, UITableViewDataSource, UITextFieldDelegate {
    typealias Info = MainView.Info
    var dataList = [Info]()
    private let textField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    weak var delegate: LLMModulesTestingViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        tableView.backgroundColor = .red
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        tableView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        
        textField.returnKeyType = .done
        textField.placeholder = "输入问题"
        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.widthAnchor.constraint(equalToConstant: 200).isActive = true
        textField.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        textField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
    }
    
    private func commonInit() {
        textField.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    func addOrUpdateInfo(info: Info) {
        if dataList.isEmpty {
            dataList.append(info)
            tableView.reloadData()
            return
        }
        
        for (index, obj) in dataList.enumerated().reversed() {
            if obj.uuid == info.uuid {
                if info.uuid.contains("llm") {
                    dataList[index].content = obj.content + info.content
                }
                else { /** stt */
                    dataList[index].content = info.content
                }
                let indexPath = IndexPath(row: index, section: 0)
                tableView.reloadData()
                tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                return
            }
        }
        
        dataList.append(info)
        tableView.reloadData()
        let indexPath = IndexPath(row: dataList.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    }
    
    /// UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let info = dataList[indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.textLabel?.text = info.prefix + info.content
        cell.textLabel?.textColor = .blue
        cell.textLabel?.numberOfLines = 0
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataList.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.llmModulesTestingViewDidUpdateText(text: textField.text ?? "")
        textField.resignFirstResponder()
        return true
    }
}
