import UIKit
import FirebaseFirestore
import FirebaseAuth
import CoreLocation


class AfficherDetailViewController: UIViewController {
    
    // MARK: Prise et variables
    @IBOutlet weak var NomActionL: UILabel!
    @IBOutlet weak var NomAssoL: UILabel!
    @IBOutlet weak var DebutActionL: UILabel!
    @IBOutlet weak var FinActionL: UILabel!
    @IBOutlet weak var VilleActionL: UILabel!
    @IBOutlet weak var DescActionL: UILabel!
    
    @IBOutlet weak var ContactAssoL: UILabel!
    @IBOutlet weak var MailAssoL: UILabel!
    @IBOutlet weak var TelAssoL: UILabel!
    
    
    @IBOutlet weak var LikeButton: UIButton!
    
    // Varibales
    var recupActionFirebase: Action?
    var recupAssoFirebase: associations?
    var isLiked = false
    
    
    
    // MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad appelé")
        
        if let action = recupActionFirebase {
            // Affichage des données de l'action
            NomActionL.text = action.nom
            DescActionL.text = action.description
            DebutActionL.text = "Date début : \(action.dateDebut)"
            FinActionL.text = "Date fin: \(action.dateFin)"
            ContactAssoL.text = ""
            MailAssoL.text = ""
            TelAssoL.text = ""

            trouverVilleDepuisCoordonnees(latitude: action.latitude, longitude: action.longitude) { ville in
                DispatchQueue.main.async {
                    self.VilleActionL.text = "Ville : \(ville ?? "Inconnue")"
                }
            }

            
            let idAssoDsAction = action.idAsso // Par exemple "/associations/0001" ou "associations/0001"

            // On enlève les "/" en début ou fin de chaîne, s'il y en a
            let idAssoPath = idAssoDsAction.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

            // On découpe le chemin en composants
            let mots = idAssoPath.components(separatedBy: "/")

            // Vérifie qu'on a exactement 2 composants : ["associations", "0001"]
            guard mots.count == 2 else {
                print("❌ Format inattendu : \(idAssoPath)")
                self.NomAssoL.text = "Association inconnue"
                return
            }

            // Récupère l'ID du document Firestore : "0001"
            let idAsso = mots[1]

            let db = Firestore.firestore()
            db.collection("associations").document(idAsso).getDocument { snapshot, error in
                if let error = error {
                    print("Erreur récupération association : \(error.localizedDescription)")
                    self.NomAssoL.text = "Association inconnue"
                    return
                }

                guard let snapshot = snapshot, snapshot.exists,
                      let data = snapshot.data(),
                      let nomAsso = data["nom"] as? String else {
                    print("❌ Données association manquantes ou document non trouvé")
                    self.NomAssoL.text = "Association inconnue"
                    return
                }

                // 🎯 Mise à jour des labels
                self.NomAssoL.text = "Proposé par : \(nomAsso)"
                self.ContactAssoL.text = "Contact :"
                self.MailAssoL.text = data["mail"] as? String ?? "Email non disponible"
                self.TelAssoL.text = data["telephone"] as? String ?? "Téléphone non disponible"
                    
                
            }
            
            verifierSiActionEstLikee()
            
        } else if let asso = recupAssoFirebase {
            // Affichage des données de l'association
            NomActionL.text = asso.nom
            DescActionL.text = asso.description
            DebutActionL.text = "Date création : \(asso.dateCreation)"
            FinActionL.text = ""
            VilleActionL.text = "Adresse : \(asso.adresse)"
            NomAssoL.text = ""
            ContactAssoL.text = "Contact :"
            MailAssoL.text = asso.mail
            TelAssoL.text = asso.telephone
            LikeButton.isHidden = true // Masquer le bouton de like s’il n’a pas de sens ici
        }
    }

    
    
    
    // Trouver la ville à partir de la latitude et de la longitude que l'on récupère de la base
    func trouverVilleDepuisCoordonnees(latitude: Double, longitude: Double, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Erreur de geocodage inverse : \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let ville = placemarks?.first?.locality {
                completion(ville)
            } else {
                completion(nil)
            }
        }
    }
    
    
    
    func verifierSiActionEstLikee() {
        guard let currentUser = Auth.auth().currentUser,
              let action = recupActionFirebase
        else {
            return
        }
        
        let db = Firestore.firestore()
        let userId = currentUser.uid

        db.collection("likes").whereField("userId", isEqualTo: userId).getDocuments { snapshot, error in
        if let error = error {
            print("❌ Erreur récupération likes : \(error.localizedDescription)")
            return
        }
            guard let document = snapshot?.documents.first,
                  let data = document.data()["likes"] as? [[String: Any]]
            else {
                self.isLiked = false
                self.updateBoutonCoeur()
                return
            }
            self.isLiked = data.contains { $0["id"] as? String == action.id }
            self.updateBoutonCoeur()
        }
    }
    
    func updateBoutonCoeur() {
        let imageName = isLiked ? "heart.fill" : "heart"
        LikeButton.setImage(UIImage(systemName: imageName), for: .normal)
        LikeButton.tintColor = isLiked ? .systemRed : .gray
    }

    
    @IBAction func TapSurLiker(_ sender: Any) {
        guard let currentUser = Auth.auth().currentUser,
                      let action = recupActionFirebase else { return }

                let db = Firestore.firestore()
                let userId = currentUser.uid
                let actionDict: [String: Any] = [
                    "id": action.id,
                    "nom": action.nom,
                    "description": action.description,
                    "latitude": action.latitude,
                    "longitude": action.longitude,
                    "dateDebut": action.dateDebut,
                    "dateFin": action.dateFin,
                    "idAsso": action.idAsso
                ]

                let likesRef = db.collection("likes").whereField("userId", isEqualTo: userId)

                likesRef.getDocuments { snapshot, error in
                    if let error = error {
                        print("❌ Erreur lecture des likes : \(error.localizedDescription)")
                        return
                    }

                    if let document = snapshot?.documents.first {
                        var likes = document.data()["likes"] as? [[String: Any]] ?? []

                        if let index = likes.firstIndex(where: { $0["id"] as? String == action.id }) {
                            likes.remove(at: index)
                            self.isLiked = false
                        } else {
                            likes.append(actionDict)
                            self.isLiked = true
                        }

                        db.collection("likes").document(document.documentID).updateData([
                            "likes": likes
                        ]) { error in
                            if let error = error {
                                print("❌ Erreur mise à jour des likes : \(error.localizedDescription)")
                            } else {
                                self.updateBoutonCoeur()
                            }
                        }
                    } else {
                        // Aucun document encore pour ce user -> on en crée un
                        db.collection("likes").addDocument(data: [
                            "userId": userId,
                            "likes": [actionDict]
                        ]) { error in
                            if let error = error {
                                print("❌ Erreur ajout likes : \(error.localizedDescription)")
                            } else {
                                self.isLiked = true
                                self.updateBoutonCoeur()
                            }
                        }
                    }
                }
            }
}
