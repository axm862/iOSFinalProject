//
//  MyExtension.swift
//  finalProject
//
//  Created by Nathan Walls on 5/2/18.
//  Copyright © 2018 Malik and Walls. All rights reserved.
//

import Foundation
import AVFoundation

extension AVMutableCompositionTrack {
	func append(url: URL) {
		let newAsset = AVURLAsset(url: url)
		let range = CMTimeRangeMake(kCMTimeZero, newAsset.duration)
		let end = timeRange.end
		print(end)
		if let track = newAsset.tracks(withMediaType: AVMediaType.audio).first {
			try! insertTimeRange(range, of: track, at: end)
		}
		
	}
}
