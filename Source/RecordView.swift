//
//  RecordView.swift
//  iRecordView
//
//  Created by Devlomi on 8/3/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

enum SwipeDirection {
    case none
    case up
    case left
}

public class RecordView: UIView, CAAnimationDelegate {

    private var isSwiped = false
    private var bucketImageView: BucketImageView!

    private var timer: Timer?
    private var duration: CGFloat = 0
    private var mTransform: CGAffineTransform!
    private var audioPlayer: AudioPlayer!
    
    private var timerStackView: UIStackView!
    private var slideToCancelStackVIew: UIStackView!
    private var direction = SwipeDirection.none;

    public weak var delegate: RecordViewDelegate?
    public var offset: CGFloat = 20
    public var isSoundEnabled = true
    public var buttonTransformScale: CGFloat = 2
    
    public var slideToCancelText: String! {
        didSet {
            slideLabel.text = slideToCancelText
        }
    }

    public var slideToCancelTextColor: UIColor! {
        didSet {
            slideLabel.textColor = slideToCancelTextColor
        }
    }

    public var slideToCancelArrowImage: UIImage! {
        didSet {
            arrow.image = slideToCancelArrowImage
        }
    }

    public var smallMicImage: UIImage! {
        didSet {
            bucketImageView.smallMicImage = smallMicImage
        }
    }

    public var durationTimerColor: UIColor! {
        didSet {
            timerLabel.textColor = durationTimerColor
        }
    }


    private let arrow: UIImageView = {
        let arrowView = UIImageView()
        arrowView.image = UIImage.fromPod("arrow")
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.tintColor = .black
        return arrowView
    }()
    
    private let lock: UIImageView = {
        let lockView = UIImageView()
        lockView.translatesAutoresizingMaskIntoConstraints = false
        lockView.tintColor = .blue
        lockView.image = UIImage.fromPod("lock")
        NSLayoutConstraint.activate([lockView.widthAnchor.constraint(equalToConstant: 35),
                                     lockView.heightAnchor.constraint(equalToConstant: 35)]);
        lockView.isHidden = true;
        return lockView
    }()

    private let slideLabel: UILabel = {
        let slide = UILabel()
        slide.text = "Slide To Cancel"
        slide.translatesAutoresizingMaskIntoConstraints = false
        slide.font = slide.font.withSize(12)
        return slide
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(UIColor.blue, for: .normal)
        //button.tintColor = UIColor.blue
        button.translatesAutoresizingMaskIntoConstraints = false
        //slide.text = "Slide To Cancel"
        //slide.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = button.titleLabel!.font.withSize(15)
        button.isHidden = true
        return button
    }()

    @objc func cancelButtonTouched() {
        isSwiped = false
        audioPlayer.didFinishPlaying = nil
        hideCancelStackViewAndTimeLabel()
        bucketImageView.animateBucketAndMic()
        resetTimer()
        delegate?.onCancel()
        cancelButton.isHidden = true;
    }

    private var timerLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = label.font.withSize(12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private func setup() {
        bucketImageView = BucketImageView(frame: frame)
        bucketImageView.animationDelegate = self
        bucketImageView.translatesAutoresizingMaskIntoConstraints = false
        bucketImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        bucketImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true


        timerStackView = UIStackView(arrangedSubviews: [bucketImageView, timerLabel])
        timerStackView.translatesAutoresizingMaskIntoConstraints = false
        timerStackView.isHidden = true
        timerStackView.spacing = 5

        slideToCancelStackVIew = UIStackView(arrangedSubviews: [arrow, slideLabel])
        slideToCancelStackVIew.translatesAutoresizingMaskIntoConstraints = false
        slideToCancelStackVIew.isHidden = true
        
        addSubview(timerStackView)
        addSubview(slideToCancelStackVIew)
        addSubview(lock)
        
        lock.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 55).isActive = true
        lock.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -100).isActive = true



        arrow.widthAnchor.constraint(equalToConstant: 15).isActive = true
        arrow.heightAnchor.constraint(equalToConstant: 15).isActive = true

        slideToCancelStackVIew.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        slideToCancelStackVIew.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        timerStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        timerStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true


        mTransform = CGAffineTransform(scaleX: buttonTransformScale, y: buttonTransformScale)

