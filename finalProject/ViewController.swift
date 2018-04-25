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
    var numberOfRecords:Int = 0
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var trackListView: UITableView!
	@IBOutlet weak var recordingView: UIView!
	
	@IBOutlet weak var playPauseButton: UIButton!
	
	@IBAction func tappedPlayPause(_ sender: UIButton) {
	}
	
    
    @IBAction func record(_ sender: Any) {
        //Check if we have an active recorder (if nil then record)
        if audioRecorder == nil {
            //Update total number of records
            numberOfRecords += 1
            //Defines filename for new recording in m4a format
            let filename = getDirectory().appendingPathComponent("\(numberOfRecords).m4a")
            //Recording settings
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            //Start audio recording
            do
            {
                audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
                audioRecorder.delegate = self
                audioRecorder.record()
                
                
                
                recordButton.setTitle("Stop Recording", for: .normal)
            }
            catch
            {
                displayAlert(title: "Oops!", message: "Recording failed")
            }
        }
        else {
            //Stopping audio recording if no active recorder
            audioRecorder.stop()
            audioRecorder = nil
            //save after leaving app
            UserDefaults.standard.set(numberOfRecords, forKey: "myNumber")
            trackListView.reloadData()
            
            recordButton.setTitle("Start Recording", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Setting up session
        recordingSession = AVAudioSession.sharedInstance()
        
        //if we have something in our user defaults then we set it as current value for number of records
        if let number:Int = UserDefaults.standard.object(forKey: "myNumber") as? Int
        {
            numberOfRecords = number
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
        return numberOfRecords
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = String(indexPath.row + 1)
        return cell
    }
    
    //listen to recordings
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //get path for audio recording
        let path = getDirectory().appendingPathComponent("\(indexPath.row + 1).m4a")
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

