//
//  TransitionView.swift
//  CoreImageSwift
//
//  Created by 永超 沈 on 5/19/16.
//  Copyright © 2016 永超 沈. All rights reserved.
//

import UIKit
import CoreImage

class TransitionView: UIView {
    var context: CIContext!
        
    
    var beginImage: CIImage!
    var targetImage: CIImage!
    var base: NSTimeInterval!
    var transtion: CIFilter!
    let thumbnailWidth: CGFloat = 300.0
    let thumbnailHeight: CGFloat = 300.0
    var realtimeRender = false
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let fileURL = NSBundle.mainBundle().URLForResource("image", withExtension: "png")
        beginImage = CIImage(contentsOfURL: fileURL!)
        realtimeRender = true
        if realtimeRender {
            #if os(iOS)
                let myEAGLContext = EAGLContext(API: .OpenGLES2)
                context = CIContext(EAGLContext: myEAGLContext, options: [kCIContextWorkingColorSpace: NSNull()])
            #elseif os(OSX)
                context = CIContext(CGContext: NSGraphicsContext.currentContext().graphicsPort, options: nil)
                //[[NSGraphicsContext currentContext] CIContext]
            #endif
        } else {
            context = CIContext(options: nil)
        }
        
        calledFromViewDidLoadForTransition()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func calledFromViewDidLoadForTransition() {
        let timer = NSTimer(timeInterval: 1.0/30.0, target: self, selector: #selector(TransitionView.timerFired), userInfo: nil, repeats: true)
        
        let url = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("download", ofType: "jpeg")!)
        self.targetImage = CIImage(contentsOfURL: url)
        
        base = NSDate.timeIntervalSinceReferenceDate()
        
        NSRunLoop.currentRunLoop().addTimer(timer, forMode:NSRunLoopCommonModes)
        //NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSEventTrackingRunLoopMode)
    
    }

    
    func setupTransition() {
        let extent = CIVector(x: 0, y: 0, z: self.thumbnailWidth, w: self.thumbnailHeight)
        self.transtion = CIFilter(name: "CICopyMachineTransition")
        transtion.setDefaults()
        transtion.setValue(extent, forKey: kCIInputExtentKey)
    }
    
    func layerClass() -> AnyClass {
        return CAEAGLayer.self
    }
    
    override func drawRect(rectangle: CGRect) {
        let cg = CGRectMake(CGRectGetMinX(rectangle), CGRectGetMinY(rectangle), CGRectGetWidth(rectangle), CGRectGetHeight(rectangle))
        let t: Double = 0.4 * Double(NSDate.timeIntervalSinceReferenceDate() - base)
        if transtion == nil {
            self.setupTransition()
        }
        self.context.drawImage(imageForTransition(t+0.1), inRect: cg, fromRect: cg)
    }
    
    func imageForTransition(t: Double) -> CIImage {
        if t % 2.0 < 1.0 {
            transtion.setValue(beginImage, forKey: kCIInputImageKey)
            transtion.setValue(targetImage, forKey: kCIInputTargetImageKey)
        } else {
            transtion.setValue(targetImage, forKey: kCIInputImageKey)
            transtion.setValue(beginImage, forKey: kCIInputTargetImageKey)
        }
        transtion.setValue(Double(0.5 * (1.0-cos(t%1.0*M_PI))), forKey: kCIInputTimeKey)
        let crop = CIFilter(name: "CICrop", withInputParameters: [kCIInputImageKey: transtion.valueForKey(kCIOutputImageKey)!, "inputRectangle": CIVector(x:0, y:0, z: thumbnailWidth, w:thumbnailHeight)])
        return crop!.outputImage!
    }
    
    func timerFired(sender: AnyObject?) {
        self.drawRect(CGRectMake(0, 0, 300, 300))
    }


}