        audioPlayer = AudioPlayer()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }


    func onTouchDown(recordButton: RecordButton) {
        if cancelButton.isHidden {
            onStart(recordButton: recordButton)
        }
    }

    func onTouchUp(recordButton: RecordButton) {
        direction = .none
        if cancelButton.isHidden {
            guard !isSwiped else {
                return
            }
            onFinish(recordButton: recordButton)
        }
    }
    
    func onTouchCancelled(recordButton: RecordButton) {
        onTouchCancel(recordButton: recordButton)
    }


    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }


    @objc private func updateDuration() {
        duration += 1
        timerLabel.text = duration.fromatSecondsFromTimer()
    }

    //this will be called when user starts tapping the button
    private func onStart(recordButton: RecordButton) {
        isSwiped = false

        self.prepareToStartRecording(recordButton: recordButton)

        if isSoundEnabled {
            audioPlayer.playAudioFile(soundType: .start)
            audioPlayer.didFinishPlaying = { [weak self] _ in
                self?.delegate?.onStart()
            }
        } else {
            delegate?.onStart()
        }
    }
    
    private func prepareToStartRecording(recordButton: RecordButton) {
        resetTimer()

        //start timer
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateDuration), userInfo: nil, repeats: true)


        //reset all views to default
        slideToCancelStackVIew.transform = .identity
        recordButton.transform = .identity

        //animate button to scale up
        UIView.animate(withDuration: 0.2) {
            recordButton.transform = self.mTransform
        }


        slideToCancelStackVIew.isHidden = false
        timerStackView.isHidden = false
        timerLabel.isHidden = false
        bucketImageView.isHidden = false
        bucketImageView.resetAnimations()
        bucketImageView.animateAlpha()
    }

    fileprivate func animateRecordButtonToIdentity(_ recordButton: RecordButton) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            recordButton.transform = .identity
        })
    }
    
    //this will be called when user swipes to the left and cancel the record
    fileprivate func hideCancelStackViewAndTimeLabel() {
        slideToCancelStackVIew.isHidden = true
        timerLabel.isHidden = true
    }
    
    private func onSwipe(recordButton: RecordButton) {
        isSwiped = true
        audioPlayer.didFinishPlaying = nil
        
        animateRecordButtonToIdentity(recordButton)

        hideCancelStackViewAndTimeLabel()

        if !isLessThanOneSecond() {
            bucketImageView.animateBucketAndMic()

        } else {
            bucketImageView.isHidden = true
            delegate?.onAnimationEnd?()
        }

        resetTimer()

        delegate?.onCancel()
    }
    
    private func onTouchCancel(recordButton: RecordButton) {
        isSwiped = false
        
        audioPlayer.didFinishPlaying = nil
        
        animateRecordButtonToIdentity(recordButton)
        
        hideCancelStackViewAndTimeLabel()
        
        bucketImageView.isHidden = true
        delegate?.onAnimationEnd?()
        
        resetTimer()
        
        delegate?.onCancel()
    }

    private func resetTimer() {
        timer?.invalidate()
        timerLabel.text = "00:00"
        duration = 0
    }

    //this will be called when user lift his finger
    private func onFinish(recordButton: RecordButton) {
        isSwiped = false
        audioPlayer.didFinishPlaying = nil
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            recordButton.transform = .identity
        })


        slideToCancelStackVIew.isHidden = true
        timerStackView.isHidden = true

        timerLabel.isHidden = true
        cancelButton.isHidden = true


        if isLessThanOneSecond() {
            if isSoundEnabled {
                audioPlayer.playAudioFile(soundType: .error)
            }
        } else {
            if isSoundEnabled {
                audioPlayer.playAudioFile(soundType: .end)
            }
        }

        delegate?.onFinished(duration: duration)

        resetTimer()

    }

    //this will be called when user starts to move his finger
    func touchMoved(recordButton: RecordButton, sender: UIPanGestureRecognizer) {

        guard !isSwiped else {
            return
        }
        
        guard cancelButton.isHidden else {
            return
        }

        let button = sender.view!
        let translation = sender.translation(in: button)

        switch sender.state {
        case .changed:

            //prevent swiping the button outside the bounds
            if direction == .up || translation.y < 0 {
                if direction != .left {
                    //start move the views
                    direction = .up
                    if lock.isHidden {
                        lock.isHidden = false
                    }
                    let transform = mTransform.translatedBy(x: 0, y: translation.y * 2 )
                    button.transform = transform
                    
                    if cancelButton.isHidden && self.convert(lock.frame, to: button.superview).maxY - 18 > button.frame.minY {
                        cancelButton.isHidden = false
                        if cancelButton.superview == nil {
                            superview!.addSubview(cancelButton)
                            NSLayoutConstraint.activate([cancelButton.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: timerStackView.bounds.width / 2)
                                                         ,cancelButton.centerYAnchor.constraint(equalTo: self.centerYAnchor)
                            ]);
                            
                            superview?.bringSubviewToFront(cancelButton)
                            cancelButton.addTarget(self, action: #selector(cancelButtonTouched), for: .touchUpInside)
                        }
                        
                        button.transform = .identity
                        slideToCancelStackVIew.isHidden = true
                        lock.isHidden = true
                        delegate?.onLock()
                    }
                }
            }
            
            if direction == .left || translation.x < 0 {
                if direction != .up {
                    //start move the views
                    direction = .left
                    let transform = mTransform.translatedBy(x: translation.x, y: 0)
                    button.transform = transform
                    slideToCancelStackVIew.transform = transform.scaledBy(x: 0.5, y: 0.5)


                    if slideToCancelStackVIew.frame.intersects(timerStackView.frame.offsetBy(dx: offset, dy: 0)) {
                        onSwipe(recordButton: recordButton)
                    }
                }
            }
        default:
            break
        }

    }
    
    public func finishRecording(recordButton: RecordButton) {
        onFinish(recordButton: recordButton)
    }

}


extension RecordView: AnimationFinishedDelegate {
    func animationFinished() {
        slideToCancelStackVIew.isHidden = true
        timerStackView.isHidden = false
        timerLabel.isHidden = true
        delegate?.onAnimationEnd?()
    }
}

private extension RecordView {
    func isLessThanOneSecond() -> Bool {
        return duration < 1
    }
}


