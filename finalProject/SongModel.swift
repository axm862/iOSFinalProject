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
			return trackList[0].length!
		} else {
			return -1
		}
	}
	
	public func getTrackAtIndex(indexOf: Int) -> Track {
		return trackList[indexOf]
	}
	
	public func getNumberOfTracks() -> Int {
		return trackList.count
	}
	
	public func addTrack(new: Track) {
		self.trackList.append(new)
	}
}

class Track {
	var path: URL
	var length: Double?
	
	init (path: URL, length: Double) {
		self.path = path
		self.length = length
	}
	
	init (path: URL) {
		self.path = path
	}
}
