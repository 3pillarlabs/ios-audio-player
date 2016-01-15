//
//  TPGAudioPlayer.swift
//  swiftAudioPlayer
//
//  Created by 3Pillar Global on 9/23/15.
//  Copyright © 2015 3PillarGlobal. All rights reserved.
//

import UIKit
import AVFoundation

/*
    TPGMediaLoadedStateNotification - triggered each time an media hunk was loaded in queue
*/

public let TPGMediaLoadedStateNotification = "com.3pillarglobal.medialoadedstate.notification"

/*
    TPGPlayerStalledNotification - indicates that the player has stalled
        -> object: NSNumber indicating the current player item
*/

public let TPGPlayerStalledNotification = "com.3pillarglobal.playerstalled.notification"

/*
    TPGPlayerDidReachEndNotification - player has reached end
*/

public let TPGPlayerDidReachEndNotification = "com.3pillarglobal.playerdidreachend.notification"

/*
    TPGPlayerTimeJumpedNotification - player has jumped to a different
        -> object: NSNumber indicating the current time the player has jumped to
*/

public let TPGPlayerTimeJumpedNotification = "com.3pillarglobal.playertimejumped.notification"

let kStartTimeZero                      = 0.0

public let kLoadedTimeRangesKeyPath    = "loadedTimeRanges"

/*
    SkipDirection type used in skipDirection: method
*/

public enum SkipDirection: Double {
    case Backward = -1, Forward = 1
}

public class TPGAudioPlayer: NSObject {
    static let internalInstance = TPGAudioPlayer()
    
    let player = AVPlayer()
    var playerDuration: Double?
    
    var currentPlayingItem: String?
    
    public var isPlaying: Bool {
        get {
            if player.rate == 0.0 {
                return false
            }
            return true
        }
        
        set {
            if newValue == true {
                player.play()
                
                if let _ = self.currentPlayingItem {
                    SpringboardData().updateLockScreenCurrentTime(currentTimeInSeconds)
                }
            } else {
                player.pause()
            }
        }
    }
    
    /*************************************/
            // MARK: PUBLIC METHODS
    /*************************************/
     
    
    /*
        Method used to return the total duration of the player item
    */
    
    public var durationInSeconds: Double {
        get {
            return playerDuration ?? kCMTimeZero.seconds
        }
    }

    /*
        Method used to return the total duration of the player item
    */
    
    public class func sharedInstance() -> TPGAudioPlayer {
        return self.internalInstance
    }
    
    /*
        Returns the current time in seconds of the current player item
    */
        
    public var currentTimeInSeconds: Double {
        get {
            return player.currentTime().seconds
        }
    }
    
    public override init() {
        super.init()

        self.setupNotifications()
    }
    
    /*
        Method to be called whenever play or pause functionality is needed:
            -> audioUrl: the resource that need to be processed
            -> springboardInfo: dictionary that contains useful information to be displayed when device is in sleep mode
                + kTitleKey - holds value of title String object
                + kAuthorKey - key for holding the author information
                + kDurationKey - length of the certain player item
                + kListScreenTitleKey - secondary information to be displayed on springboard in sleep mode
                + kImagePathKey - key to be used for holding the path of image to be displayed
    
            -> startTime: offset from where the certain processing should start
            -> completion: completion block
    
        NOTE: springboardInfo is an optional parameter, it can be set to nil if the feature of playing in background while 
        the device is in sleep mode is desired to be ignored.
    */
    
