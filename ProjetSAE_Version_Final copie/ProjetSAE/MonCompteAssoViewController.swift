import UIKit
import FirebaseAuth
import FirebaseFirestore

class MonCompteAssoViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var nomLabel: UILabel!
    @IBOutlet weak var representantLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var telephoneLabel: UILabel!
    @IBOutlet weak var adresseLabel: UILabel!
    @IBOutlet weak var dateCreationLabel: UILabel!
    
    @IBOutlet weak var DeconnexionButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        if let user = Auth.auth().currentUser {
            fetchAssociationData(uid: user.uid)
        } else {
            print("Aucune association connectée.")

        }
        DeconnexionButton.isHidden = Auth.auth().currentUser == nil
    }
    
    // MARK: - Fonctions personnalisées
    func fetchAssociationData(uid: String) {
        let db = Firestore.firestore()
        let docRef = db.collection("associations").document(uid)
        
        docRef.getDocument { document, error in
            if let error = error {
                print("Erreur lors de la récupération des données : \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                let nom = data?["nom"] as? String ?? ""
                let representant = data?["representant"] as? String ?? ""
                let descriptionText = data?["description"] as? String ?? ""
                let mail = data?["mail"] as? String ?? ""
                let telephone = data?["telephone"] as? String ?? ""
                let adresse = data?["adresse"] as? String ?? ""
                let dateCreation = data?["dateCreation"] as? Timestamp
                
                var dateString = ""
                if let dateCreation = dateCreation?.dateValue() {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.locale = Locale(identifier: "fr_FR")
                    dateString = formatter.string(from: dateCreation)
                }
                
                // MAJ des labels
                self.nomLabel.text = nom
                self.representantLabel.text = representant
                self.descriptionLabel.text = descriptionText
                self.mailLabel.text = mail
                self.telephoneLabel.text = telephone
                self.adresseLabel.text = adresse
                self.dateCreationLabel.text = dateString
            } else {
                print("Le document n'existe pas.")
            }
        }
    }
    
    @IBAction func TapSurDeconnexion(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            print("Déconnexion réussie.")
            UserDefaults.standard.set(false, forKey: "isConnected")
            
            // Revenir à l'onglet "Mon compte"
            self.tabBarController?.selectedIndex = 3
            
            // Remonter à la racine (ex: ChoixConnexionViewController)
            if let navController = self.tabBarController?.viewControllers?[3] as? UINavigationController {
                navController.popToRootViewController(animated: true)
            }
            // Mettre à jour la TabBar si besoin
            (self.tabBarController as? TonTabBarController)?.mettreAJourTabBar()
            
        } catch let error as NSError {
            print("Erreur de déconnexion : \(error.localizedDescription)")
        }
    }
    
}
