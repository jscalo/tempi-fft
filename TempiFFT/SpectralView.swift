//
//  SpectralView.swift
//  TempiHarness
//
//  Created by John Scalo on 1/20/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import UIKit

class SpectralView: UIView {

    var fft: TempiFFT!

    override func drawRect(rect: CGRect) {
        
        if fft == nil {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()
        
        self.drawSpectrum(context!)
        
        // We're drawing static labels every time through our drawRect() which is a waste.
        // If this were more than a demo we'd take care to only draw them once.
        self.drawLabels(context!)
    }
    
    private func drawSpectrum(context: CGContextRef) {
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        let plotYStart: CGFloat = 48.0
        
        CGContextSaveGState(context)
        CGContextScaleCTM(context, 1, -1)
        CGContextTranslateCTM(context, 0, -viewHeight)
        
        let colors: CFArrayRef = [UIColor.greenColor().CGColor, UIColor.yellowColor().CGColor, UIColor.redColor().CGColor]
        let gradient = CGGradientCreateWithColors(
            nil, // generic color space
            colors,
            [0.0, 0.3, 0.6])
        
        var x: CGFloat = 0.0
        
        let count = fft.numberOfBands
        
        // Draw the spectrum.
        let maxDB: Float = 64.0
        let minDB: Float = -32.0
        let headroom = maxDB - minDB
        let colWidth = tempi_round_device_scale(viewWidth / CGFloat(count))
        
        for i in 0..<count {
            let magnitude = fft.magnitudeAtBand(i)
            
            // Incoming magnitudes are linear, making it impossible to see very low or very high values. Decibels to the rescue!
            var magnitudeDB = TempiFFT.toDB(magnitude)
            
            // Normalize the incoming magnitude so that -Inf = 0
            magnitudeDB = max(0, magnitudeDB + abs(minDB))
            
            let dbRatio = min(1.0, magnitudeDB / headroom)
            let magnitudeNorm = CGFloat(dbRatio) * viewHeight
            
            let colRect: CGRect = CGRect(x: x, y: plotYStart, width: colWidth, height: magnitudeNorm)
            
            let startPoint = CGPointMake(viewWidth / 2, 0)
            let endPoint = CGPointMake(viewWidth / 2, viewHeight)
            
            CGContextSaveGState(context)
            CGContextClipToRect(context, colRect)
            CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, CGGradientDrawingOptions(rawValue: 0))
            CGContextRestoreGState(context)
            
            x += colWidth
        }
        
        CGContextRestoreGState(context)
    }
    
    private func drawLabels(context: CGContextRef) {
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, 0, viewHeight);
        
        let pointSize: CGFloat = 15.0
        let font = UIFont.systemFontOfSize(pointSize, weight: UIFontWeightRegular)
        
        let freqLabelStr = "Frequency (kHz)"
        var attrStr = NSMutableAttributedString(string: freqLabelStr)
        attrStr.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, freqLabelStr.characters.count))
        attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellowColor(), range: NSMakeRange(0, freqLabelStr.characters.count))
        
        var x: CGFloat = viewWidth / 2.0 - attrStr.size().width / 2.0
        attrStr.drawAtPoint(CGPointMake(x, -22))
        
        let labelStrings: [String] = ["5", "10", "15", "20"]
        let labelValues: [CGFloat] = [5000, 10000, 15000, 20000]
        let samplesPerPixel: CGFloat = CGFloat(fft.sampleRate) / 2.0 / viewWidth
        for i in 0..<labelStrings.count {
            let str = labelStrings[i]
            let freq = labelValues[i]
            
            attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, str.characters.count))
            attrStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.yellowColor(), range: NSMakeRange(0, str.characters.count))
            
            x = freq / samplesPerPixel - pointSize / 2.0
            attrStr.drawAtPoint(CGPointMake(x, -40))
        }
        
        CGContextRestoreGState(context)
    }
}
