//
//  ViewController.swift
//  SplitBill
//
//  Created by Jung Hwan Park on 2021/09/19.
//

import UIKit
import AuthenticationServices
import GoogleSignIn
import Firebase
import CryptoKit
    
class LoginViewController: UIViewController
{
    @IBOutlet weak var loginProviderStackView: UIStackView!
    
    let signInConfig = GIDConfiguration.init(clientID: "669908413130-v75ttsna41geu31vgt85mc1irt35b20v.apps.googleusercontent.com")
    
    fileprivate var currentNonce: String?
    
    let db = Firestore.firestore()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.31, green: 0.62, blue: 0.24, alpha: 1.00)
        setupProviderLoginView()
    }
    @IBAction func signIn(_ sender: Any)
    {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.signIn(with: config, presenting: self)
        { user, error in
            guard
              let authentication = user?.authentication,
              let idToken = authentication.idToken
            else
            {
              return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)

            Auth.auth().signIn(with: credential)
            { (authResult, error) in
                if let error = error
                {
                    print("Error occured during google login")
                    print(error.localizedDescription)
                }
                else
                {
                    print("Login Successful")
                    DispatchQueue.main.async
                    {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
       // performExistingAccountSetupFlows()
    }
    
    /// - Tag: add_appleid_button
    func setupProviderLoginView()
    {
        let authorizationButton = ASAuthorizationAppleIDButton()
        authorizationButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        self.loginProviderStackView.addArrangedSubview(authorizationButton)
    }
    /// - Tag: perform_appleid_request
    @objc
    func handleAuthorizationAppleIDButtonPress()
    {
        startSignInWithAppleFlow()
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate
{
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor
    {
        return self.view.window!
    }
    /// - Tag: did_complete_authorization
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization)
    {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
        {
              guard let nonce = currentNonce else
              {
                  fatalError("Invalid state: A login callback was received, but no login request was sent.")
              }
              guard let appleIDToken = appleIDCredential.identityToken else
              {
                  print("Unable to fetch identity token")
                  return
              }
              guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else
              {
                  print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                  return
              }
              // Initialize a Firebase credential.
              let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                        idToken: idTokenString,
                                                        rawNonce: nonce)
              // Sign in with Firebase.
              Auth.auth().signIn(with: credential)
              { (authResult, error) in
                  if let e = error
                  {
                      // Error. If error.code == .MissingOrInvalidNonce, make sure
                      // you're sending the SHA256-hashed nonce as a hex string with
                      // your request to Apple.
                      print("error: \(e.localizedDescription)")
                      return
                  }
                  else
                  {
                      print(appleIDCredential.user, appleIDCredential.fullName, appleIDCredential.email)
                      if appleIDCredential.email != nil
                      {
                          self.db.collection("appleID").addDocument(data: ["email": appleIDCredential.email,"name": appleIDCredential.fullName?.givenName])
                          { err in
                              if let err = err
                              {
                                  print("Error writing document: \(err)")
                              }
                              else
                              {
                                  print("Document successfully written!")
                              }
                          }
                      }
                      self.showCategoryViewController(userIdentifier: appleIDCredential.user, fullName: appleIDCredential.fullName, email: appleIDCredential.email)
                  }
              }
        }
    }
        // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
        private func randomNonceString(length: Int = 32) -> String
        {
          precondition(length > 0)
          let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
          var result = ""
          var remainingLength = length

          while remainingLength > 0
          {
              let randoms: [UInt8] = (0 ..< 16).map
              { _ in
                  var random: UInt8 = 0
                  let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                  if errorCode != errSecSuccess
                  {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                  }
                  return random
              }
              randoms.forEach
              { random in
                  if remainingLength == 0
                  {
                      return
                  }
                  if random < charset.count
                  {
                      result.append(charset[Int(random)])
                      remainingLength -= 1
                  }
              }
          }
          return result
        }
        
        @available(iOS 13, *)
        private func sha256(_ input: String) -> String
        {
          let inputData = Data(input.utf8)
          let hashedData = SHA256.hash(data: inputData)
          let hashString = hashedData.compactMap
          {
            String(format: "%02x", $0)
          }.joined()

          return hashString
        }
        @available(iOS 13, *)
        func startSignInWithAppleFlow()
        {
            print("startSignInWithAppleFlow")
            let nonce = randomNonceString()
            currentNonce = nonce
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }

    
    private func saveUserInKeychain(_ userIdentifier: String) {
        do {
            try KeychainItem(service: "konkuk.jhpark.SplitBill", account: "userIdentifier").saveItem(userIdentifier)
        } catch {
            print("Unable to save userIdentifier to keychain.")
        }
    }
    
    private func showCategoryViewController(userIdentifier: String, fullName: PersonNameComponents?, email: String?) {
        print("showCategoryVC")
        DispatchQueue.main.async
        {
            print("dismiss")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    /// - Tag: did_complete_error
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error)
    {
        print("Sign in with Apple errored: \(error)")
    }
        
}

extension UIViewController
{
    func showLoginViewController()
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginViewController = storyboard.instantiateViewController(withIdentifier: "loginViewController") as? LoginViewController {
            loginViewController.modalPresentationStyle = .fullScreen
            loginViewController.isModalInPresentation = true
            self.present(loginViewController, animated: true, completion: nil)
        }
    }
}
