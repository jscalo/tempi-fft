# TempiFFT

## Description

TempiFFT demonstrates how to input audio via AVFoundation for recording or processing and implements an FFT to display a real-time spectrum plot of incoming audio.

<b>What's an FFT?</b> Short for Fast Fourier Transform, it's a method for deconstructing an audio signal (or any time-based signal for that matter) into its constituent frequencies and intensities. The FFT function is a crucial component for nearly all audio DSP.

<b>Doesn't Apple's Accelerate framework already include an FFT?</b> Yes, and this project makes use of it. But Accelerate's FFT function (```vDSP_fft_zrip```) isn't trivial to call or set up correctly (esp. from Swift) and is just one necessary ingredient to a functional FFT.

<b>What's “logical banding”?</b> Actually I made that term up so maybe there's a better name for it, but logical banding adds an interface on top of the raw FFT data so that you can, for example, analyze the data at 5 bands per octave across a 6 octave range.

<b>How do you pronounce Tempi?</b> TEMP-ee.



## Technologies

- Swift
- iOS
- AVFoundation
- DSP (Fast Fourier Transform)
- CoreGraphics

## License

[![CC0](https://licensebuttons.net/p/zero/1.0/88x31.png)](http://creativecommons.org/publicdomain/zero/1.0/)

To the extent possible under law, John Scalo has waived all copyright and related or neighboring rights to this work.

## Contact

Contact me on Twitter - [@scalo](https://twitter.com/intent/user?screen_name=scalo)