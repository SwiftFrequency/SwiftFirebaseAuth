//
//  MainViewController.swift
//  FirebaseAuthSample
//
//  Created by taehy.k on 2021/10/22.
//

import UIKit

import FirebaseAuth

class MainViewController: UIViewController {

    @IBOutlet weak var emailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        fetchCurrentUser()
    }
    
    private func fetchCurrentUser() {
        let email = Auth.auth().currentUser?.email ?? "고객"
        emailLabel.text = "\(email)님"
    }
}
