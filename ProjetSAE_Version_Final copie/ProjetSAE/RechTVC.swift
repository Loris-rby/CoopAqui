import UIKit
import FirebaseFirestore

class RechTVC: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var RechTF: UITextField!
    
    let db = Firestore.firestore()
    
    var toutesLesActions: [Action] = [] // Toutes les actions depuis Firestore
    var resultatRecherche: [Action] = [] // Actions filtrées après recherche

    
    override func viewDidLoad() {
        super.viewDidLoad()
        RechTF.delegate = self
        chargerActionsDepuisFirestore()
        
    }

    
    // Récupère les actions de la base Firestore
    func chargerActionsDepuisFirestore() {
        db.collection("Action").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Erreur Firestore : \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            self.toutesLesActions = documents.compactMap { doc in
                let data = doc.data()
                guard
                    let nom = data["nom"] as? String,
                    let description = data["description"] as? String,
                    let latitude = data["latitude"] as? Double,
                    let longitude = data["longitude"] as? Double,
                    let dateDebut = data["date_debut"] as? String,
                    let dateFin = data["date_Fin"] as? String,
                    let idAssoRef = data["id_asso"] as? DocumentReference
                else { return nil }

                return Action(
                    id: doc.documentID,
                    nom: nom,
                    description: description,
                    latitude: latitude,
                    longitude: longitude,
                    dateDebut: dateDebut,
                    dateFin: dateFin,
                    idAsso: idAssoRef.path
                )
            }

            self.resultatRecherche = self.toutesLesActions
            self.tableView.reloadData()
        }
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        lancerRecherche()
        return true
    }
    
    func lancerRecherche() {
        guard let motRecherche = RechTF.text?.lowercased(), !motRecherche.isEmpty else {
            resultatRecherche = toutesLesActions
            tableView.reloadData()
            return
        }

        resultatRecherche = toutesLesActions.filter { action in
            return action.nom.lowercased().contains(motRecherche) ||
                   action.description.lowercased().contains(motRecherche) ||
                   action.dateDebut.lowercased().contains(motRecherche) ||
                   action.dateFin.lowercased().contains(motRecherche)
        }

        tableView.reloadData()
    }

    
    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultatRecherche.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let uneCellule = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)

        let action = resultatRecherche[indexPath.row]
        uneCellule.textLabel?.text = action.nom
        uneCellule.detailTextLabel?.text = "\(action.description) - du \(action.dateDebut) au \(action.dateFin)"

        return uneCellule
    }

    
    // MARK: - Navigation

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "idsegue", sender: tableView.cellForRow(at: indexPath))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "idsegue" {
            guard let uneCellule = sender as? UITableViewCell,
                  let indexPath = tableView.indexPath(for: uneCellule),
                  let leControlDetail = segue.destination as? AfficherDetailViewController else {
                return
            }

            let action = resultatRecherche[indexPath.row]
            leControlDetail.recupActionFirebase = action // ⚠️ Crée cette variable dans ton AfficherDetailViewController
        }
    }
}
