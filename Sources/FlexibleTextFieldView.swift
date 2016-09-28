//
//  FlexibleTextFieldView.swift
//  Pods
//
//  Created by Thompson Sanjoto on 2016-09-22.
//
//

import Foundation

public class FlexibleTextFieldView: UIView {
    
    public var textView = UITextView()
    public var resizeBtn = UIButton()
    
    convenience init(origin:CGPoint) {
        let defaultFrame = CGRect(origin: origin, size: CGSize(width: 140, height: 40))
        self.init(frame: defaultFrame)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Initialization code
        
        
        self.backgroundColor = UIColor.clearColor()
        
        //add UITextView
        textView.editable = true
        textView.backgroundColor = UIColor.clearColor()
        textView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width-20, height: frame.height)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.contentInset = UIEdgeInsetsMake(-4,0,0,0)
        textView.scrollEnabled = false
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.whiteColor().CGColor
        textView.textAlignment = .Center
        
        let font = UIFont(name: "Helvetica", size: 25)!
        let stringAtt = [
            NSFontAttributeName: font,
            NSStrokeColorAttributeName : UIColor.blackColor(),
            NSForegroundColorAttributeName : UIColor.whiteColor(),
            NSStrokeWidthAttributeName : -2.0
        ]
        textView.attributedText = NSAttributedString(string: "Your Text", attributes: stringAtt)
        
        
        self.addSubview(textView)
        var leadConstraint = NSLayoutConstraint(item: textView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0)
        var yConstraint = NSLayoutConstraint(item: textView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        var hConstraint = NSLayoutConstraint(item: textView, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 1, constant: 0)
        var wConstraint = NSLayoutConstraint(item: textView, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: -20)
        
        var constraints = [leadConstraint,yConstraint,hConstraint,wConstraint]
        self.addConstraints(constraints)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action:#selector(FlexibleTextFieldView.moveView(_:)))
        textView.addGestureRecognizer(panRecognizer)
        
        //add resize button
        resizeBtn.frame = CGRect(x: frame.maxX-20, y: frame.maxY, width: 20, height: 20)
        resizeBtn.setImage(UIImage(named: "resize"), forState: .Normal)
        resizeBtn.tintColor = UIColor.whiteColor()
        resizeBtn.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(resizeBtn)
        
        leadConstraint = NSLayoutConstraint(item: resizeBtn, attribute: .Leading, relatedBy: .Equal, toItem: textView, attribute: .Trailing, multiplier: 1, constant: 0)
        let trailConstraint = NSLayoutConstraint(item: resizeBtn, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0)
        hConstraint = NSLayoutConstraint(item: resizeBtn, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 20)
        wConstraint = NSLayoutConstraint(item: resizeBtn, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 20)
        yConstraint = NSLayoutConstraint(item: resizeBtn, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
        constraints = [leadConstraint,trailConstraint,yConstraint,hConstraint,wConstraint]
        self.addConstraints(constraints)
        
        
        let resizePanRecognizer = UIPanGestureRecognizer(target: self, action:#selector(FlexibleTextFieldView.resizeView(_:)))
        resizeBtn.addGestureRecognizer(resizePanRecognizer)
        
        self.layoutSubviews()
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func moveView(gesture:UIPanGestureRecognizer) {
        let newCoord = gesture.locationInView(self.superview!)
        let x = newCoord.x
        let y = newCoord.y
        let center = CGPointMake((gesture.view?.frame.origin.x)! + x, (gesture.view?.frame.origin.y)! + y)
        self.center = center
    }
    
    func resizeView(gesture:UIPanGestureRecognizer) {
        let newCoord = gesture.locationInView(self.superview!)
        let newX = newCoord.x - self.frame.origin.x
        let newY = newCoord.y - self.frame.origin.y
        
        if newX > 140 && newY > 40
        {
            let newFrame = CGRect(origin: self.frame.origin, size: CGSize(width: newX, height: newY))
            self.frame = newFrame
        }
        
    }
    
    
}