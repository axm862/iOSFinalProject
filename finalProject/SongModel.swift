//
//  SongModel.swift
//  finalProject
//
//  Created by Nathan Walls on 4/24/18.
//  Copyright © 2018 Malik and Walls. All rights reserved.
//

import Foundation
import AVFoundation

class SongModel {
	var trackList: [Track]
	
	init () {
		trackList = []
	}
	
	init (firstTrack: Track) {
		trackList = []
		trackList.append(firstTrack)
	}
	
	public func getMasterTrackLength() -> Double{
		if trackList.count > 0 {
			return trackList[0].length
		} else {
			return -1
		}
	}
}

class Track {
	var path: String
	var length: Double
	
	init (path: String, length: Double) {
		self.path = path
		self.length = length
	}
}
