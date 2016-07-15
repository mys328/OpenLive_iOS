//
//  MainViewController.swift
//  OpenLive
//
//  Created by GongYuhua on 6/25/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var popoverSourceView: UIView!
    
    private var videoProfile = AgoraRtcVideoProfile._VideoProfile_360P
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let segueId = segue.identifier else {
            return
        }
        
        switch segueId {
        case "mainToSettings":
            let settingsVC = segue.destinationViewController as! SettingsViewController
            settingsVC.videoProfile = videoProfile
            settingsVC.delegate = self
        case "mainToLive":
            let liveVC = segue.destinationViewController as! LiveRoomViewController
            liveVC.roomName = roomNameTextField.text!
            liveVC.videoProfile = videoProfile
            if let value = sender as? NSNumber, let role = AgoraRtcClientRole(rawValue: value.integerValue) {
                liveVC.clientRole = role
            }
            liveVC.delegate = self
        default:
            break
        }
    }
}

private extension MainViewController {
    func showRoleSelection() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let broadcaster = UIAlertAction(title: "Broadcaster", style: .Default) { [weak self] _ in
            self?.joinWithRole(.ClientRole_Dual_Stream_Broadcaster)
        }
        let audience = UIAlertAction(title: "Audience", style: .Default) { [weak self] _ in
            self?.joinWithRole(.ClientRole_Dual_Stream_Audience)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        sheet.addAction(broadcaster)
        sheet.addAction(audience)
        sheet.addAction(cancel)
        sheet.popoverPresentationController?.sourceView = popoverSourceView
        sheet.popoverPresentationController?.permittedArrowDirections = .Up
        presentViewController(sheet, animated: true, completion: nil)
    }
}

private extension MainViewController {
    func joinWithRole(role: AgoraRtcClientRole) {
        performSegueWithIdentifier("mainToLive", sender: NSNumber(integer: role.rawValue))
    }
}

extension MainViewController: SettingsVCDelegate {
    func settingsVC(settingsVC: SettingsViewController, didSelectProfile profile: AgoraRtcVideoProfile) {
        videoProfile = profile
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension MainViewController: LiveRoomVCDelegate {
    func liveVCNeedClose(liveVC: LiveRoomViewController) {
        navigationController?.popViewControllerAnimated(true)
    }
}

extension MainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let string = textField.text where !string.isEmpty {
            showRoleSelection()
        }
        
        return true
    }
}
