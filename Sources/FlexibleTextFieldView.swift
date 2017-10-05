//
//  FlexibleTextFieldView.swift
//  Pods
//
//  Created by Thompson Sanjoto on 2016-09-22.
//
//

import Foundation

open class FlexibleTextFieldView: UIView
{
    open var textView = UITextView()
    open var resizeBtn = UIButton()
    open var closeBtn = UIButton()
    
    convenience init(origin:CGPoint) {
        let defaultFrame = CGRect(origin: origin, size: CGSize(width: 140, height: 40))
        self.init(frame: defaultFrame)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Initialization code
        
        self.backgroundColor = UIColor.clear
        
        //add UITextView
        textView.isEditable = true
        textView.backgroundColor = UIColor.clear
        textView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width-20, height: frame.height)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.contentInset = UIEdgeInsetsMake(-4,0,0,0)
        textView.isScrollEnabled = false
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.white.cgColor
        textView.textAlignment = .center
        
        if let font = UIFont(name: "Helvetica", size: 25)
        {
            let stringAtt: [NSAttributedStringKey: Any] = [
                NSAttributedStringKey.font:             font,
                NSAttributedStringKey.strokeColor:      UIColor.black,
                NSAttributedStringKey.foregroundColor:  UIColor.white,
                NSAttributedStringKey.strokeWidth:      -2.0
            ]
            textView.attributedText = NSAttributedString(string: "Your Text", attributes: stringAtt)
        }
        
        
        self.addSubview(textView)
        var leadConstraint = NSLayoutConstraint(item: textView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        var yConstraint = NSLayoutConstraint(item: textView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        var hConstraint = NSLayoutConstraint(item: textView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        var wConstraint = NSLayoutConstraint(item: textView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: -20)
        
        var constraints = [leadConstraint,yConstraint,hConstraint,wConstraint]
        self.addConstraints(constraints)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action:#selector(FlexibleTextFieldView.moveView(_:)))
        textView.addGestureRecognizer(panRecognizer)
        
        //add resize button
        resizeBtn.frame = CGRect(x: frame.maxX-20, y: frame.maxY, width: 20, height: 20)
        resizeBtn.setImage(UIImage(named: "resize"), for: .normal)
        resizeBtn.tintColor = UIColor.white
        resizeBtn.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(resizeBtn)
        
        leadConstraint = NSLayoutConstraint(item: resizeBtn, attribute: .leading, relatedBy: .equal, toItem: textView, attribute: .trailing, multiplier: 1, constant: 0)
        var trailConstraint = NSLayoutConstraint(item: resizeBtn, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        hConstraint = NSLayoutConstraint(item: resizeBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
        wConstraint = NSLayoutConstraint(item: resizeBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
        yConstraint = NSLayoutConstraint(item: resizeBtn, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        constraints = [leadConstraint,trailConstraint,yConstraint,hConstraint,wConstraint]
        self.addConstraints(constraints)
        
        
        let resizePanRecognizer = UIPanGestureRecognizer(target: self, action:#selector(FlexibleTextFieldView.resizeView(_:)))
        resizeBtn.addGestureRecognizer(resizePanRecognizer)
        
        //add close button
        closeBtn.frame = CGRect(x: frame.maxX-20, y: frame.minY, width: 20, height: 20)
        closeBtn.setImage(UIImage(named: "cancel"), for: .normal)
        closeBtn.tintColor = UIColor.white
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(closeBtn)
        
        leadConstraint = NSLayoutConstraint(item: closeBtn, attribute: .leading, relatedBy: .equal, toItem: textView, attribute: .trailing, multiplier: 1, constant: 0)
        trailConstraint = NSLayoutConstraint(item: closeBtn, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        hConstraint = NSLayoutConstraint(item: closeBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
        wConstraint = NSLayoutConstraint(item: closeBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
        yConstraint = NSLayoutConstraint(item: closeBtn, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        constraints = [leadConstraint,trailConstraint,yConstraint,hConstraint,wConstraint]
        self.addConstraints(constraints)
        
        closeBtn.addTarget(self, action: #selector(FlexibleTextFieldView.removeSelfFromSuperview), for: .touchUpInside)
        
        
        self.layoutSubviews()
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func moveView(_ gesture:UIPanGestureRecognizer) {
        let newCoord = gesture.location(in: self.superview!)
        let x = newCoord.x
        let y = newCoord.y
        let center = CGPoint(x: (gesture.view?.frame.origin.x)! + x, y: (gesture.view?.frame.origin.y)! + y)
        self.center = center
    }
    
    @objc func resizeView(_ gesture:UIPanGestureRecognizer) {
        let newCoord = gesture.location(in: self.superview)
        let newX = newCoord.x - self.frame.origin.x
        let newY = newCoord.y - self.frame.origin.y
        
        if newX > 140 && newY > 40
        {
            let newFrame = CGRect(origin: self.frame.origin, size: CGSize(width: newX, height: newY))
            self.frame = newFrame
        }
    }
    
    @objc func removeSelfFromSuperview(_ sender:AnyObject){
        self.removeFromSuperview()
    }
    
    
}
