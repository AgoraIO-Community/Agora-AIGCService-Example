//
//  RoleListVC.swift
//  Demo
//
//  Created by ZYP on 2023/8/25.
//

import UIKit

protocol RoleListVCDelegate: NSObjectProtocol {
    func roleListVCDidSelectedItem(at index: Int)
}

class RoleListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var items = [Item]()
    let tableview = UITableView(frame: .zero, style: .grouped)
    weak var delegate: RoleListVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }

    func setupUI() {
        view.backgroundColor = .white
        view.addSubview(tableview)
        tableview.frame = view.bounds
    }
    
    func commonInit() {
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableview.delegate = self
        tableview.dataSource = self
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        let item = items[indexPath.row]
        cell.textLabel?.text = item.text
        cell.detailTextLabel?.text = item.detail
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.roleListVCDidSelectedItem(at: indexPath.row)
        dismiss(animated: true)
    }
}

extension RoleListVC {
    struct Item {
        let text: String
        let detail: String
    }
}

