//
//  ViewController.swift
//  DemoAudioPlayer
//
//  Created by 3Pillar Global on 10/01/16.
//  Copyright © 2016 3Pillar Global. All rights reserved.
//

import UIKit
import iOSAudioPlayer

let kTestLink = "http://traffic.libsyn.com/innovationengine/Disruptive_Innovation_in_Media__Entertainment.mp3"
let kTestImage = "Icon"
let kTestTimeInterval = 20.0

class ViewController: UIViewController {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var fastforwardButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var sliderTimer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(red: 38.0/255, green: 50.0/255, blue: 56.0/255, alpha: 1.0)
        
        self.hideLoadingIndicator()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear( animated )
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "episodeLoadedNotification:", name: TPGMediaLoadedStateNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver( self )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Notifications
    
    func episodeLoadedNotification(notification: NSNotification) {
        if let percentage: NSNumber = notification.object as? NSNumber {
            self.statusLabel.text = "\(percentage.integerValue)% Loaded"
        }
    }

    
    // MARK: Actions

    @IBAction func playButtonPressed(sender: AnyObject) {
        /*
        Create the dictionary for springboard information
        */
        let dictionary: Dictionary <String, AnyObject> = SpringboardData.springboardDictionary("Demo Album", artist: "Demo Artist", duration: Int (300.0), listScreenTitle: "Demo List Screen Title", imagePath: NSBundle.mainBundle().pathForResource(kTestImage, ofType: "png")!)
        
        /*
        Start Player
        */
        
        self.showLoadingIndicator()
        
        TPGAudioPlayer.sharedInstance().playPauseMediaFile(NSURL(string: kTestLink)!, springboardInfo: dictionary, startTime: 0.0, completion: {(_ , stopTime) -> () in
            
            self.hideLoadingIndicator()
            self.setupSlider()
            self.updatePlayButton()
        } )
    }
    
    @IBAction func rewindButtonPressed(sender: AnyObject) {
        TPGAudioPlayer.sharedInstance().skipDirection(SkipDirection.Backward, timeInterval: kTestTimeInterval, offset: TPGAudioPlayer.sharedInstance().currentTimeInSeconds)
    }
    
    @IBAction func fastforwardButtonPressed(sender: AnyObject) {
        TPGAudioPlayer.sharedInstance().skipDirection(SkipDirection.Forward, timeInterval: kTestTimeInterval, offset: TPGAudioPlayer.sharedInstance().currentTimeInSeconds)
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        if TPGAudioPlayer.sharedInstance().isPlaying {
            TPGAudioPlayer.sharedInstance().seekPlayerToTime(Double( sender.value ), completion: {() -> () in
                self.updatePlayButton()
            })
        }
    }
    
    func updatePlayButton() {
        let playPauseImage = (TPGAudioPlayer.sharedInstance().isPlaying ? UIImage(named: "pause") : UIImage(named: "play"))
        
        self.playButton.setImage(playPauseImage, forState: .Normal)
    }
    
    func setupSlider() {
        self.progressSlider.maximumValue = Float( TPGAudioPlayer.sharedInstance().durationInSeconds )
        self.progressSlider.minimumValue = 0.0
        
        if let _ = self.sliderTimer {
            self.sliderTimer?.invalidate()
        }
        
        self.sliderTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "sliderTimerTriggered", userInfo: nil, repeats: true)

        self.setupTotalTimeLabel()
    }
    
    func sliderTimerTriggered() {
        let playerCurrentTime = TPGAudioPlayer.sharedInstance().currentTimeInSeconds
        
        self.progressSlider.value = Float( playerCurrentTime )
        
        self.updateCurrentTimeLabel(Float( playerCurrentTime ))
    }
    
    func updateCurrentTimeLabel(currentTimeInSeconds: Float) {
        if currentTimeInSeconds.isNaN || currentTimeInSeconds.isInfinite {
            return
        }
        
        currentTimeLabel.text = timeLabelString( Int( currentTimeInSeconds ) )
    }
    
    func setupTotalTimeLabel() {
        let duration = TPGAudioPlayer.sharedInstance().durationInSeconds
        
        if duration.isNaN || duration.isInfinite {
            return
        }
        
        totalTimeLabel.text = timeLabelString( Int (duration) )
    }
    
    func showLoadingIndicator() {
        self.playButton.hidden = true
        self.loadingIndicator.hidden = false
        
        self.loadingIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        self.playButton.hidden = false
        self.loadingIndicator.hidden = true
        
        self.loadingIndicator.stopAnimating()
    }
    
    func timeLabelString(duration: Int) -> String {
        let currentMinutes = Int(duration) / 60
        let currentSeconds = Int(duration) % 60
        
        return currentSeconds < 10 ? "\(currentMinutes):0\(currentSeconds)" : "\(currentMinutes):\(currentSeconds)"
    }
}