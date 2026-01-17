import UIKit
import FirebaseFirestore
import FirebaseAuth

class NouvelleActionViewController: UIViewController {
    
    // Champs du formulaire
    let nomTextField = UITextField()
    let descriptionTextField = UITextField()
    let latitudeTextField = UITextField()
    let longitudeTextField = UITextField()
    let dateDebutPicker = UIDatePicker()
    let dateFinPicker = UIDatePicker()
    let ajouterButton = UIButton(type: .system)
    
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Nouvelle Action"
        view.backgroundColor = .systemBackground
        
        setupForm()
    }

    func setupForm() {
        // Configuration des champs
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        func configureTextField(_ tf: UITextField, placeholder: String) {
            tf.placeholder = placeholder
            tf.borderStyle = .roundedRect
        }

        configureTextField(nomTextField, placeholder: "Nom")
        configureTextField(descriptionTextField, placeholder: "Description")
        configureTextField(latitudeTextField, placeholder: "Latitude (ex: 45.75)")
        configureTextField(longitudeTextField, placeholder: "Longitude (ex: -1.25)")
        
        dateDebutPicker.datePickerMode = .date
        dateFinPicker.datePickerMode = .date
        
        ajouterButton.setTitle("Ajouter", for: .normal)
        ajouterButton.addTarget(self, action: #selector(ajouterAction), for: .touchUpInside)

        // Ajout des éléments au stack
        [nomTextField, descriptionTextField, latitudeTextField, longitudeTextField, dateDebutPicker, dateFinPicker, ajouterButton].forEach {
            stackView.addArrangedSubview($0)
        }

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }

    @objc func ajouterAction() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard
            let nom = nomTextField.text, !nom.isEmpty,
            let description = descriptionTextField.text, !description.isEmpty,
            let latStr = latitudeTextField.text, let latitude = Double(latStr),
            let lonStr = longitudeTextField.text, let longitude = Double(lonStr)
        else {
            showAlert(message: "Tous les champs doivent être remplis correctement.")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let actionData: [String: Any] = [
            "nom": nom,
            "description": description,
            "latitude": latitude,
            "longitude": longitude,
            "date_debut": formatter.string(from: dateDebutPicker.date),
            "date_Fin": formatter.string(from: dateFinPicker.date),
            "id_asso": db.collection("Association").document(uid)
        ]

        db.collection("Action").addDocument(data: actionData) { error in
            if let error = error {
                self.showAlert(message: "Erreur : \(error.localizedDescription)")
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
