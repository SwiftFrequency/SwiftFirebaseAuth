//
//  ViewController.swift
//  FirebaseAuthSample
//
//  Created by taehy.k on 2021/10/21.
//

import UIKit

import FBSDKLoginKit
import Firebase
import FirebaseAuth
import GoogleSignIn

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    fileprivate var isMFAEnabled = false
        
    private let permissions: [String] = ["public_profile", "email"]
    
    @IBOutlet weak var facebookButton: FBLoginButton!
    private lazy var facebookSignInButton: FBLoginButton = {
        let btn = FBLoginButton()
        btn.permissions = permissions
        return btn
    }()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFacebook()
    }
    
    // MARK: - Cutom Methods
    
    private func setupFacebook() {
        view.addSubview(facebookButton)
        facebookButton.center = view.center
        facebookButton.delegate = self
    }
    
    // (1) 구글 로그인 버튼 클릭
    @IBAction func googleSignInButtonDidTap(_ sender: Any) {
        performGoogleSignInFlow()
    }
    
    // (2) 구글 로그인 플로우 수행
    private func performGoogleSignInFlow() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let signInConfig = GIDConfiguration(clientID: clientID)
        
        // 구글의 OAuth 서비스를 이용해서 권한을 위임 받은 행위
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: self) { [weak self] user, error in
            guard error == nil else { return }
            
            guard let authentication = user?.authentication,
                  let idToken = authentication.idToken
            else { return }
            
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)
            
            
            // 서버 없이 파이어베이스를 이용하기로 함
            // 파이어베이스(내 서버)에 구글로부터 위임 받은 인증키를 넘겨주는 작업 (OAuth 방식)
            Auth.auth().signIn(with: credential) { result, error in
                guard error == nil else { return print("error")}
                
                self?.transitionToDetailViewController()
            }
        }
    }
    
    // (3) DetailVC로 화면 전환
    private func transitionToDetailViewController() {
        // 대부분의 vc에서 모달 형식으로 뷰를 띄워준다.
        // 하지만 일부 클래스마다 재정의 되어있어 다르게 동작하는 경우가 있다.
        // ex) 네비게이션 뷰 컨트롤러에서는 push 형태로 뷰를 띄운다.
        
        // change window rootViewController
        
        guard let window = self.view.window else { return }
        let mainVC = self.storyboard?.instantiateViewController(withIdentifier: "MainViewController")
        
        
        let transition = CATransition()
        transition.type = .fade
        transition.duration = 0.2
        
        window.layer.add(transition, forKey: kCATransition)
        window.rootViewController = mainVC
        window.makeKeyAndVisible()
    }
}

// MARK: - Facebook LoginButtonDelegate

extension ViewController: LoginButtonDelegate {
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        if let accessToken = AccessToken.current?.tokenString {
            print("토큰", accessToken)
            
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    let authError = error as NSError
                    if self.isMFAEnabled, authError.code == AuthErrorCode.secondFactorRequired.rawValue {
                        // The user is a multi-factor user. Second factor challenge is required.
                        let resolver = authError
                            .userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
                        var displayNameString = ""
                        for tmpFactorInfo in resolver.hints {
                            displayNameString += tmpFactorInfo.displayName ?? ""
                            displayNameString += " "
                        }
                        self.showTextInputPrompt(
                            withMessage: "Select factor to sign in\n\(displayNameString)",
                            completionBlock: { userPressedOK, displayName in
                                var selectedHint: PhoneMultiFactorInfo?
                                for tmpFactorInfo in resolver.hints {
                                    if displayName == tmpFactorInfo.displayName {
                                        selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
                                    }
                                }
                                PhoneAuthProvider.provider()
                                    .verifyPhoneNumber(with: selectedHint!, uiDelegate: nil,
                                                       multiFactorSession: resolver
                                                        .session) { verificationID, error in
                                        if error != nil {
                                            print(
                                                "Multi factor start sign in failed. Error: \(error.debugDescription)"
                                            )
                                        } else {
                                            self.showTextInputPrompt(
                                                withMessage: "Verification code for \(selectedHint?.displayName ?? "")",
                                                completionBlock: { userPressedOK, verificationCode in
                                                    let credential: PhoneAuthCredential? = PhoneAuthProvider.provider()
                                                        .credential(withVerificationID: verificationID!,
                                                                    verificationCode: verificationCode!)
                                                    let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator
                                                        .assertion(with: credential!)
                                                    resolver.resolveSignIn(with: assertion!) { authResult, error in
                                                        if error != nil {
                                                            print(
                                                                "Multi factor finanlize sign in failed. Error: \(error.debugDescription)"
                                                            )
                                                        } else {
                                                            self.navigationController?.popViewController(animated: true)
                                                        }
                                                    }
                                                }
                                            )
                                        }
                                    }
                            }
                        )
                    } else {
                        self.showMessagePrompt(error.localizedDescription)
                        return
                    }
                    return
                }
                self.transitionToDetailViewController()
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("로그아웃")
    }
}

// MARK: - Extra Extension

extension ViewController {
    
    func showMessagePrompt(_ message: String) {
      let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
      let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
      alert.addAction(okAction)
      present(alert, animated: false, completion: nil)
    }
    
    func showTextInputPrompt(withMessage message: String,
                               completionBlock: @escaping ((Bool, String?) -> Void)) {
        let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
          completionBlock(false, nil)
        }
        weak var weakPrompt = prompt
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
          guard let text = weakPrompt?.textFields?.first?.text else { return }
          completionBlock(true, text)
        }
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(cancelAction)
        prompt.addAction(okAction)
        present(prompt, animated: true, completion: nil)
      }
}
