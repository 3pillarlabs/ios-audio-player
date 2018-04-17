//
//  Notifications.swift
//  iOSAudioPlayer
//
//  Created by David Livadaru on 16/04/2018.
//  Copyright © 2018 3Pillar Global. All rights reserved.
//

import Foundation

public extension Notification.Name {
    /// Triggered each time an media hunk was loaded in queue.
    static let mediaLoadProgress = Notification.Name(rawValue: "com.3pillarglobal.medialoadedstate.notification")

    /// Indicates that the player has stalled.
    ///
    /// object: NSNumber indicating the current player item
    static let playerStalled = Notification.Name(rawValue: "com.3pillarglobal.playerstalled.notification")

    /// Player has reached end.
    static let playerDidReachEnd = Notification.Name(rawValue: "com.3pillarglobal.playerdidreachend.notification")

    /// Player has jumped to a different.
    ///
    /// object: NSNumber indicating the current time the player has jumped to.
    static let playerTimeDidChange = Notification.Name(rawValue: "com.3pillarglobal.playertimejumped.notification")
}
