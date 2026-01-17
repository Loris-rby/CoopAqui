//
//  MonCompteViewController.swift
//  ProjetSAE
//
//  Created by etudiant on 24/04/2025.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

class MonCompteViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var nom: UILabel!
    @IBOutlet weak var prenom: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var sexe: UILabel!
    @IBOutlet weak var mail: UILabel!
    
    @IBOutlet weak var DéconnexionButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        if let user = Auth.auth().currentUser {
            let uid = user.uid
            fetchUserData(uid: uid) 
        } else {
            print("Aucun utilisateur connecté.")
        }
        DéconnexionButton.isHidden = Auth.auth().currentUser == nil

    }

    // MARK: - Fonctions personnalisées
    func fetchUserData(uid: String) {
        let db = Firestore.firestore()
        let docRef = db.collection("Utilisateur").document(uid)
        
        docRef.getDocument { document, error in
            if let error = error {
                print("Erreur lors de la récupération des données : \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                let nom = data?["nom"] as? String ?? ""
                let prenom = data?["prenom"] as? String ?? ""
                let sexe = data?["sexe"] as? String ?? ""
                let mail = data?["mail"] as? String ?? ""
                let dateInscription = data?["date_inscription"] as? Timestamp

                // Formatage de la date si elle existe
                var dateString = ""
                if let dateInscription = dateInscription?.dateValue() {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    formatter.locale = Locale(identifier: "fr_FR")
                    dateString = formatter.string(from: dateInscription)
                }

                // Mise à jour des labels
                self.nom.text = nom
                self.prenom.text = prenom
                self.mail.text = mail
                self.sexe.text = sexe
                self.date.text = dateString
            }
        }
    }
    
    @IBAction func TapSurDéconnexion(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            print("Déconnexion réussie.")
            UserDefaults.standard.set(false, forKey: "isConnected")
            
            // Revenir à l’onglet "Mon compte"
            self.tabBarController?.selectedIndex = 3
            
            // Remonter à la racine (ex: ChoixConnexionViewController)
            if let navController = self.tabBarController?.viewControllers?[3] as? UINavigationController {
                navController.popToRootViewController(animated: true)
            }
            
            // Mettre à jour l'icône et le titre de l'onglet
            (self.tabBarController as? TonTabBarController)?.mettreAJourTabBar()
            
        } catch let error as NSError {
            print("Erreur de déconnexion : \(error.localizedDescription)")
        }
    }
}
