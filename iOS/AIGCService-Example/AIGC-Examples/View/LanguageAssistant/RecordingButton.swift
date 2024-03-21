//
//  RecordingView.swift
//  AIGC-Examples
//
//  Created by ZYP on 2024/3/1.
//

protocol RecordingButtonDelegate: AnyObject {
    func recordingDidTap(_ button: RecordingButton, action: RecordingButton.RecordingStateAction)
}

class RecordingButton: UIButton {
    weak var delegate: RecordingButtonDelegate?

    private var isRecording = false {
        didSet {
            self.backgroundColor = self.isRecording ? .green : .white
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setTitle("按住 说话", for: .normal)
        setTitleColor(.black, for: .normal)
        
        layer.cornerRadius = 5
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 1
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        self.addGestureRecognizer(longPressGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleLongPressGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            isRecording = true
            delegate?.recordingDidTap(self, action: .start)
        case .ended:
            isRecording = false
            if frame.contains(gestureRecognizer.location(in: self)) {
                delegate?.recordingDidTap(self, action: .end)
            } else {
                delegate?.recordingDidTap(self, action: .cancel)
            }
        default:
            break
        }
    }
}

extension RecordingButton {
    enum RecordingStateAction {
        case start
        case end
        case cancel
    }
}
