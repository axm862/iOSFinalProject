//
//  ViewController.swift
//  finalProject
//
//  Created by Aditya Malik on 4/9/18.
//  Copyright © 2018 Malik and Walls. All rights reserved.
//
import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource {
	
	var recordingSession:AVAudioSession!
	var audioRecorder:AVAudioRecorder!
	var audioPlayer:AVAudioPlayer!
	//Counter for how many recordings we have
	//var numberOfRecords:Int = 0
	
	@IBAction func tapShare(_ sender: UIButton) {
		playmerge()
	}
	@IBOutlet weak var timeLabel: UILabel!
	
	var model: SongModel = SongModel()
	var nextTrackId = 0
	var currentlyRecordingTrack: Track?
	
	@IBOutlet weak var recordingProgress: UIProgressView!
	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var recordingView: UIView!
	@IBOutlet weak var trackListView: UITableView!
	
	@IBOutlet weak var playPauseButton: UIButton!
	
	var playerList: [AVAudioPlayer] = []
	
	@IBAction func tappedPlayPause(_ sender: UIButton) {
		playAll()
	}
	
	func playAll() {
		playerList = []
		do {
			for t in model.trackList {
				let myaudioPlayer = try AVAudioPlayer(contentsOf: t.path)
				playerList.append(myaudioPlayer)
				myaudioPlayer.play()
			}
		} catch {
			displayAlert(title: "Oops!", message: "Playback Failed")
		}
	}
	
	// Save files to 'unique' name every time
	let sessionId = arc4random()
	
	// Timer for updating progress bar
	var timer = Timer()
	var timeStartedRecording = Date()
	
	@objc func countSeconds() {
		if model.trackList.count == 0 {
			timeLabel.text = "\(-1 * timeStartedRecording.timeIntervalSinceNow)"
			let myindex = timeLabel.text!.index(timeLabel.text!.startIndex, offsetBy: 4)
			timeLabel.text = "\(timeLabel.text![..<myindex])"
		}
	}
	
	@IBAction func record(_ sender: Any) {
		//Check if we have an active recorder (if nil then record)
		if audioRecorder == nil {
			//Defines filename for new recording in m4a format
			let filename = getDirectory().appendingPathComponent("musicapp\(sessionId)-\(nextTrackId).m4a")
			
			// Use a separate ID tracker from the model to ensure unique filenames
			nextTrackId += 1
			
			// If we weren't already recording, make a new track to record to
			if currentlyRecordingTrack == nil {
				currentlyRecordingTrack = Track(path: filename)
			} else {
				print("started recording a track when currentlyRecordingTrack was not nil")
			}

			//Recording settings
			let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
			
			//Start audio recording
			do
			{
				audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
				audioRecorder.delegate = self
				
				// If there are no tracks, place no limit (or an arbitrary limit) on length
				if model.getNumberOfTracks() == 0 {
					audioRecorder.record()

					// Call function to update the time label
					timeStartedRecording = Date()
					timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.countSeconds), userInfo: nil, repeats: true)
					
					//recordButton.setTitle("Stop Recording", for: .normal)
				} else {
					// If there's already a master track, don't allow recording for longer
					audioRecorder.record(forDuration: TimeInterval(model.getMasterTrackLength()))
					// Play previous tracks in background while recording the new track
					playAll()
					recordButton.isEnabled = false
					
					// Need to update the GUI when this track is done recording
					print("Calling recordingTimedOut in \(TimeInterval(model.getMasterTrackLength()) * 0.0001)")
					DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(model.getMasterTrackLength()) * 0.0001, execute: {
						self.recordingTimedOut()
					})
				}
				
				// Set up timer to continually update progress bar
				timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.setProgressBar), userInfo: nil, repeats: true)
				timeStartedRecording = Date()
			}
			catch
			{
				displayAlert(title: "Oops!", message: "Recording failed")
			}
		}
		else {
			//Stopping audio recording if no active recorder
			finishRecording()
		}
	}
	
	
	// Function to calculate what value the progress bar should have
	// This is called every .1 seconds after tapping record
	@objc func setProgressBar() {
		if audioRecorder == nil {
			recordingProgress.progress = 0.0
		} else {
			if model.getNumberOfTracks() == 0 {
				recordingProgress.progress = 0.0
			} else {
				//let totalLength = model.getMasterTrackLength()
				var val = -1 * Float(timeStartedRecording.timeIntervalSinceNow / (TimeInterval(model.getMasterTrackLength()) * 0.0001))
				if val > 1 {
					val = 1.0
				}
				recordingProgress.progress = val
				
				
				timeLabel.text = "\(Double(val) * (TimeInterval(model.getMasterTrackLength()) * 0.0001))"
			
				let myindex = timeLabel.text!.index(timeLabel.text!.startIndex, offsetBy: 4)
				timeLabel.text = "\(timeLabel.text![..<myindex])"
			}
		}
	}
	
	// function that wraps up recording, e.g. sets path field in our data model
	func finishRecording() {
		if currentlyRecordingTrack != nil {
			audioRecorder.stop()
			audioRecorder = nil
			//save after leaving app
			UserDefaults.standard.set(model.getNumberOfTracks(), forKey: "myNumber")
			
			var asset: AVAudioFile?
			
			do {
				try asset = AVAudioFile(forReading: currentlyRecordingTrack!.path)
				
			} catch {
				// error handling
				print("There was an error loading the asset from device memory!")
			}
			
			if asset != nil {
				currentlyRecordingTrack!.length = asset!.length
			}
			
			model.addTrack(new: currentlyRecordingTrack!)
			currentlyRecordingTrack = nil
			trackListView.reloadData()
			
		} else {
			print("Stopped recording when currentlyRecordingTrack was nil")
		}
	}
	
	func recordingTimedOut() {
		finishRecording()
		//recordButton.setTitle("Record New Track", for: .normal)
		recordButton.isEnabled = true
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		//Setting up session
		recordingSession = AVAudioSession.sharedInstance()
		
		//if we have something in our user defaults then we set it as current value for number of records
		if let number:Int = UserDefaults.standard.object(forKey: "myNumber") as? Int
		{
			// TODO not totally sure how we'll load in the old files w/ this method
			// numberOfRecords = number
		}
		AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
			if hasPermission {
				print ("ACCEPTED")
			}
		}
	}
	
	//Function that gets path to directory to save the recordings
	func getDirectory() -> URL
	{
		//search for all urls in document directory
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		//take first one as path
		let documentDirectory = paths[0]
		//return it so now we have url to directory to save audio recording
		return documentDirectory
	}
	
	//Function that displays an alert if something goes wrong
	func displayAlert(title:String, message:String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
		present(alert, animated: true, completion: nil)
	}
	
	//Setting up table view
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return model.getNumberOfTracks()
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		cell.textLabel?.text = String("Track \(indexPath.row + 1)")
		if(indexPath.row%2 == 0) {
			cell.backgroundColor = UIColor(red:0.83, green:0.96, blue:0.95, alpha:1.0)
		} else {
			cell.backgroundColor = UIColor(red:0.96, green:0.83, blue:0.83, alpha:1.0)
		}
		return cell
	}
	
	//listen to recordings
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		//get path for audio recording
		let path = getDirectory().appendingPathComponent("musicapp\(sessionId)-\(indexPath.row + 1).m4a")
		//play recording
		do
		{
			audioPlayer = try AVAudioPlayer(contentsOf: path)
			audioPlayer.play()
		}
		catch
		{
			displayAlert(title: "Oops!", message: "Playback Failed")
		}
	}
	
	// Delete a row
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			print("Deleting a row")
			model.trackList.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .fade)
		} else if editingStyle == .insert {
			// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
		}
	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	

	func handleFinishExport() {
		print("starting async callback")
		do
		{
			audioPlayer = try AVAudioPlayer(contentsOf: getDirectory().appendingPathComponent("\(sessionId)-Final.wav"))
			audioPlayer.play()
		}
		catch
		{
			displayAlert(title: "Oops!", message: "Playback Failed for Exported Song")
		}
		print("finished async callback")
	}
	
	var fileDestinationUrl: URL?
	
	func playmerge()
	{
		let composition = AVMutableComposition()
		//let compositionAudioTrack1:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
		//let compositionAudioTrack2:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
		
		let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
		self.fileDestinationUrl = getDirectory().appendingPathComponent("\(sessionId)-Final.wav")
		
		let filemanager = FileManager.default
		if (!filemanager.fileExists(atPath: self.fileDestinationUrl!.path))
		{
			do
			{
				try filemanager.removeItem(at: self.fileDestinationUrl!)
			}
			catch let error as NSError
			{
				NSLog("Error: \(error)")
			}
			
		}
		else
		{
			do
			{
				try filemanager.removeItem(at: self.fileDestinationUrl!)
			}
			catch let error as NSError
			{
				NSLog("Error: \(error)")
			}
			
		}
		
		var compList: [AVMutableCompositionTrack] = []
		do
		{
			//try compositionAudioTrack1.insertTimeRange(timeRange1, of: assetTrack1, at: kCMTimeZero)
			//try compositionAudioTrack2.insertTimeRange(timeRange2, of: assetTrack2, at: kCMTimeZero)
			for t in model.trackList {
				let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
				let url = t.path
				let avAsset = AVURLAsset(url: url, options: nil)
				var tracks = avAsset.tracks(withMediaType: AVMediaType.audio)
				let assetTrack:AVAssetTrack = tracks[0]
				let duration:CMTime = assetTrack.timeRange.duration
				let timeRange = CMTimeRangeMake(kCMTimeZero, duration)
				
				try compositionAudioTrack.insertTimeRange(timeRange, of: assetTrack, at: kCMTimeZero)
				compList.append(compositionAudioTrack)
			}
		}
		catch
		{
			print(error)
		}
		
		let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
		assetExport?.outputFileType = AVFileType.m4a
		assetExport?.outputURL = fileDestinationUrl!
		assetExport?.exportAsynchronously(completionHandler:
			{
				switch assetExport!.status
				{
				case AVAssetExportSessionStatus.failed:
					print("failed \(assetExport?.error)")
				case AVAssetExportSessionStatus.cancelled:
					print("cancelled \(assetExport?.error)")
				case AVAssetExportSessionStatus.unknown:
					print("unknown\(assetExport?.error)")
				case AVAssetExportSessionStatus.waiting:
					print("waiting\(assetExport?.error)")
				case AVAssetExportSessionStatus.exporting:
					print("exporting\(assetExport?.error)")
				default:
					print("complete")
					self.presentShareScreen()
				}
			
		})
	}
	
	@objc func presentShareScreen() {
		print("About to attempt to present share screen")
		
		let output = AVURLAsset(url: self.fileDestinationUrl!, options: nil)
		/*
		let testString = ["This is a test string", output] as [Any]
		let vc = UIActivityViewController(activityItems: testString, applicationActivities: [])
		DispatchQueue.main.async {
			self.present(vc, animated: true)
		}
		*/
		let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: ["teststring"], applicationActivities:nil)
		//activityViewController.excludedActivityTypes = [.print, .copyToPasteboard, .assignToContact, .saveToCameraRoll, .airDrop]
		
		DispatchQueue.main.async {
			self.present(activityViewController, animated: true, completion: nil);
		}
		// getting this error:
		// finalProject[13151:635117] [ShareSheet] ERROR: <UIActivityViewController: 0x7fa42703e000> timed out waiting to establish a connection to the ShareUI view service extension.
		
		
	}
	
}
