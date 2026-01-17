//
//  CompteAssoViewController.swift
//  ProjetSAE
//
//  Created by etudiant on 08/04/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CompteAssoViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var nomTextField: UITextField!
    @IBOutlet weak var representantTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var telephoneTextField: UITextField!
    @IBOutlet weak var adresseTextField: UITextField!
    @IBOutlet weak var motDePasseTextField: UITextField!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

    }
    
    // MARK: - Actions
    @IBAction func validerButtonTapped(_ sender: UIButton) {
        guard
            let nom = nomTextField.text, !nom.isEmpty,
            let representant = representantTextField.text, !representant.isEmpty,
            let descriptionText = descriptionTextField.text, !descriptionText.isEmpty,
            let mail = mailTextField.text, !mail.isEmpty,
            let telephone = telephoneTextField.text, !telephone.isEmpty,
            let adresse = adresseTextField.text, !adresse.isEmpty,
            let motDePasse = motDePasseTextField.text, !motDePasse.isEmpty
        else {
            afficherAlerte(titre: "Champs manquants", message: "Veuillez remplir tous les champs.")
            return
        }
            
        Auth.auth().createUser(withEmail: mail, password: motDePasse) { authResult, error in
            if let error = error {
                self.afficherAlerte(titre: "Erreur", message: error.localizedDescription)
                return
            }
                
            guard let uid = authResult?.user.uid else {
                self.afficherAlerte(titre: "Erreur", message: "Impossible de récupérer l'utilisateur.")
                return
            }
                
            let associationData: [String: Any] = [
                "id": uid,
                "nom": nom,
                "representant": representant,
                "description": descriptionText,
                "mail": mail,
                "telephone": telephone,
                "adresse": adresse,
                "dateCreation": Timestamp(date: Date())
            ]
            
            let db = Firestore.firestore()
            db.collection("associations").document(uid).setData(associationData) { error in
                if let error = error {
                    self.afficherAlerte(titre: "Erreur", message: "Échec lors de l'enregistrement : \(error.localizedDescription)")
                } else {
                    print("Asso enregistrée avec succès.")
                    (self.tabBarController as? TonTabBarController)?.mettreAJourTabBar()
                    self.performSegue(withIdentifier: "versMonCompteAsso", sender: self)
                }
            }
        }
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    
    func afficherAlerte(titre: String, message: String) {
        let alert = UIAlertController(title: titre, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }

}
