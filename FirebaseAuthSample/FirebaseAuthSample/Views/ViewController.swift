//
//  ViewController.swift
//  FirebaseAuthSample
//
//  Created by taehy.k on 2021/10/21.
//

import UIKit

import Firebase
import FirebaseAuth
import GoogleSignIn

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
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

