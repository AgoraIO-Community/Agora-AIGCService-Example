//
//  MainView2.swift
//  GPT-Demo
//
//  Created by ZYP on 2023/10/18.
//

import UIKit

protocol MainViewDelegate: NSObjectProtocol {
    func mainViewDidShouldSendText(text: String)
}

class MainView: UIView, UITableViewDataSource {
    var dataList = [Info]()
    private var textField = UITextField()
    private let sendBtn = UIButton()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    weak var delegate: MainViewDelegate?
    
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
        
        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sendBtn)
        sendBtn.translatesAutoresizingMaskIntoConstraints = false
        
        textField.borderStyle = .roundedRect
        textField.placeholder = "请输入内容"
        
        textField.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
        textField.rightAnchor.constraint(equalTo: sendBtn.leftAnchor).isActive = true
        textField.topAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
        
        sendBtn.setTitle("发送", for: .normal)
        sendBtn.setTitleColor(.blue, for: .normal)
        sendBtn.backgroundColor = .green
        
        sendBtn.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
        sendBtn.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendBtn.centerYAnchor.constraint(equalTo: textField.centerYAnchor).isActive = true
        sendBtn.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        
        textField.isHidden = true
        sendBtn.isHidden = true
    }
    
    private func commonInit() {
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
    
    @objc func buttonTap(_ sender: UIButton) {
        delegate?.mainViewDidShouldSendText(text: textField.text!)
        textField.text = ""
    }
    
    func showTextField(show: Bool) {
        textField.isHidden = !show
        sendBtn.isHidden = !show
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
}

extension MainView {
    class Info {
        let uuid: String
        var content: String
        
        init(uuid: String, content: String) {
            self.uuid = uuid
            self.content = content
        }
        
        var prefix: String {
            if uuid.contains("llm") {
                return "[llm]:"
            }
            return ""
        }
    }
}
