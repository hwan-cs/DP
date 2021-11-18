//
//  AppDelegate.swift
//  SplitBill
//
//  Created by Jung Hwan Park on 2021/09/19.
//

import UIKit
import AuthenticationServices
import GoogleSignIn
import Firebase
import FirebaseDynamicLinks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?
    var orientationLock = UIInterfaceOrientationMask.all
    var flag: Bool = true
    
    override init()
    {
        FirebaseApp.configure()
    }
    /// - Tag: did_finish_launching
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        GIDSignIn.sharedInstance.restorePreviousSignIn
        { user, error in
            if error != nil || user == nil
            {
                DispatchQueue.main.async
                {
                    self.flag = false
                    self.window?.rootViewController?.showLoginViewController()
                }
              // Show the app's signed-out state.
            }
        }
        if flag
        {
            return true
        }
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: KeychainItem.currentUserIdentifier) { (credentialState, error) in
            switch credentialState {
            case .authorized:
                break // The Apple ID credential is valid.
            case .revoked, .notFound:
                // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                DispatchQueue.main.async {
                    self.window?.rootViewController?.showLoginViewController()
                }
            default:
                break
            }
        }
        return true
    }
    
    func handleIncomingDynamicLink(_ dynamiclink: DynamicLink)
    {
        guard let url = dynamiclink.url else
        {
            print("my dynamic link object has no url")
            return
        }
        print("your incoming link parameter is \(url.absoluteString)")

        guard (dynamiclink.matchType == .unique || dynamiclink.matchType == .default) else
        {
            print("Not a strong enough match to continue")
            return
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return }

        if components.path == "/events"
        {
            if let eventFIRDocIDQueryItem = queryItems.first(where: { $0.name == "FIRDocID" })
            {
                guard let eventFIRDocID = eventFIRDocIDQueryItem.value else { return }
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

                guard let newDetailVC = storyboard.instantiateViewController(withIdentifier: "detailViewController") as? DetailViewController else { return }

                let newEvent = PaymentEvent(FIRDocID: eventFIRDocID, eventName: "", dateCreated: 0.0, participants: [""], price: 0.0, eventDate: "", isOwner: false)
                newDetailVC.event = newEvent
                (self.window?.rootViewController as? UINavigationController)?.popToRootViewController(animated: true)
                (self.window?.rootViewController as? UINavigationController)?.pushViewController(newDetailVC, animated: true)
            }
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        if let incomingURL = userActivity.webpageURL
        {
            print("Incoming URL is \(incomingURL)")
            let linkHandled = DynamicLinks.dynamicLinks()
              .handleUniversalLink(incomingURL)
            { dynamiclink, error in
                guard error == nil else
                {
                    print("found an error! \(error?.localizedDescription)")
                    return
                }
                if let dynamiclink = dynamiclink
                {
                    self.handleIncomingDynamicLink(dynamiclink)
                }
            }
            if linkHandled
            {
                return true
            }
            else
            {
                return false
            }
        }
        return false
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
    {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url)
        {
            self.handleIncomingDynamicLink(dynamicLink)
            return true
        }
        else
        {
            //maybe handle google signin here
            return false
        }
        var handled: Bool
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled
        {
            return true
        }
        return GIDSignIn.sharedInstance.handle(url)
    }
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
    {
        return self.orientationLock
    }
}

