//
//  LiveRoomViewController.swift
//  OpenLive
//
//  Created by GongYuhua on 6/25/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import UIKit

protocol LiveRoomVCDelegate: NSObjectProtocol {
    func liveVCNeedClose(liveVC: LiveRoomViewController)
}

class LiveRoomViewController: UIViewController {
    
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var remoteContainerView: UIView!
    @IBOutlet weak var broadcastButton: UIButton!
    @IBOutlet var sessionButtons: [UIButton]!
    @IBOutlet weak var audioMuteButton: UIButton!
    
    var roomName: String!
    var clientRole = AgoraRtcClientRole.ClientRole_Dual_Stream_Audience {
        didSet {
            updateButtonsVisiablity()
        }
    }
    var videoProfile: AgoraRtcVideoProfile!
    weak var delegate: LiveRoomVCDelegate?
    
    //MARK: - engine & session view
    var rtcEngine: AgoraRtcEngineKit!
    var agoraEnhancer: AgoraYuvEnhancerObjc?
    private var isBroadcaster: Bool {
        return clientRole == .ClientRole_Dual_Stream_Broadcaster
    }
    private var isMuted = false {
        didSet {
            rtcEngine?.muteLocalAudioStream(isMuted)
            audioMuteButton?.setImage(UIImage(named: isMuted ? "btn_mute_cancel" : "btn_mute"), forState: .Normal)
        }
    }
    
    private var videoSessions = [VideoSession]() {
        didSet {
            guard remoteContainerView != nil else {
                return
            }
            updateInterfaceWithAnimation(true)
        }
    }
    private var fullSession: VideoSession? {
        didSet {
            if fullSession != oldValue && remoteContainerView != nil {
                updateInterfaceWithAnimation(true)
            }
        }
    }
    
    private let viewLayouter = VideoViewLayouter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomNameLabel.text = roomName
        updateButtonsVisiablity()
        
        loadAgoraKit()
    }
    
    //MARK: - user action
    @IBAction func doSwitchCameraPressed(sender: UIButton) {
        rtcEngine?.switchCamera()
    }
    
    @IBAction func doMutePressed(sender: UIButton) {
        isMuted = !isMuted
    }
    
    @IBAction func doBroadcastPressed(sender: UIButton) {
        if isBroadcaster {
            clientRole = .ClientRole_Dual_Stream_Audience
        } else {
            clientRole = .ClientRole_Dual_Stream_Broadcaster
        }
        
        rtcEngine.setClientRole(clientRole)
        updateInterfaceWithAnimation(true)
    }
    
    @IBAction func doDoubleTapped(sender: UITapGestureRecognizer) {
        if fullSession == nil {
            //将双击到的session全屏
            if let tappedSession = viewLayouter.reponseSessionOfGesture(sender, inSessions: videoSessions, inContainerView: remoteContainerView) {
                fullSession = tappedSession
            }
        } else {
            fullSession = nil
        }
    }
    
    @IBAction func doLeavePressed(sender: UIButton) {
        leaveChannel()
    }
}

private extension LiveRoomViewController {
    func updateButtonsVisiablity() {
        guard let sessionButtons = sessionButtons else {
            return
        }
        
        broadcastButton?.setImage(UIImage(named: isBroadcaster ? "btn_join_cancel" : "btn_join"), forState: .Normal)
        
        for button in sessionButtons {
            button.hidden = !isBroadcaster
        }
    }
    
    func leaveChannel() {
        setIdleTimerActive(true)
        
        rtcEngine.setupLocalVideo(nil)
        rtcEngine.leaveChannel(nil)
        if isBroadcaster {
            rtcEngine.stopPreview()
        }
        
        for session in videoSessions {
            session.hostingView.removeFromSuperview()
        }
        videoSessions.removeAll()
        
        agoraEnhancer?.turnOff()
        
        delegate?.liveVCNeedClose(self)
    }
    
    func setIdleTimerActive(active: Bool) {
        UIApplication.sharedApplication().idleTimerDisabled = !active
    }
    
