//
//  TempiDebug.swift
//  TempiHarness
//
//  Created by John Scalo on 1/18/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import Foundation
import UIKit

// Provide either sampleArray (a [Float]) or samplePointer (a C pointer to an array of Float)
func TempiDebugWaveform(count: Int, sampleArray: [Float]? = nil, samplePointer: UnsafePointer<Float>? = nil) -> UIImage {
    
    let height: CGFloat = 800.0
    let width: CGFloat = CGFloat(count)
    let bgndRect: CGRect = CGRect(x: 0, y: 0, width: width, height: height)

    UIGraphicsBeginImageContextWithOptions(bgndRect.size, false, 2.0)
    let context: CGContext = UIGraphicsGetCurrentContext()!
    
    context.scaleBy(x: 1, y: -1)
    context.translateBy(x: 0, y: -height)
    context.saveGState()

    // Fill background with black
    context.setFillColor(CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])!)
    context.fill(bgndRect)

    // Draw waveform columns
    let colWidth: CGFloat = 1.0
    var x: CGFloat = 0.0
    
    for i in 0..<count {
        var sample: Float = 0.0
        if let unwrappedSampleArray = sampleArray {
            sample = unwrappedSampleArray[i]
        } else if let unwrappedSamplePointer = samplePointer {
            let newPtr = unwrappedSamplePointer + i
            sample = newPtr.pointee
        } else {
            assertionFailure("Me want data nom nom")
        }
        
        let qSample: Float = sample * Float(height) / 2.0
        let colRect: CGRect = CGRect(x: x, y: 400, width: colWidth, height: CGFloat(qSample))
        
        // Use orange for column color and fill it
        context.setFillColor(CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 0.5, 0.0, 1.0])!)
        context.fill(colRect)
        
        x += colWidth
    }
    
    context.restoreGState()
    let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return image
}

func TempiDebugSampleDump(count: Int, sampleArray: [Float]? = nil, samplePointer: UnsafePointer<Float>? = nil) {
    for i in 0..<count {
        var sample: Float = 0.0
        if let unwrappedSampleArray = sampleArray {
            sample = unwrappedSampleArray[i]
        } else if let unwrappedSamplePointer = samplePointer {
            let newPtr = unwrappedSamplePointer + i
            sample = newPtr.pointee
        } else {
            assertionFailure("Me want data nom nom")
        }

        print("TempiDebugSampleDump: [\(i)]: [\(sample)]")
    }
}
