//
//  TempiUtilities.swift
//  TempiHarness
//
//  Created by John Scalo on 1/8/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import Foundation
import UIKit

func tempi_dispatch_main(closure:()->()) {
    dispatch_async(dispatch_get_main_queue(), closure)
}

func tempi_dispatch_delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

func tempi_round_device_scale(d: CGFloat) -> CGFloat
{
    let scale: CGFloat = UIScreen.mainScreen().scale
    return round(d * scale) / scale
}
