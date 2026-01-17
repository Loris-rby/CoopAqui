//
//  CustomTabBarController.swift
//  ProjetSAE
//
//  Created by etudiant on 07/05/2025.
//

import UIKit
import FirebaseAuth

class TonTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        mettreAJourTabBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mettreAJourTabBar()
    }

    func mettreAJourTabBar() {
        let estConnecte = Auth.auth().currentUser != nil
        if let items = tabBar.items {
            let compteTab = items[3]
            compteTab.title = estConnecte ? "Mon compte" : "Se connecter"
            compteTab.image = UIImage(systemName: estConnecte ? "person.crop.circle.fill" : "person.crop.circle")
        }
    }
}
