//
//  ConnexionViewController.swift
//  ProjetSAE
//
//  Created by etudiant on XX/XX/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CompteConnexionPersoViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var motDePasseTextField: UITextField!

    @IBOutlet weak var connexionButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

    }

    // MARK: - Actions
    @IBAction func connexionButtonTapped(_ sender: UIButton) {
        guard
            let mail = mailTextField.text, !mail.isEmpty,
            let motDePasse = motDePasseTextField.text, !motDePasse.isEmpty
        else {
            showAlert(title: "Erreur", message: "Veuillez remplir tous les champs.")
            return
        }

        toggleConnexionUI(enabled: false)
        
        AuthService.login(email: mail, password: motDePasse, expectedType: .perso) { [weak self] result in
            DispatchQueue.main.async {
                self?.toggleConnexionUI(enabled: true)
                switch result {
                case .success(let data):
                    print("✅ Connexion réussie : \(data)")
                    
                    UserDefaults.standard.set(true, forKey: "isConnected")
                    UserDefaults.standard.set("perso", forKey: "typeCompte")
                    
                    (self?.tabBarController as? TonTabBarController)?.mettreAJourTabBar()
                    self?.performSegue(withIdentifier: "goToMonComptePerso", sender: self)

                case .failure(let error):
                    self?.showAlert(title: "Erreur", message: error.localizedDescription)
                }
            }
        }
    }
    func toggleConnexionUI(enabled: Bool) {
        connexionButton.isEnabled = enabled
        connexionButton.alpha = enabled ? 1.0 : 0.5
    }

    // MARK: - Helper
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

