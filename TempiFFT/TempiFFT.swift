//
//  TempiFFT.swift
//  TempiHarness
//
//  Created by John Scalo on 1/12/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

/*  
    Note that TempiFFT expects a mono signal (i.e. numChannels == 1) which is ideal for performance.
*/

import Foundation
import Accelerate

enum TempiFFTWindowType {
    case none
    case hanning
    case hamming
}

class TempiFFT {
    
    /// The length of the sample buffer we'll be analyzing.
    private(set) var size: Int

    /// The sample rate provided at init time.
    private(set) var sampleRate: Float

    /// After performing the FFT, contains ```size/2``` magnitudes, one for each frequency band.
    private(set) var magnitudes: [Float]!
    
    /// Returns the width of each frequency band in the spectrum (in Hz).
    var bandwidth: Float {
        get {
            return sampleRate / Float(size)
        }
    }
    
    var bandCount: Int {
        get {
            return halfSize
        }
    }
    
    /// Supplying a window type (hanning or hamming) smooths the edges of the incoming waveform and reduces output errors from the FFT function (aka "spectral leakage" - ewww).
    var windowType = TempiFFTWindowType.none
    
    private var halfSize:Int
    private var log2Size:Int
    private var window:[Float]!
    private var fftSetup:FFTSetup
    private var complexBuffer:COMPLEX_SPLIT = DSPSplitComplex(realp: nil, imagp: nil)
    private var hasPerformedFFT: Bool = false
    
    /// Instantiate the FFT.
    /// - Parameter withSize: The length of the sample buffer we'll be analyzing. Must be a power of 2. The resulting ```magnitudes``` are of length ```inSize/2```.
    /// - Parameter sampleRate: Sampling rate of the provided audio data.
    init(withSize inSize:Int, sampleRate inSampleRate: Float) {
        
        let sizeFloat: Float = Float(inSize)
        
        self.sampleRate = inSampleRate
        
        // Check if the size is a power of two        
        let lg2 = logbf(sizeFloat)
        assert(remainderf(sizeFloat, powf(2.0, lg2)) == 0, "size must be a power of 2")

        size = inSize
        halfSize = inSize / 2
        
        // create fft setup
        log2Size = Int(log2f(sizeFloat))
        fftSetup = vDSP_create_fftsetup(UInt(log2Size), FFTRadix(FFT_RADIX2))
        
        // Init the complexBuffer
        let mallocSize: Int = Int(halfSize) * sizeof(Float)
        complexBuffer.realp = UnsafeMutablePointer<Float>(malloc(mallocSize))
        complexBuffer.imagp = UnsafeMutablePointer<Float>(malloc(mallocSize))
    }
    
    deinit {
        // destroy the fft setup object
        vDSP_destroy_fftsetup(fftSetup)
        
        free(complexBuffer.realp)
        free(complexBuffer.imagp)
    }

    /// Perform a forward FFT on the provided single-channel audio data. When complete, the instance can be queried for information about the analysis or the magnitudes can be accessed directly.
    /// - Parameter inMonoBuffer: Audio data in mono format
    func fftForward(inMonoBuffer:[Float]) {
        var analysisBuffer = inMonoBuffer
        
        // If we have a window, apply it now. Since 99.9% of the time the window array will be exactly the same, an optimization would be to create it once and cache it, possibly caching it by size.
        // TODO: Optimize
        if windowType != .none {
            window = [Float](count: size, repeatedValue: 0.0)
            
            switch windowType {
            case .hamming:
                vDSP_hann_window(&window!, UInt(size), Int32(vDSP_HANN_NORM))
            case .hanning:
                vDSP_hamm_window(&window!, UInt(size), 0)
            default:
                break
            }

            // Apply the window
            vDSP_vmul(inMonoBuffer, 1, self.window, 1, &analysisBuffer, 1, UInt(inMonoBuffer.count))
        }
        

        // vDSP_ctoz converts an interleaved vector into a complex split vector. i.e. moves the even indexed samples into frame.buffer.realp and the odd indexed samples into frame.buffer.imagp.
        vDSP_ctoz(UnsafePointer<DSPComplex>(analysisBuffer), 2, &complexBuffer, 1, UInt(self.halfSize))
        
        // Perform a forward FFT
        vDSP_fft_zrip(self.fftSetup, &complexBuffer, 1, UInt(self.log2Size), Int32(FFT_FORWARD))
        
        // Store and square (for better visualization & conversion to db) the magnitudes
        self.magnitudes = [Float](count: self.halfSize, repeatedValue: 0.0)
        vDSP_zvmags(&complexBuffer, 1, &self.magnitudes!, 1, UInt(self.halfSize))
        
        self.hasPerformedFFT = true
    }
    
    /// Get the magnitude for the specified frequency band.
    /// - Parameter inBand: The frequency band you want a magnitude for. Note that the Nyquist cutoff requires this be < size / 2.
    func magnitudeAtBand(inBand: Int) -> Float {
        assert(hasPerformedFFT, "*** Perform the FFT first.")
        return magnitudes[inBand]
    }
    
    /// Get the magnitude of the requested frequency in the spectrum.
    /// - Parameter inFrequency: The requested frequency. Must be less than the Nyquist frequency (```sampleRate/2```).
    /// - Returns: A magnitude.
    func magnitudeAtFrequency(inFrequency: Float) -> Float {
        assert(hasPerformedFFT, "*** Perform the FFT first.")
        let index = Int(floorf(inFrequency / self.bandwidth ))
        return self.magnitudes[index]
    }
    
    /// Get the middle frequency of the Nth band.
    /// - Parameter inBand: An index where 0 <= inBand < size / 2.
    /// - Returns: The middle frequency of the provided band.
    func frequencyForBand(inBand: Int) -> Float {
        assert(hasPerformedFFT, "*** Perform the FFT first.")
        let halfBandwidth = self.bandwidth / 2.0
        let edgeFreq = self.bandwidth * Float(inBand)
        return edgeFreq + halfBandwidth
    }
    
    /// A convenience function that converts a linear magnitude (like those stored in ```magnitudes```) to db (which is log 10).
    class func toDB(inMagnitude: Float) -> Float {
        // ceil to 128db in order to avoid log10'ing 0
        let magnitude = max(inMagnitude, 0.000000000001)
        return 10 * log10f(magnitude)
    }
}
