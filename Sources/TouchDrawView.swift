//
//  TouchDrawView.swift
//  TouchDraw
//
//  Created by Christian Paul Dehli
//

import Foundation

/// The protocol which the container of TouchDrawView can conform to
@objc public protocol TouchDrawViewDelegate {
    /// triggered when undo is enabled (only if it was previously disabled)
    @objc optional func undoEnabled() -> Void
    
    /// triggered when undo is disabled (only if it previously enabled)
    @objc optional func undoDisabled() -> Void
    
    /// triggered when redo is enabled (only if it was previously disabled)
    @objc optional func redoEnabled() -> Void
    
    /// triggered when redo is disabled (only if it previously enabled)
    @objc optional func redoDisabled() -> Void
    
    /// triggered when clear is enabled (only if it was previously disabled)
    @objc optional func clearEnabled() -> Void
    
    /// triggered when clear is disabled (only if it previously enabled)
    @objc optional func clearDisabled() -> Void
}

/// A subclass of UIView which allows you to draw on the view using your fingers
public class TouchDrawView: UIView {
    
    /// Used to register undo and redo actions
    private var touchDrawUndoManager: UndoManager!

    /// must be set in whichever class is using the TouchDrawView
    public var delegate: TouchDrawViewDelegate?
    
    /// used to keep track of all the strokes
    public var stack: [Stroke]!
    private var pointsArray: [String]!
    
    private var lastPoint = CGPoint.zero
    
    /// brushProperties: current brush settings
    public var brushProperties = StrokeSettings()
    
    private var touchesMoved = false
    
    public var mainImageView = UIImageView()
    public var tempImageView = UIImageView()
    
    private var undoEnabled = false
    private var redoEnabled = false
    private var clearEnabled = false
    
    public var selectedTool:Tools = .brush
    
    public enum Tools:Int
    {
        case brush
        case square
        case arrow
        case text
    }
    
    
    
