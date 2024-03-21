//
//  InputTipSelectedView.swift
//  AIGC-Examples
//
//  Created by ZYP on 2024/2/28.
//

import UIKit

protocol TipSelectedViewDelegate: NSObjectProtocol {
    func tipSelectedView(_ view: TipSelectedView, didSelectContent content: String)
}

class TipSelectedView: UIView {
    weak var delegate: TipSelectedViewDelegate?
    private var collectionView: UICollectionView!
    private var data: [String] = []
    
    init(frame: CGRect, dataArray: [String]) {
        super.init(frame: frame)
        data = dataArray
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TipCell.self, forCellWithReuseIdentifier: "TipCell")
        addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        collectionView.reloadData()
    }
}

extension TipSelectedView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TipCell", for: indexPath) as! TipCell
        cell.textLabel.text = data[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = data[indexPath.item]
        let width = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]).width + 20
        return CGSize(width: width, height: 30)
    }
    
    /// 监听collectionView点击事件
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let content = data[indexPath.row]
        delegate?.tipSelectedView(self, didSelectContent: content)
    }
}

class TipCell: UICollectionViewCell {
    
    var textLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        textLabel = UILabel(frame: .zero)
        textLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textLabel.backgroundColor = .purple
        textLabel.textColor = .white
        textLabel.textAlignment = .center
        textLabel.font = UIFont.systemFont(ofSize: 16)
        textLabel.layer.cornerRadius = bounds.height / 2
        textLabel.layer.masksToBounds = true
        textLabel.layer.borderWidth = 1.0
        textLabel.layer.borderColor = UIColor.white.cgColor
        textLabel.numberOfLines = 0
        contentView.addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        textLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        textLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        textLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