    public func playPauseMediaFile(audioUrl: NSURL, springboardInfo: Dictionary <String, AnyObject>, startTime: Double, completion: (previousItem: String?, stopTime: Double) -> ()) {
        
        let stopTime = self.currentTimeInSeconds
        
        if audioUrl.absoluteString == self.currentPlayingItem {
            // Current episode playing
            self.isPlaying = !self.isPlaying
            completion(previousItem: nil, stopTime: stopTime)

            return
        }
            
        // Other episode to load
        // Load new episode
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [unowned self] in
            let options = [AVURLAssetReferenceRestrictionsKey : 0]
            let playerAsset = AVURLAsset(URL: audioUrl, options: options)
            self.playerDuration = playerAsset.duration.seconds
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //Episode Loaded
                self.prepareAndPlay(playerAsset, startTime: startTime, completion: { () -> Void in
                    //Ready to play
                    let previousPlayingItem = self.currentPlayingItem
                    self.currentPlayingItem = audioUrl.absoluteString
                    
                    completion(previousItem: previousPlayingItem, stopTime: stopTime)
                    
                    if let springboardData: Dictionary <String, AnyObject> = springboardInfo {
                        SpringboardData().setupLockScreenElementsWithDictionary( springboardData )
                    }
                })
            })
        }
    }
    
    /*
        Method used for skiping a certain time interval from an audio resourse
    */
    
    public func skipDirection(skipDirection: SkipDirection, timeInterval: Double, offset: Double) {
        let skipPercentage = timeInterval / self.durationInSeconds
        let newTime = CMTimeMakeWithSeconds(offset + ((skipDirection.rawValue * skipPercentage) * 2000.0), 100)
        
        player.seekToTime(newTime) { (finished) -> Void in
            SpringboardData().updateLockScreenCurrentTime(self.currentTimeInSeconds)
        }
    }
    
    /*
        Set the current player to a certain time from an input value
    */
    
    public func seekPlayerToTime(value: Double, completion: (() -> Void)!) {
        let newTime = CMTimeMakeWithSeconds(value, 100)
        
        player.seekToTime(newTime, completionHandler: { (finished) -> Void in
            if completion != nil {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion()
                })
            }
        })
    }
   
    /*
        Method used for showing the buffer bar (i.e. amount of the playable file that's been loaded)
    */
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == kLoadedTimeRangesKeyPath && object as? AVPlayerItem === self.player.currentItem {
            if let timeRanges = change?[NSKeyValueChangeNewKey] as? Array<AnyObject> {
                if timeRanges.count > 0 {
                    let timeRange = timeRanges[0].CMTimeRangeValue
                    let loadedAmout = timeRange.start.seconds + timeRange.duration.seconds
                    let loadedPercentage = (loadedAmout * 100.0) / self.durationInSeconds
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(TPGMediaLoadedStateNotification, object: NSNumber(double: loadedPercentage))
                }
            }
        }
    }
    
    /*************************************/
        // MARK: NOTIFICATION METHODS
    /*************************************/
    
    func playingStalled(notification: NSNotification) {
        NSNotificationCenter.defaultCenter().postNotificationName(TPGPlayerStalledNotification, object: player.currentItem)
    }
    
    func playerDidReachEnd(notification: NSNotification) {
        self.player.seekToTime(kCMTimeZero)
        
        NSNotificationCenter.defaultCenter().postNotificationName(TPGPlayerDidReachEndNotification, object: nil)
    }
    
    func playerItenTimeJumpedNotification(notification: NSNotification) {
        NSNotificationCenter.defaultCenter().postNotificationName(TPGPlayerTimeJumpedNotification, object: NSNumber(double: self.currentTimeInSeconds))
    }
    
    /*************************************/
            // MARK: PRIVATE METHODS
    /*************************************/
    
    func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidReachEnd:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playingStalled:", name: AVPlayerItemPlaybackStalledNotification, object: player.currentItem)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItenTimeJumpedNotification:", name: AVPlayerItemTimeJumpedNotification, object: nil)
    }
    
    func prepareAndPlay(playerAsset: AVURLAsset, startTime: Double, completion: (() -> Void)) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        } catch {
            // Code to be added in case of audio session setup error
            print(error)
        }
        
        self.player.pause()
        
        //remove kvo for current item
        let currentItem = self.player.currentItem
        currentItem?.removeObserver(self, forKeyPath: kLoadedTimeRangesKeyPath, context: nil)
        
        //load new asset
        let newPlayerItem = AVPlayerItem(asset: playerAsset)
        
        //replace current item with new player item
        self.player.replaceCurrentItemWithPlayerItem(newPlayerItem)
        
        if let _ = self.player.currentItem {
            self.player.currentItem!.addObserver(self, forKeyPath: kLoadedTimeRangesKeyPath, options: .New, context: nil)
        }
        
        //seek player to offset
        self.seekPlayerToTime(startTime, completion: { [unowned self] in
            self.player.play()
            
            completion()
            })
    }
}
