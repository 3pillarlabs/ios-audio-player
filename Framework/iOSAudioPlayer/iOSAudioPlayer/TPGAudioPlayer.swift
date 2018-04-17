//
//  TPGAudioPlayer.swift
//  swiftAudioPlayer
//
//  Created by 3Pillar Global on 9/23/15.
//  Copyright © 2015 3PillarGlobal. All rights reserved.
//

import UIKit
import AVFoundation

/// Used in skipDirection: method.
public enum SkipDirection: Double {
    case backward = -1, forward = 1
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
                    SpringboardData().updateLockScreenCurrentTime(currentTime: currentTimeInSeconds)
                }
            } else {
                player.pause()
            }
        }
    }

    private var timeRangesObservation: Any?

    // MARK: PUBLIC METHODS
    
    /// Method used to return the total duration of the player item.
    public var durationInSeconds: Double {
        get {
            return playerDuration ?? kCMTimeZero.seconds
        }
    }

    public class func sharedInstance() -> TPGAudioPlayer {
        return self.internalInstance
    }
        
    /// Current time in seconds of the current player item.
    public var currentTimeInSeconds: Double {
        get {
            return player.currentTime().seconds
        }
    }
    
    public override init() {
        super.init()

        self.setupNotifications()
    }
    
    /// Method to be called whenever play or pause functionality is needed.
    ///
    /// __springboardInfo__ may contain the following keys:
    ///     - kTitleKey: holds value of title String object
    ///     - kAuthorKey - key for holding the author information
    ///     - kDurationKey - length of the certain player item
    ///     - kListScreenTitleKey - secondary information to be displayed on springboard in sleep mode
    ///     - kImagePathKey - key to be used for holding the path of image to be displayed
    ///
    /// *springboardInfo* is an optional parameter, it can be set to nil if the feature of playing in background while
    /// the device is in sleep mode is desired to be ignored.
    ///
    /// - Parameters:
    ///   - audioUrl: The resource that need to be processed.
    ///   - springboardInfo: dictionary that contains useful information to be displayed when device is in sleep mode
    ///   - startTime: Offset from where the certain processing should start
    ///   - completion: Completion block.
    public func playPauseMediaFile(audioUrl: NSURL, springboardInfo: Dictionary <String, AnyObject>, startTime: Double, completion: @escaping (_ previousItem: String?, _ stopTime: Double) -> ()) {
        
        let stopTime = self.currentTimeInSeconds
        
        if audioUrl.absoluteString == self.currentPlayingItem {
            // Current episode playing
            self.isPlaying = !self.isPlaying
            completion(nil, stopTime)

            return
        }
            
        // Other episode to load
        // Load new episode
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            let options = [AVURLAssetReferenceRestrictionsKey : 0]
            let playerAsset = AVURLAsset(url: audioUrl as URL, options: options)
            self.playerDuration = playerAsset.duration.seconds
            
            DispatchQueue.main.async(execute: {
                //Episode Loaded
                self.prepareAndPlay(playerAsset: playerAsset, startTime: startTime, completion: { () -> Void in
                    //Ready to play
                    let previousPlayingItem = self.currentPlayingItem
                    self.currentPlayingItem = audioUrl.absoluteString
                    
                    completion(previousPlayingItem, stopTime)
                    
                    SpringboardData().setupLockScreenElementsWithDictionary( infoDictionary: springboardInfo as NSDictionary )
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
        
        player.seek(to: newTime) { (finished) -> Void in
            SpringboardData().updateLockScreenCurrentTime(currentTime: self.currentTimeInSeconds)
        }
    }
    
    /*
        Set the current player to a certain time from an input value
    */
    
    public func seekPlayerToTime(value: Double, completion: (() -> Void)!) {
        let newTime = CMTimeMakeWithSeconds(value, 100)
        
        player.seek(to: newTime, completionHandler: { (finished) -> Void in
            if completion != nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion()
                })
            }
        })
    }
    
    /*************************************/
        // MARK: NOTIFICATION METHODS
    /*************************************/
    
    @objc func playingStalled(_ notification: NSNotification) {
        NotificationCenter.default.post(name: .playerStalled, object: player.currentItem)
    }
    
    @objc func playerDidReachEnd(_ notification: NSNotification) {
        self.player.seek(to: kCMTimeZero)
        
        NotificationCenter.default.post(name: .playerDidReachEnd, object: nil)
    }
    
    @objc func playerItemTimeJumpedNotification(_ notification: NSNotification) {
        NotificationCenter.default.post(name: .playerTimeDidChange, object: NSNumber(value: self.currentTimeInSeconds))
    }
    
    /*************************************/
            // MARK: PRIVATE METHODS
    /*************************************/
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(TPGAudioPlayer.playerDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(TPGAudioPlayer.playingStalled(_:)), name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: player.currentItem)

        NotificationCenter.default.addObserver(self, selector: #selector(TPGAudioPlayer.playerItemTimeJumpedNotification(_:)), name: NSNotification.Name.AVPlayerItemTimeJumped, object: nil)
    }
    
    func prepareAndPlay(playerAsset: AVURLAsset, startTime: Double, completion: @escaping (() -> Void)) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            // Code to be added in case of audio session setup error
            print(error)
        }
        
        self.player.pause()
        
        // remove kvo for current item
        timeRangesObservation = nil
        
        // load new asset
        let newPlayerItem = AVPlayerItem(asset: playerAsset)
        
        // replace current item with new player item
        self.player.replaceCurrentItem(with: newPlayerItem)
        
        if let _ = self.player.currentItem {
            timeRangesObservation = player.currentItem?.observe(\.loadedTimeRanges, changeHandler: { (playerItem, change) in
                guard let timeRanges = change.newValue else { return }
                guard let firstTimeRange = timeRanges.first else { return }

                let timeRange = firstTimeRange.timeRangeValue
                let loadedAmout = timeRange.start.seconds + timeRange.duration.seconds
                let loadedPercentage = (loadedAmout * 100.0) / self.durationInSeconds

                NotificationCenter.default.post(name: .mediaLoadProgress, object: NSNumber(value: loadedPercentage))
            })
        }
        
        // seek player to offset
        self.seekPlayerToTime(value: startTime, completion: { [unowned self] in
            self.player.play()
            
            completion()
        })
    }
}
