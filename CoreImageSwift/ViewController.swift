//
//  ViewController.swift
//  CoreImageSwift
//
//  Created by 永超 沈 on 5/19/16.
//  Copyright © 2016 永超 沈. All rights reserved.
//

import UIKit
import AssetsLibrary

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var beginImage: CIImage!
    var targetImage: CIImage!
    var base: NSTimeInterval!
    var filter: CIFilter!
    
    var realtimeRender = false
    var valueKey: String!
    var valueMin: Double!
    var valueMax: Double!
    @IBOutlet weak var slider: UISlider!
    var context: CIContext {
        get {
            if realtimeRender {
                #if os(iOS)
                    let myEAGLContext = EAGLContext(API: .OpenGLES2)
                    return CIContext(EAGLContext: myEAGLContext, options: [kCIContextWorkingColorSpace: NSNull()])
                #elseif os(OSX)
                    return CIContext(CGContext: NSGraphicsContext.currentContext().graphicsPort, options: nil)
                    //[[NSGraphicsContext currentContext] CIContext]
                #endif
            } else {
                return CIContext(options: nil)
            }

        }
        
    }
    var orientation: UIImageOrientation = .Up
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        let fileURL = NSBundle.mainBundle().URLForResource("image", withExtension: "png")
//        beginImage = CIImage(contentsOfURL: fileURL!)
//        filter = self.chainFilters(self.getGloomFilter(beginImage), secondFilter: self.getDumpDistortionFilter(beginImage))
//        realtimeRender = true
//        
//        let cgImage = context.createCGImage(filter.outputImage!, fromRect: filter.outputImage!.extent)
//        
//        let newImage = UIImage(CGImage: cgImage)
//        
//
//        imageView.image = newImage;
//        imageView.contentMode = .ScaleAspectFit
//
        let transView = TransitionView()
        transView.frame = CGRectMake(0, 0, 300, 300)
        transView.center = view.center
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.imageViewTaped))
        imageView.addGestureRecognizer(tap)
        imageView.userInteractionEnabled = true
        
        
        view.addSubview(transView)
        
    }
    
        
    
