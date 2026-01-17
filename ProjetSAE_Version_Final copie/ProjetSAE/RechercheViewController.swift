//
//  RechViewController.swift
//  SAERechercheV2
//
//  Created by etudiant on 11/05/2025.
//

import UIKit
import FirebaseFirestore

class RechercheViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    // MARK: Prises & Variables
    @IBOutlet weak var RechTF: UITextField!
    @IBOutlet weak var TypeRechercheSC: UISegmentedControl!

    @IBOutlet weak var laTableView: UITableView!
    
    let db = Firestore.firestore()
    
    // Variables
    var toutesLesActions: [Action] = [] // Toutes les actions depuis Firestore
    var toutesLesAsso: [associations] = [] // Toutes les asso depuis Firestore
    var resultatRechercheAction: [Action] = [] // Actions filtrées après recherche
    var resultatRechercheAsso: [associations] = [] // Actions filtrées après recherche


    
    // MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        RechTF.delegate = self
        laTableView.delegate = self
        laTableView.dataSource = self
        chargerActionsDepuisFirestore()
        chargerAssoDepuisFirestore()
        //ajouterAssociationsDansFirebase()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

    }

    
    
    // Vérifier si on a changé de segmentedControl
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // Segment "Actions" sélectionné
            resultatRechercheAction = toutesLesActions
        } else {
            // Segment "Associations" sélectionné
            resultatRechercheAsso = toutesLesAsso
        }
        laTableView.reloadData()
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }


    
    // MARK: Récupérer les données de la base
    // Récupère les actions de la base Firestore
    func chargerActionsDepuisFirestore() {
        db.collection("Action").getDocuments { snapshot, error in
            if let error = error {
                print("Erreur Firestore : \(error.localizedDescription)")
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

            self.resultatRechercheAction = self.toutesLesActions
            self.laTableView.reloadData()
        }
    }

    
    // Récupère les asso de la base Firestore
    func chargerAssoDepuisFirestore() {
        db.collection("associations").getDocuments { snapshot, error in
            if let error = error {
                print("Erreur Firestore Association : \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            self.toutesLesAsso = documents.compactMap { doc in
                let data = doc.data()
                guard
                    let nom = data["nom"] as? String,
                    let description = data["description"] as? String,
                    let adresse = data["adresse"] as? String,
                    let mail = data["mail"] as? String,
                    let telephone = data["telephone"] as? String,
                    let representant = data["representant"] as? String,
                    let dateCreation = data["dateCreation"] as? Timestamp
                else { return nil }

                return associations(
                    id: doc.documentID,
                    nom: nom,
                    description: description,
                    dateCreation: dateCreation.dateValue(),
                    adresse: adresse,
                    mail: mail,
                    telephone: telephone,
                    representant: representant
                )
            }

            self.resultatRechercheAsso = self.toutesLesAsso
            self.laTableView.reloadData()
            
            if self.TypeRechercheSC.selectedSegmentIndex == 1 {
                DispatchQueue.main.async {
                    self.laTableView.reloadData()
                }
            }
        }
    }
    
    
    // MARK: Fonctions de recherche
    // Lancer la rechercher quand on clique sur le bouton
    @IBAction func CliqueBoutonRecherche(_ sender: UIButton) {
        lancerRecherche()
    }
    
    
    // Faire la recherche
    func lancerRecherche() {
        guard let motRecherche = RechTF.text?.lowercased(), !motRecherche.isEmpty else {
            resultatRechercheAction = toutesLesActions
            resultatRechercheAsso = toutesLesAsso
            laTableView.reloadData()
            return
        }

        if TypeRechercheSC.selectedSegmentIndex == 0 {
            // Rechercher les actions
            resultatRechercheAction = toutesLesActions.filter { action in
                return action.nom.lowercased().contains(motRecherche) ||
                action.description.lowercased().contains(motRecherche) ||
                action.dateDebut.lowercased().contains(motRecherche) ||
                action.dateFin.lowercased().contains(motRecherche)
            }
        }
        else if TypeRechercheSC.selectedSegmentIndex == 1{
            // Rechercher les associations
            resultatRechercheAsso = toutesLesAsso.filter { asso in
                return asso.nom.lowercased().contains(motRecherche) ||
                        asso.description.lowercased().contains(motRecherche) ||
                        asso.adresse.lowercased().contains(motRecherche) ||
                        asso.representant.lowercased().contains(motRecherche)
            }
        }

        laTableView.reloadData()
    }

    
    
    // MARK: - Table View Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if TypeRechercheSC.selectedSegmentIndex == 0 {
                return resultatRechercheAction.count
        } else {
                return resultatRechercheAsso.count
        }
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let uneCellule = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)

        if TypeRechercheSC.selectedSegmentIndex == 0 {
            let action = resultatRechercheAction[indexPath.row]
            uneCellule.textLabel?.text = action.nom
            uneCellule.detailTextLabel?.text = "\(action.description) - du \(action.dateDebut) au \(action.dateFin)"
        }
        else if TypeRechercheSC.selectedSegmentIndex == 1 {
            let asso = resultatRechercheAsso[indexPath.row]
            uneCellule.textLabel?.text = asso.nom
            uneCellule.detailTextLabel?.text = "\(asso.description) - Représentant : \(asso.representant)"
        }

        return uneCellule
    }

    
    // MARK: - Navigation

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // Pour passer à la page des informations
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "afficherDetailASegue" {
            guard let uneCellule = sender as? UITableViewCell,
                  let index = laTableView.indexPath(for: uneCellule)?.row,
                  let leControlDetail = segue.destination as? AfficherDetailViewController else {
                return
            }
            if TypeRechercheSC.selectedSegmentIndex == 0 {
                let action = resultatRechercheAction[index]
                leControlDetail.recupActionFirebase = action
            }
            else {
                let asso = resultatRechercheAsso[index]
                leControlDetail.recupAssoFirebase = asso
            }
            
        }
    }
}
