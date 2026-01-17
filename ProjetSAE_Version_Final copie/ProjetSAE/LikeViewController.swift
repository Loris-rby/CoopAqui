import UIKit
import FirebaseAuth
import FirebaseFirestore

class LikeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var LogoImageView: UIImageView!
    @IBOutlet weak var TitreLabel: UILabel!

    var likedItems: [Action] = []
    let tableView = UITableView()
    var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground
        TitreLabel.text = "Mes Likes"
        setupTableView()

        // Surveille la connexion utilisateur
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.listener?.remove() // Nettoie ancien écouteur
            if user != nil {
                self?.écouterLikesEnTempsRéel()
            } else {
                self?.likedItems = []
                self?.tableView.reloadData()
            }
        }
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: TitreLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func écouterLikesEnTempsRéel() {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userId = currentUser.uid

        listener = db.collection("likes").whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Erreur lors de l'écoute des likes : \(error.localizedDescription)")
                    self.likedItems = []
                } else if let document = snapshot?.documents.first {
                    let data = document.data()
                    if let likesArray = data["likes"] as? [[String: Any]] {
                        self.likedItems = likesArray.compactMap { dict in
                            guard
                                let id = dict["id"] as? String,
                                let nom = dict["nom"] as? String,
                                let description = dict["description"] as? String,
                                let latitude = dict["latitude"] as? Double,
                                let longitude = dict["longitude"] as? Double,
                                let dateDebut = dict["dateDebut"] as? String,
                                let dateFin = dict["dateFin"] as? String,
                                let idAsso = dict["idAsso"] as? String
                            else {
                                return nil
                            }
                            return Action(id: id, nom: nom, description: description,
                                            latitude: latitude, longitude: longitude,
                                            dateDebut: dateDebut, dateFin: dateFin,
                                            idAsso: idAsso)
                        }
                    } else {
                        self.likedItems = []
                    }
                } else {
                    self.likedItems = []
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    deinit {
        listener?.remove()
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let item = likedItems[indexPath.row]
        cell.textLabel?.text = item.nom
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        cell.textLabel?.textColor = .darkText
        cell.imageView?.image = UIImage(systemName: "heart.fill")
        cell.imageView?.tintColor = .systemRed
        cell.backgroundColor = .white
        cell.layer.cornerRadius = 12
        cell.layer.masksToBounds = true
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layer.shadowColor = UIColor.black.cgColor
        cell.contentView.layer.shadowOpacity = 0.05
        cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 4)
        cell.contentView.layer.shadowRadius = 4
        cell.contentView.layer.masksToBounds = false
    }

    // MARK: - Suppression de likes
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let currentUser = Auth.auth().currentUser else { return }
            let userId = currentUser.uid
            let db = Firestore.firestore()

            let actionASupprimer = likedItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)

            db.collection("likes").whereField("userId", isEqualTo: userId).getDocuments { snapshot, error in
                if let document = snapshot?.documents.first {
                    var currentLikes = document.data()["likes"] as? [[String: Any]] ?? []

                    currentLikes.removeAll { dict in
                        (dict["id"] as? String) == actionASupprimer.id
                    }

                    db.collection("likes").document(document.documentID).updateData(["likes": currentLikes]) { err in
                        if let err = err {
                            print("❌ Erreur lors de la mise à jour : \(err.localizedDescription)")
                        } else {
                            print("✅ Like supprimé avec succès.")
                        }
                    }
                }
            }
        }
    }
}