//    func createContextFromOpenGL -> CIContext {
//        //It’s important that the pixel format for the context includes the NSOpenGLPFANoRecovery constant as an attribute. Otherwise Core Image may not be able to create another context that shares textures with this one. You must also make sure that you pass a pixel format whose data type is CGLPixelFormatObj
//        //let attrs: [UInt32] = [NSOpenGLPFAAccelerated, NSOpenGLPFANoRecovery, NSOpenGLPFAColorSize, 32, 0]
//        const NSOpenGLPixelFormatAttribute attr[] = {
//            NSOpenGLPFAAccelerated,
//            NSOpenGLPFANoRecovery,
//            NSOpenGLPFAColorSize, 32,
//            0
//        };
//        NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void
//            *)&attr];
//        CIContext *myCIContext = [CIContext contextWithCGLContext: CGLGetCurrentContext()
//            pixelFormat: [pf CGLPixelFormatObj]
//            options: nil];
//        
//    }
    /// MARK: transition filter
    
    func chainFilters(firstFilter: CIFilter!, secondFilter: CIFilter!) -> CIFilter {
        let inputImage = firstFilter.outputImage
        secondFilter.setValue(inputImage, forKey: kCIInputImageKey)
        return secondFilter
}
    
    func getDumpDistortionFilter(inputImage: CIImage!) -> CIFilter {
        let dumpDistortion = CIFilter(name: "CIBumpDistortion")
        dumpDistortion?.setDefaults()
        dumpDistortion?.setValue(inputImage, forKey: kCIInputImageKey)
        dumpDistortion?.setValue(CIVector(x: 200, y: 150), forKey: kCIInputCenterKey)
        dumpDistortion?.setValue(100.0, forKey: kCIInputRadiusKey)
        dumpDistortion?.setValue(3.0, forKey: kCIInputScaleKey)
        valueKey = kCIInputScaleKey
        valueMin = 0.0
        valueMax = 3.0 * 2
        return dumpDistortion!
    }
    
    func getGloomFilter(inputImage: CIImage!) -> CIFilter? {
        if let gloom = CIFilter(name: "CIGloom") {
            gloom.setDefaults()
            gloom.setValue(inputImage, forKey: kCIInputImageKey)
            gloom.setValue(25.0, forKey: kCIInputRadiusKey)
            gloom.setValue(0.75, forKey: kCIInputIntensityKey)
            valueMax = 1.0
            valueMin = 0.0
            valueKey = kCIInputIntensityKey
            return gloom
        }
        return nil
        
    }
    
    func getSepiaToneFilter(inputImage: CIImage!) -> CIFilter {
        let localFilter = CIFilter(name: "CISepiaTone")!
        localFilter.setDefaults()
        localFilter.setValue(inputImage, forKey: kCIInputImageKey)
        localFilter.setValue(0.5, forKey: kCIInputIntensityKey)
        valueKey = kCIInputIntensityKey
        valueMax = 1.0
        valueMin = 0.0
        return localFilter
    }
    
    func getMonoChromeFilter(inputImage: CIImage!, color: UIColor) -> CIFilter {
        let localFilter = CIFilter(name: "CIColorMonochrome")!
        localFilter.setDefaults()
        localFilter.setValue(inputImage, forKey: kCIInputImageKey)
        localFilter.setValue(CIColor(color: color), forKey: kCIInputColorKey)
        localFilter.setValue(0.8, forKey: kCIInputIntensityKey)
        valueKey = kCIInputIntensityKey
        valueMin = 0.0
        valueMax = 1.0
        slider.value = 0.8
        return localFilter
    }
    
    func getHueAdjustFilter(inputImage: CIImage!) -> CIFilter {
        let localFilter = CIFilter(name: "CIHueAdjust")!
        localFilter.setDefaults()
        localFilter.setValue(inputImage, forKey: kCIInputImageKey)
        localFilter.setValue(2.094, forKey: kCIInputAngleKey)
        valueKey = kCIInputAngleKey
        valueMin = 0.0
        valueMax = 2.094 * 2
        return localFilter
    }

   
    @IBAction func sliderValueChanged(sender: UISlider) {
        let sliderValue = valueMin+(valueMax - valueMin)*Double(sender.value)
        
        filter.setValue(sliderValue, forKey: valueKey)
        let outputImage = filter.outputImage
        let cgImage = context.createCGImage(outputImage!, fromRect: outputImage!.extent)
        imageView.image = UIImage(CGImage: cgImage, scale: 0.4, orientation: orientation)
    }
    
    func imageViewTaped(sender: UITapGestureRecognizer) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        self.presentViewController(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBAction func saveImage(sender: UIButton) {
        let imageToSave = filter.outputImage!
        let softwareContext = CIContext(options: [kCIContextUseSoftwareRenderer: true])
        let cgimage = softwareContext.createCGImage(imageToSave, fromRect: imageToSave.extent)
        let library = ALAssetsLibrary()
        library.writeImageToSavedPhotosAlbum(cgimage, metadata: imageToSave.properties, completionBlock: nil)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        self.dismissViewControllerAnimated(true, completion: nil)
//        let imageUrl = info[UIImagePickerControllerMediaURL] as! NSURL
//        let imageData = NSData(contentsOfURL: imageUrl)
//        var scale = 1.0
//        while Double(imageData!.length) * scale > Double(1024*1024) {
//            scale *= 0.9
//        }
        let gotImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        orientation = gotImage.imageOrientation
        beginImage = CIImage(image: gotImage)
        //beginImage = CIImage(image: gotImage, options: [])
        filter.setValue(beginImage, forKey: kCIInputImageKey)
        self.sliderValueChanged(slider)
    }


}

