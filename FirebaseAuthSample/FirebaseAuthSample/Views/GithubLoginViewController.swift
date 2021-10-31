//
//  GithubLoginViewController.swift
//  FirebaseAuthSample
//
//  Created by 김혜수 on 2021/10/31.
//

import UIKit
import FirebaseAuth

class GithubLoginViewController: UIViewController {

    var emailData: String = ""
    @IBOutlet weak var emailLogin: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        emailLogin.text = emailData
    }
    
    @IBAction func logoutButtonClicked(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        self.dismiss(animated: true, completion: nil)
    }
}