    func alertString(string: String) {
        guard !string.isEmpty else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: string, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
}

private extension LiveRoomViewController {
    func updateInterfaceWithAnimation(animation: Bool) {
        if animation {
            UIView.animateWithDuration(0.3, animations: { [weak self] _ in
                self?.updateInterface()
                self?.view.layoutIfNeeded()
            })
        } else {
            updateInterface()
        }
    }
    
    func updateInterface() {
        var displaySessions = videoSessions
        if !isBroadcaster && !displaySessions.isEmpty {
            displaySessions.removeFirst()
        }
        viewLayouter.layoutSessions(displaySessions, fullSession: fullSession, inContainer: remoteContainerView)
        setStreamTypeForSessions(displaySessions, fullSession: fullSession)
    }
    
    func setStreamTypeForSessions(sessions: [VideoSession], fullSession: VideoSession?) {
        if let fullSession = fullSession {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(UInt(session.uid), type: (session == fullSession ? .VideoStream_High : .VideoStream_Low))
            }
        } else {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(UInt(session.uid), type: .VideoStream_High)
            }
        }
    }
    
    func addLocalSession() {
        let localSession = VideoSession.localSession()
        videoSessions.append(localSession)
        rtcEngine.setupLocalVideo(localSession.canvas)
    }
    
    func fetchSessionOfUid(uid: Int64) -> VideoSession? {
        for session in videoSessions {
            if session.uid == uid {
                return session
            }
        }
        
        return nil
    }
    
    func videoSessionOfUid(uid: Int64) -> VideoSession {
        if let fetchedSession = fetchSessionOfUid(uid) {
            return fetchedSession
        } else {
            let newSession = VideoSession(uid: uid)
            videoSessions.append(newSession)
            return newSession
        }
    }
}

//MARK: - Agora Media SDK
private extension LiveRoomViewController {
    func loadAgoraKit() {
        rtcEngine = AgoraRtcEngineKit.sharedEngineWithVendorKey(VendorKey, applicationCategory: .ApplicationCategory_LiveBroadcasting, delegate: self)
        rtcEngine.enableVideo()
        rtcEngine.setVideoProfile(videoProfile)
        rtcEngine.setClientRole(clientRole)
        
        if isBroadcaster {
            rtcEngine.startPreview()
        }
        
        addLocalSession()
        
        let code = rtcEngine.joinChannelByKey(nil, channelName: roomName, info: nil, uid: 0, joinSuccess: nil)
        if code == 0 {
            setIdleTimerActive(false)
            rtcEngine.setEnableSpeakerphone(true)
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.alertString("Join channel failed: \(code)")
            })
        }
        
        if isBroadcaster {
            let enhancer = AgoraYuvEnhancerObjc()
            enhancer.turnOn()
            self.agoraEnhancer = enhancer
        }
    }
}

extension LiveRoomViewController: AgoraRtcEngineDelegate {
    func rtcEngine(engine: AgoraRtcEngineKit!, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        let userSession = videoSessionOfUid(Int64(uid))
        rtcEngine.setupRemoteVideo(userSession.canvas)
    }
    
    func rtcEngine(engine: AgoraRtcEngineKit!, firstLocalVideoFrameWithSize size: CGSize, elapsed: Int) {
        if let _ = videoSessions.first {
            updateInterfaceWithAnimation(false)
        }
    }
    
    func rtcEngine(engine: AgoraRtcEngineKit!, didOfflineOfUid uid: UInt, reason: AgoraRtcUserOfflineReason) {
        var indexToDelete: Int?
        for (index, session) in videoSessions.enumerate() {
            if session.uid == Int64(uid) {
                indexToDelete = index
            }
        }
        
        if let indexToDelete = indexToDelete {
            let deletedSession = videoSessions.removeAtIndex(indexToDelete)
            deletedSession.hostingView.removeFromSuperview()
            
            if deletedSession == fullSession {
                fullSession = nil
            }
        }
    }
}
