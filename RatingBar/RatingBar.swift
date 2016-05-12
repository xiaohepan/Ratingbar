
//
//  Created by panxiaohe on 16/05/12.
//  Copyright (c) 2015年 panxiaohe rights reserved.
//

import UIKit

@IBDesignable
class RatingBar: UIView {
    //总分
    @IBInspectable var ratingMax:Int = 5{
        didSet{
            setScore(userSetRating)
        }
    }
    //IB设置ratingMode
    @IBInspectable var ratingModeAdapter:Int {
        get{
            return self.ratingMode.rawValue
        }
        set{
            ratingMode = RatingMode(rawValue: newValue) ?? .None
        }
    }
    
    //用户设置的分数被记录在 userSetRating里，如果ratingmode发生改变重新设置innerRating
    @IBInspectable var rating: CGFloat{
        set{
            userSetRating = newValue
            setScore(newValue)
        }
        get{
            return innerRating
        }
    }
   
    //打分模式
    var ratingMode:RatingMode = .None{
        didSet{
           
            guard oldValue != ratingMode else{
                return
            }
            setScore(userSetRating)
            switch (oldValue,ratingMode) {
            case (.None,_):
                addRecognizer()
            case (_,.None):
                removeRecognizer()
            default:
                break
            }
        }
    }
    //总分图片
    @IBInspectable var imageTotal:UIImage?{
        didSet{
            setNeedsDisplay()
        }
    }
    //打分图片
    @IBInspectable var imageRating:UIImage?{
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var paddingTop:CGFloat = 0
    @IBInspectable var paddingBottom:CGFloat = 0
    @IBInspectable var paddingLeft:CGFloat = 0
    @IBInspectable var paddingRight:CGFloat = 0
    
    
    weak var delegate: RatingBarDelegate?
    private var tapGesture:UITapGestureRecognizer?
    private var panGesture:UIPanGestureRecognizer?
    //每个星星大小
    private var itemSize:CGSize = CGSizeZero
    
    //用来显示的分数
    private var innerRating:CGFloat = 0{
        didSet{
            if oldValue != innerRating{
                setNeedsDisplay()
                delegate?.ratingDidChange(self, rating: innerRating)
            }
        }
    }
    //用户记录的分数
    private var userSetRating:CGFloat = 0

    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        guard let context = UIGraphicsGetCurrentContext() else{
            return
        }
        guard let imageAll = imageTotal else{
          return
        }
        guard let imageScore = imageRating else{
            return
        }
        guard itemSize.width != 0 && itemSize.height != 0 else{
            return
        }
        UIGraphicsPushContext(context)
        let rect = CGRectMake(paddingLeft, paddingTop, itemSize.width, itemSize.height)
        for i in 0 ..< ratingMax{
            let rect1 = rect.offsetBy(dx: CGFloat(i) * itemSize.width, dy: 0)
            if CGFloat(i) < floor(innerRating){
                imageScore.drawInRect(rect1)
            }else if CGFloat(i) < ceil(innerRating){
                let percent = innerRating - floor(innerRating)
                let xOffset =  round(percent * itemSize.width)
                let (rect2,rect3) = rect1.divide(xOffset, fromEdge: .MinXEdge)
        
                var imageScale = imageScore.scale
                var imageWidth = imageScore.size.width
                var imageHeight = imageScore.size.height
                var imageCropOffset = floor(imageWidth * percent * imageScale)
                var cropRect = CGRectMake(0, 0, imageCropOffset, imageHeight * imageScale)
                if let imageLeft = CGImageCreateWithImageInRect(imageScore.CGImage, cropRect){
                    UIImage(CGImage: imageLeft).drawInRect(rect2)
                }
                imageScale = imageAll.scale
                imageWidth = imageAll.size.width
                imageHeight = imageAll.size.height
                imageCropOffset = floor(imageWidth * percent * imageScale)
                cropRect = CGRectMake(imageCropOffset, 0, imageWidth * imageScale - imageCropOffset, imageHeight * imageScale)
                if let imageRight = CGImageCreateWithImageInRect(imageAll.CGImage, cropRect){
                 UIImage(CGImage: imageRight).drawInRect(rect3)
                }
            }else{
                imageAll.drawInRect(rect1)
            }
        }
        UIGraphicsPopContext()
    }

    func addRecognizer(){
        if tapGesture == nil{
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapRateView(_:)))
            tapGesture!.numberOfTapsRequired = 1
            self.addGestureRecognizer(tapGesture!)
        }
        if panGesture == nil{
            panGesture = UIPanGestureRecognizer(target: self, action: #selector(panRateView(_:)))
            self.addGestureRecognizer(panGesture!)
        }
    }
    
    func removeRecognizer(){
        if tapGesture != nil{
            self.removeGestureRecognizer(tapGesture!)
            tapGesture = nil
        }
        if panGesture != nil{
            self.removeGestureRecognizer(panGesture!)
            panGesture = nil
        }
    }
    
    
    override func intrinsicContentSize() -> CGSize {
        calculateItemSize()
        return CGSizeMake(itemSize.width * CGFloat(ratingMax) + paddingLeft + paddingRight, itemSize.height + paddingTop + paddingBottom)
    }
    
    private func calculateItemSize(){
        let width1 = self.imageRating?.size.width ?? 0
        let width2 = self.imageTotal?.size.width ?? 0
        let width = max(width1, width2)
        let height1 = self.imageRating?.size.height ?? 0
        let height2 = self.imageTotal?.size.height ?? 0
        let height = max(height1, height2)
        itemSize = CGSizeMake(width, height)
    }
    
    
    
    //编辑分数，通过手势的x坐标来设置数值
    @objc private func tapRateView(sender: UITapGestureRecognizer){
        let tapPoint = sender.locationInView(self)
        self.rating = calculateRating(tapPoint.x)
    }
    //编辑分数，通过手势的x坐标来设置数值
    @objc private func panRateView(sender: UIPanGestureRecognizer){
        let tapPoint = sender.locationInView(self)
        self.rating = calculateRating(tapPoint.x)
    }
    
    private func calculateRating(x:CGFloat) -> CGFloat{
        var offset = x - paddingLeft
        let length = CGFloat(ratingMax) * itemSize.width
        offset = max(offset,0)
        offset = min(offset, length)
        return offset / itemSize.width
    }
    
    private func setScore(value:CGFloat){
        let score  = min(max(value,0),CGFloat(ratingMax))
        switch ratingMode {
        case .FullStar:
            innerRating = ceil(score)
        case .halfStar:
            let i = ceil(score)
            innerRating = i - score > 0.5 ? i - 0.5 : i
        default:
            innerRating = score
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        calculateItemSize()
    }
    
}

enum RatingMode:Int {
    case None = 0,FullStar = 1,halfStar = 2,Normal = 3
}

@objc protocol RatingBarDelegate{
    func ratingDidChange(ratingBar: RatingBar,rating: CGFloat)
}
