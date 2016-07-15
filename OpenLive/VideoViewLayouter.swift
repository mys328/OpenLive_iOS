//
//  VideoViewLayouter.swift
//  OpenLive
//
//  Created by GongYuhua on 6/25/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import UIKit

class VideoViewLayouter {
    
    private var layoutConstraints = [NSLayoutConstraint]()
    
    func layoutSessions(sessions: [VideoSession], fullSession: VideoSession?, inContainer container: UIView) {
        
        guard !sessions.isEmpty else {
            return
        }
        
        NSLayoutConstraint.deactivateConstraints(layoutConstraints)
        layoutConstraints.removeAll()
        
        for session in sessions {
            session.hostingView.removeFromSuperview()
        }
        
        if let fullSession = fullSession {
            layoutConstraints.appendContentsOf(layoutFullScreenView(fullSession.hostingView, inContainerView: container))
            let smallViews = viewListFromSessions(sessions, maxCount: 3, ignorSession: fullSession)
            layoutConstraints.appendContentsOf(layoutSmallViews(smallViews, inContainerView: container))
        } else {
            let allViews = viewListFromSessions(sessions, maxCount: 4, ignorSession: nil)
            layoutConstraints.appendContentsOf(layoutGridViews(allViews, inContainerView: container))
        }
        
        if !layoutConstraints.isEmpty {
            NSLayoutConstraint.activateConstraints(layoutConstraints)
        }
    }
    
    func reponseSessionOfGesture(gesture: UIGestureRecognizer, inSessions sessions: [VideoSession], inContainerView container: UIView) -> VideoSession? {
        let location = gesture.locationInView(container)
        for session in sessions {
            if let view = session.hostingView where view.frame.contains(location) {
                return session
            }
        }
        return nil
    }
}

//MARK: - layouts
private extension VideoViewLayouter {
    func viewListFromSessions(sessions: [VideoSession], maxCount: Int, ignorSession: VideoSession?) -> [UIView] {
        var views = [UIView]()
        for session in sessions {
            if session == ignorSession {
                continue
            }
            views.append(session.hostingView)
            if views.count >= maxCount {
                break
            }
        }
        return views
    }
    