    /// initializes a TouchDrawView instance
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initTouchDrawView(frame)
    }
    
    /// initializes a TouchDrawView instance
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initTouchDrawView(CGRect.zero)
    }
    
    /// imports the stack so that previously exported stack can be used
    public func importStack(_ stack: [Stroke]) {
        
        // Reset the stack and TouchDrawView
        self.stack = []
        self.internalClear()
        self.touchDrawUndoManager.removeAllActions()
        
        // Add the strokes to UndoManager
        for stroke in stack {
            self.pushDrawing(stroke)
        }
        
        // Undo is enabled but should be disabled
        if self.undoEnabled && self.stack.count == 0 {
            self.delegate?.undoDisabled?()
            self.undoEnabled = false
        }
        // Undo is disabled but should be enabled
        else if !self.undoEnabled && self.stack.count > 0 {
            self.delegate?.undoEnabled?()
            self.undoEnabled = true
        }
        
        // Redo is enabled but should be disabled
        if self.redoEnabled {
            self.delegate?.redoDisabled?()
            self.redoEnabled = false
        }
        
        // Clear is disabled but should be enabled
        if !self.clearEnabled && self.stack.count > 0 {
            self.delegate?.clearEnabled?()
            self.clearEnabled = true
        }
        // Clear is enabled but should be disabled
        else if self.clearEnabled && self.stack.count == 0 {
            self.delegate?.clearDisabled?()
            self.clearEnabled = false
        }
    }
    
    /// Used to export the current stack (each individual stroke)
    public func exportStack() -> [Stroke] {
        return self.stack
    }

    /// adds the subviews and initializes stack
    private func initTouchDrawView(_ frame: CGRect) {
        self.addSubview(self.mainImageView)
        self.addSubview(self.tempImageView)
        self.stack = []
        
        self.touchDrawUndoManager = undoManager
        if self.touchDrawUndoManager == nil {
            self.touchDrawUndoManager = UndoManager()
        }
        
        // Initially sets the frames of the UIImageViews
        self.draw(frame)
    }
    
    /// sets the frames of the subviews
    override open func draw(_ rect: CGRect) {
        self.mainImageView.frame = rect
        self.tempImageView.frame = rect
    }
    
    /// merges tempImageView into mainImageView
    fileprivate func mergeViews() {
        UIGraphicsBeginImageContext(self.mainImageView.frame.size)
        self.mainImageView.image?.draw(in: self.mainImageView.frame, blendMode: CGBlendMode.normal, alpha: 1.0)
        self.tempImageView.image?.draw(in: self.tempImageView.frame, blendMode: CGBlendMode.normal, alpha: self.brushProperties.color.alpha)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        self.mainImageView.image = image
        UIGraphicsEndImageContext()
        
        self.tempImageView.image = nil
    }
    
    /// removes the last stroke from stack
    internal func popDrawing() {
        let stroke = stack.last
        self.stack.popLast()
        self.redrawLinePathsInStack()
        self.touchDrawUndoManager!.registerUndo(withTarget: self, selector: #selector(TouchDrawView.pushDrawing(_:)), object: stroke)
    }
    
    /// adds a new stroke to the stack
    internal func pushDrawing(_ object: AnyObject) {
        let stroke = object as? Stroke
        self.stack.append(stroke!)
        self.drawLine(stroke!)
        self.touchDrawUndoManager!.registerUndo(withTarget: self, selector: #selector(TouchDrawView.popDrawing), object: nil)
    }
    
    /// draws all the lines in the stack
    private func redrawLinePathsInStack() {
        self.internalClear()
        
        for stroke in self.stack {
            self.drawLine(stroke)
        }
    }
    
    /// draws a stroke
    private func drawLine(_ stroke: Stroke) -> Void {
        let properties = stroke.settings
        let array = stroke.points
        
        if array?.count == 1 {
            // Draw the one point
            let pointStr = array?[0] 
            let point = CGPointFromString(pointStr!)
            self.drawLineFrom(point, toPoint: point, properties: properties!)
        }
        
        for i in 0 ..< (array?.count)! - 1 {
            let pointStr0 = array?[i] 
            let pointStr1 = array?[i+1] 
            
            let point0 = CGPointFromString(pointStr0!)
            let point1 = CGPointFromString(pointStr1!)
            self.drawLineFrom(point0, toPoint: point1, properties: properties!)
        }
        self.mergeViews()
    }
    
    /// draws a line from one point to another with certain properties
    private func drawLineFrom(_ fromPoint: CGPoint, toPoint: CGPoint, properties: StrokeSettings) -> Void {
        
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        context!.move(to: CGPoint(x: fromPoint.x, y: fromPoint.y))
        context!.addLine(to: CGPoint(x: toPoint.x, y: toPoint.y))
        
        context!.setLineCap(CGLineCap.round)
        context!.setLineWidth(properties.width)
        context!.setStrokeColor(red: properties.color.red, green: properties.color.green, blue: properties.color.blue, alpha: 1.0)
        context!.setBlendMode(CGBlendMode.normal)
        
        context!.strokePath()
        
        self.tempImageView.image?.draw(in: self.tempImageView.frame)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        self.tempImageView.image = image
        self.tempImageView.alpha = properties.color.alpha
        UIGraphicsEndImageContext()
    }
    
    /// draws a square
    private func drawSquare(_ stroke: Stroke) -> Void {
        let properties = stroke.settings
        let array = stroke.points
        
        if array?.count == 1 {
            // Draw the one point
            let pointStr = array?[0]
            let point = CGPointFromString(pointStr!)
            self.drawSquareFrom(point, toPoint: point, properties: properties!)
        }else
        {
            let fPoint = array?[0]
            let lPoint = array?[(array?.count)!-1]
            let firstPoint = CGPointFromString(fPoint!)
            let lastPoint = CGPointFromString(lPoint!)

            self.drawSquareFrom(firstPoint, toPoint: lastPoint, properties: properties!)

        }

        self.mergeViews()
    }
    
    /// draws a square from touch began to touch ended
    private func drawSquareFrom(_ fromPoint: CGPoint, toPoint: CGPoint, properties: StrokeSettings) -> Void {
        self.tempImageView.image = nil
        
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        let origin = CGPoint(x: min(fromPoint.x, toPoint.x), y: min(fromPoint.y, toPoint.y))
        let size = CGSize(width: abs(fromPoint.x-toPoint.x), height:  abs(fromPoint.y-toPoint.y))
        
        let rect = CGRect(origin: origin, size: size)
        context!.setStrokeColor(red: properties.color.red, green: properties.color.green, blue: properties.color.blue, alpha: 1.0)
        context!.stroke(rect,width: properties.width)
        context!.setBlendMode(CGBlendMode.normal)
        context!.strokePath()
        
        self.tempImageView.image?.draw(in: self.tempImageView.frame)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        self.tempImageView.image = image
        self.tempImageView.alpha = properties.color.alpha
        
        UIGraphicsEndImageContext()
    }
    
    /// draws an arrow
    private func drawArrow(_ stroke: Stroke) -> Void {
        let properties = stroke.settings
        let array = stroke.points
        
        if array?.count == 1 {
            // Draw the one point
            let pointStr = array?[0]
            let point = CGPointFromString(pointStr!)
            self.drawArrowFrom(point, toPoint: point, properties: properties!)
        }else
        {
            let fPoint = array?[0]
            let lPoint = array?[(array?.count)!-1]
            let firstPoint = CGPointFromString(fPoint!)
            let lastPoint = CGPointFromString(lPoint!)
            self.drawArrowFrom(firstPoint, toPoint: lastPoint, properties: properties!)
        }
        
        self.mergeViews()
    }
    
    /// draws a square from touch began to touch ended
    private func drawArrowFrom(_ fromPoint: CGPoint, toPoint: CGPoint, properties: StrokeSettings) -> Void {
        self.tempImageView.image = nil
        
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()
        let arrowPath = UIBezierPath.bezierPathWithArrowFromPoint(startPoint: fromPoint, endPoint: toPoint, tailWidth: properties.width, headWidth: properties.width+15, headLength: 20)
        context!.setStrokeColor(red: properties.color.red, green: properties.color.green, blue: properties.color.blue, alpha: 1.0)
        context!.setFillColor(red: properties.color.red, green: properties.color.green, blue: properties.color.blue, alpha: 1.0)
        
        arrowPath.fill()
        arrowPath.stroke()
        
        self.tempImageView.image?.draw(in: self.tempImageView.frame)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        self.tempImageView.image = image
        self.tempImageView.alpha = properties.color.alpha
        
        UIGraphicsEndImageContext()
    }
    
    /// draws a text
    private func drawText(_ stroke: Stroke) -> Void {
        let properties = stroke.settings
        let array = stroke.points
        
        if (array?.count)! >= 1 {
            // Draw the one point
            let pointStr = array?[0]
            let point = CGPointFromString(pointStr!)
            self.drawTextFrom(point, toPoint: point, properties: properties!)
        }
        
        self.mergeViews()
    }
    
    /// draws a text from first touch
    private func drawTextFrom(_ fromPoint: CGPoint, toPoint: CGPoint, properties: StrokeSettings) -> Void {
        
        let textField = FlexibleTextFieldView(origin:fromPoint)
        self.addSubview(textField)
        textField.textView.textColor = UIColor(red: properties.color.red, green: properties.color.green, blue: properties.color.blue, alpha: 1.0)
        
        
    }
    
    
    
    
    
    /// exports the current drawing
    public func exportDrawing() -> UIImage {
        UIGraphicsBeginImageContext(self.mainImageView.bounds.size)
        self.mainImageView.image?.draw(in: self.mainImageView.frame)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    /// clears the UIImageViews
    private func internalClear() -> Void {
        self.mainImageView.image = nil
        self.tempImageView.image = nil
    }
    
    /// clears the drawing
    public func clearDrawing() -> Void {
        self.internalClear()
        self.touchDrawUndoManager!.registerUndo(withTarget: self, selector: #selector(TouchDrawView.pushAll(_:)), object: stack)
        self.stack = []
        
        self.checkClearState()
        
        if !self.touchDrawUndoManager!.canRedo {
            if self.redoEnabled {
                self.delegate?.redoDisabled?()
                self.redoEnabled = false
            }
        }
    }
    
    internal func pushAll(_ object: AnyObject) {
        let array = object as? [Stroke]
        
        for stroke in array! {
            self.drawLine(stroke)
            self.stack.append(stroke)
        }
        self.touchDrawUndoManager!.registerUndo(withTarget: self, selector: #selector(TouchDrawView.clearDrawing), object: nil)
    }
    
    /// sets the brush's color
    public func setColor(_ color: UIColor) -> Void {
        self.brushProperties.color = CIColor(color: color)
    }
    
    /// sets the brush's width
    public func setWidth(_ width: CGFloat) -> Void {
        self.brushProperties.width = width
    }
    
    private func checkClearState() {
        if self.stack.count == 0 && self.clearEnabled {
            self.delegate?.clearDisabled?()
            self.clearEnabled = false
        }
        else if self.stack.count > 0 && !self.clearEnabled {
            self.delegate?.clearEnabled?()
            self.clearEnabled = true
        }
    }
    
    /// if possible, it will undo the last stroke
    public func undo() -> Void {
        if self.touchDrawUndoManager!.canUndo {
            self.touchDrawUndoManager!.undo()
            
            if !self.redoEnabled {
                self.delegate?.redoEnabled?()
                self.redoEnabled = true
            }
            
            if !self.touchDrawUndoManager!.canUndo {
                if self.undoEnabled {
                    self.delegate?.undoDisabled?()
                    self.undoEnabled = false
                }
            }
            
            self.checkClearState()
        }
    }
    
    /// if possible, it will redo the last undone stroke
    public func redo() -> Void {
        if self.touchDrawUndoManager!.canRedo {
            self.touchDrawUndoManager!.redo()
            
            if !self.undoEnabled {
                self.delegate?.undoEnabled?()
                self.undoEnabled = true
            }
            
            if !self.touchDrawUndoManager!.canRedo {
                if self.redoEnabled {
                    self.delegate?.redoDisabled?()
                    self.redoEnabled = false
                }
            }
            
            self.checkClearState()
        }
    }
    
    // MARK: - Actions
    
    /// triggered when touches begin
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesMoved = false
        if let touch = touches.first {
            self.lastPoint = touch.location(in: self)
            self.pointsArray = []
            self.pointsArray.append(NSStringFromCGPoint(self.lastPoint))
        }
    }
    
    /// triggered when touches move
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesMoved = true
        
        if let touch = touches.first {
            switch selectedTool
            {
            case .brush:
                let currentPoint = touch.location(in: self)
                self.drawLineFrom(self.lastPoint, toPoint: currentPoint, properties: self.brushProperties)
                
                self.lastPoint = currentPoint
                self.pointsArray.append(NSStringFromCGPoint(self.lastPoint))
            case .square:
                let currentPoint = touch.location(in: self)
                self.drawSquareFrom(self.lastPoint, toPoint: currentPoint, properties: self.brushProperties)
                self.pointsArray.append(NSStringFromCGPoint(self.lastPoint))
                
            case .arrow:
                let currentPoint = touch.location(in: self)
                self.drawArrowFrom(self.lastPoint, toPoint: currentPoint, properties: self.brushProperties)
                self.pointsArray.append(NSStringFromCGPoint(self.lastPoint))
                
            case .text:
                //don't do anything
                break
                
            }
        }
    }
    
    /// triggered whenever touches end, resulting in a newly created Stroke
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.touchesMoved {
            // draw from a single point
            switch selectedTool
            {
            case .brush:
                self.drawLineFrom(self.lastPoint, toPoint: self.lastPoint, properties: self.brushProperties)
            case .square:
                self.drawSquareFrom(self.lastPoint, toPoint: self.lastPoint, properties: self.brushProperties)
            case .arrow:
                self.drawArrowFrom(self.lastPoint, toPoint: self.lastPoint, properties: self.brushProperties)
            case .text:
                self.drawTextFrom(self.lastPoint, toPoint: self.lastPoint, properties: self.brushProperties)
            }
        }
        
        guard selectedTool != .text else
        {
            //Don't save to stroke stack if its a text type.
            //Stack should be added on return key
            return
        }
        
        strokeEnded()
    }
    
    func strokeEnded()
    {
        self.mergeViews()
        
        let stroke = Stroke()
        stroke.settings = StrokeSettings(settings: self.brushProperties)
        stroke.points = self.pointsArray
        
        self.stack.append(stroke)
        
        self.touchDrawUndoManager!.registerUndo(withTarget: self, selector: #selector(TouchDrawView.popDrawing), object: nil)
        
        if !self.undoEnabled {
            self.delegate?.undoEnabled?()
            self.undoEnabled = true
        }
        if self.redoEnabled {
            self.delegate?.redoDisabled?()
            self.redoEnabled = false
        }
        if !self.clearEnabled {
            self.delegate?.clearEnabled?()
            self.clearEnabled = true
        }
    }
}

//https://gist.github.com/mwermuth/07825df27ea28f5fc89a
extension UIBezierPath {
    
    class func getAxisAlignedArrowPoints( _ points: inout Array<CGPoint>, forLength: CGFloat, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat ) {
        
        let tailLength = forLength - headLength
        points.append(CGPoint(x: 0, y: tailWidth/2))
        points.append(CGPoint(x: tailLength, y: tailWidth/2))
        points.append(CGPoint(x: tailLength, y: headWidth/2))
        points.append(CGPoint(x: forLength, y: 0))
        points.append(CGPoint(x: tailLength, y: -headWidth/2))
        points.append(CGPoint(x: tailLength, y: -tailWidth/2))
        points.append(CGPoint(x: 0, y: -tailWidth/2))
        
    }
    
    
    class func transformForStartPoint(_ startPoint: CGPoint, endPoint: CGPoint, length: CGFloat) -> CGAffineTransform{
        let cosine: CGFloat = (endPoint.x - startPoint.x)/length
        let sine: CGFloat = (endPoint.y - startPoint.y)/length
        
        return CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: startPoint.x, ty: startPoint.y)
    }
    
    
    class func bezierPathWithArrowFromPoint(startPoint:CGPoint, endPoint: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> UIBezierPath {
        
        let xdiff: Float = Float(endPoint.x) - Float(startPoint.x)
        let ydiff: Float = Float(endPoint.y) - Float(startPoint.y)
        let length = hypotf(xdiff, ydiff)
        
        var points = [CGPoint]()
        self.getAxisAlignedArrowPoints(&points, forLength: CGFloat(length), tailWidth: tailWidth, headWidth: headWidth, headLength: headLength)
        
        let transform: CGAffineTransform = self.transformForStartPoint(startPoint, endPoint: endPoint, length:  CGFloat(length))
        
        let cgPath: CGMutablePath = CGMutablePath()
        cgPath.addLines(between: points, transform: transform)
        
        
        cgPath.closeSubpath()
        
        let uiPath: UIBezierPath = UIBezierPath(cgPath: cgPath)
        return uiPath
    }
}
