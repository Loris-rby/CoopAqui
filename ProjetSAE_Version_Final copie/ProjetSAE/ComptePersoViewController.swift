//
//  CompteUtilisateurViewController.swift
//  ProjetSAE
//
//  Created by etudiant on XX/XX/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ComptePersoViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var nomTextField: UITextField!
    @IBOutlet weak var prenomTextField: UITextField!
    @IBOutlet weak var sexeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var motDePasseTextField: UITextField!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    @IBAction func validerButtonTapped(_ sender: UIButton) {
        guard
            let nom = nomTextField.text, !nom.isEmpty,
            let prenom = prenomTextField.text, !prenom.isEmpty,
            let mail = mailTextField.text, !mail.isEmpty,
            let motDePasse = motDePasseTextField.text, !motDePasse.isEmpty
        else {
            print("Veuillez remplir tous les champs.")
            return
        }
        
        let sexeIndex = sexeSegmentedControl.selectedSegmentIndex
        let sexe = sexeSegmentedControl.titleForSegment(at: sexeIndex) ?? "Non spécifié"
        
        // Création de l'utilisateur avec Firebase Auth
        Auth.auth().createUser(withEmail: mail, password: motDePasse) { authResult, error in
            if let error = error {
                print("Erreur de création du compte : \(error.localizedDescription)")
                return
            }
            
            guard let uid = authResult?.user.uid else {
                print("Erreur : UID utilisateur non disponible.")
                return
            }
            
            // Création de l'entrée dans Firestore
            let db = Firestore.firestore()
            let utilisateurData: [String: Any] = [
                "id": uid,
                "nom": nom,
                "prenom": prenom,
                "sexe": sexe,
                "mail": mail,
                "date_inscription": Timestamp(date: Date())
            ]
            
            // Enregistrement dans la collection "citoyens"
            db.collection("Utilisateur").document(uid).setData(utilisateurData) { error in
                if let error = error {
                    print("Erreur lors de l'enregistrement Firestore : \(error.localizedDescription)")
                } else {
                    print("Utilisateur enregistré avec succès.")
                    
                    // Mise à jour de la Tab Bar (titre + icône)
                    (self.tabBarController as? TonTabBarController)?.mettreAJourTabBar()

                    self.performSegue(withIdentifier: "versMonCompte", sender: self)

                }
            }
        }
    }
}