    func layoutFullScreenView(view: UIView, inContainerView container: UIView) -> [NSLayoutConstraint] {
        container.addSubview(view)
        var layouts = [NSLayoutConstraint]()
        
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: ["view": view])
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: ["view": view])
        layouts.appendContentsOf(constraintsH)
        layouts.appendContentsOf(constraintsV)
        
        return layouts
    }
    
    func layoutSmallViews(smallViews: [UIView], inContainerView container: UIView) -> [NSLayoutConstraint] {
        var layouts = [NSLayoutConstraint]()
        var lastView: UIView?
        
        let itemSpace: CGFloat = 5
        
        for view in smallViews {
            container.addSubview(view)
            let viewWidth = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 100)
            let viewHeight = NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 100)
            
            let viewTop = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: container, attribute: .Top, multiplier: 1, constant: 60 + itemSpace)
            let viewLeft: NSLayoutConstraint
            if let lastView = lastView {
                viewLeft = NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: lastView, attribute: .Right, multiplier: 1, constant: itemSpace)
            } else {
                viewLeft = NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: container, attribute: .Left, multiplier: 1, constant: itemSpace)
            }
            
            layouts.appendContentsOf([viewWidth, viewHeight, viewLeft, viewTop])
            lastView = view
        }
        
        return layouts
    }
    
    func layoutGridViews(allViews: [UIView], inContainerView container: UIView) -> [NSLayoutConstraint] {
        let viewInset: CGFloat = 0.5
        var layouts = [NSLayoutConstraint]()
        
        switch allViews.count {
        case 0: break
        case 1:
            layouts.appendContentsOf(layoutFullScreenView(allViews.first!, inContainerView: container))
        case 2:
            let firstView = allViews.first!
            let lastView = allViews.last!
            container.addSubview(firstView)
            container.addSubview(lastView)
            
            let h1 = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: ["view": firstView])
            let h2 = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: ["view": lastView])
            let v = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view1]-(\(viewInset))-[view2]|", options: [], metrics: nil, views: ["view1": firstView, "view2": lastView])
            let equal = NSLayoutConstraint(item: firstView, attribute: .Height, relatedBy: .Equal, toItem: lastView, attribute: .Height, multiplier: 1, constant: 0)
            layouts.appendContentsOf(h1)
            layouts.appendContentsOf(h2)
            layouts.appendContentsOf(v)
            layouts.append(equal)
        case 3:
            let firstView = allViews.first!
            let secondView = allViews[1]
            let lastView = allViews.last!
            container.addSubview(firstView)
            container.addSubview(secondView)
            container.addSubview(lastView)
            
            let h1 = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view1]-\(viewInset)-[view2]|", options: [], metrics: nil, views: ["view1": firstView, "view2": secondView])
            let v1 = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view1]-\(viewInset)-[view2]|", options: [], metrics: nil, views: ["view1": firstView, "view2": lastView])
            let left = NSLayoutConstraint(item: lastView, attribute: .Left, relatedBy: .Equal, toItem: container, attribute: .Left, multiplier: 1, constant: 0)
            let top = NSLayoutConstraint(item: secondView, attribute: .Top, relatedBy: .Equal, toItem: container, attribute: .Top, multiplier: 1, constant: 0)
            let equalWidth1 = NSLayoutConstraint(item: firstView, attribute: .Width, relatedBy: .Equal, toItem: secondView, attribute: .Width, multiplier: 1, constant: 0)
            let equalWidth2 = NSLayoutConstraint(item: firstView, attribute: .Width, relatedBy: .Equal, toItem: lastView, attribute: .Width, multiplier: 1, constant: 0)
            let equalHeight1 = NSLayoutConstraint(item: firstView, attribute: .Height, relatedBy: .Equal, toItem: secondView, attribute: .Height, multiplier: 1, constant: 0)
            let equalHeight2 = NSLayoutConstraint(item: firstView, attribute: .Height, relatedBy: .Equal, toItem: lastView, attribute: .Height, multiplier: 1, constant: 0)
            layouts.appendContentsOf(h1)
            layouts.appendContentsOf(v1)
            layouts.appendContentsOf([left, top, equalWidth1, equalWidth2, equalHeight1, equalHeight2])
        default:
            let firstView = allViews.first!
            let secondView = allViews[1]
            let thirdView = allViews[2]
            let lastView = allViews[3]
            container.addSubview(firstView)
            container.addSubview(secondView)
            container.addSubview(thirdView)
            container.addSubview(lastView)
            
            let h1 = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view1]-\(viewInset)-[view2]|", options: [], metrics: nil, views: ["view1": firstView, "view2": secondView])
            let h2 = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view1]-\(viewInset)-[view2]|", options: [], metrics: nil, views: ["view1": thirdView, "view2": lastView])
            let v1 = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view1]-\(viewInset)-[view2]|", options: [], metrics: nil, views: ["view1": firstView, "view2": thirdView])
            let v2 = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view1]-\(viewInset)-[view2]|", options: [], metrics: nil, views: ["view1": secondView, "view2": lastView])
            
            let equalWidth1 = NSLayoutConstraint(item: firstView, attribute: .Width, relatedBy: .Equal, toItem: secondView, attribute: .Width, multiplier: 1, constant: 0)
            let equalWidth2 = NSLayoutConstraint(item: firstView, attribute: .Width, relatedBy: .Equal, toItem: thirdView, attribute: .Width, multiplier: 1, constant: 0)
            let equalHeight1 = NSLayoutConstraint(item: firstView, attribute: .Height, relatedBy: .Equal, toItem: secondView, attribute: .Height, multiplier: 1, constant: 0)
            let equalHeight2 = NSLayoutConstraint(item: firstView, attribute: .Height, relatedBy: .Equal, toItem: thirdView, attribute: .Height, multiplier: 1, constant: 0)
            
            layouts.appendContentsOf(h1)
            layouts.appendContentsOf(v1)
            layouts.appendContentsOf(h2)
            layouts.appendContentsOf(v2)
            layouts.appendContentsOf([equalWidth1, equalWidth2, equalHeight1, equalHeight2])
        }
        
        return layouts
    }
}
