import UIKit
import MapKit
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Prise et variables
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var rechercheTF: UITextField!
    
    
    let db = Firestore.firestore()
    
    // MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        // Cacher le bouton par défaut
        addButton.isHidden = true
        
        // Définir la région affichée sur la carte
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.0, longitude: -0.5),
            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
        )
        mapView.setRegion(region, animated: true)
        
        fetchActionsFromFirestore()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkIfCurrentUserIsAssociation() // Vérifier si l'utilisateur est une association à chaque fois que la vue réapparaît
    }
    
    struct Action {
        let id: String
        let nom: String
        let description: String
        let latitude: Double
        let longitude: Double
        let dateDebut: String
        let dateFin: String
        let idAsso: String
    }
    
    // Vérifie si l'utilisateur actuel est une association
    func checkIfCurrentUserIsAssociation() {
        guard let uid = Auth.auth().currentUser?.uid else {
            
            DispatchQueue.main.async {
                self.addButton.isHidden = true
            }
            return
        }
        
        let userRef = db.collection("associations").document(uid)
        userRef.getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.addButton.isHidden = true
                    return
                }
                
                guard let doc = document else {
                    self?.addButton.isHidden = true
                    return
                }
                
                let isAsso = doc.exists
                print("👤 Utilisateur est une association ? \(isAsso)")
                self?.addButton.isHidden = !isAsso
            }
        }
    }
    
    
    @IBAction func addActionTapped(_ sender: Any) {
        print("📍 addActionTapped appelé")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nouvelleActionVC = storyboard.instantiateViewController(withIdentifier: "NouvelleActionViewController") as? NouvelleActionViewController {
            self.navigationController?.pushViewController(nouvelleActionVC, animated: true)
        } else {
        }
    }
    
    func fetchActionsFromFirestore() {
        db.collection("Action").getDocuments { [weak self] snapshot, error in
            if let error = error {
                return
            }
            
            snapshot?.documents.forEach { document in
                let data = document.data()
                guard
                    let nom = data["nom"] as? String,
                    let description = data["description"] as? String,
                    let latitude = data["latitude"] as? Double,
                    let longitude = data["longitude"] as? Double,
                    let dateDebut = data["date_debut"] as? String,
                    let dateFin = data["date_Fin"] as? String,
                    let idAssoRef = data["id_asso"] as? DocumentReference
                else {
                    return
                }
                
                let action = Action(
                    id: document.documentID,
                    nom: nom,
                    description: description,
                    latitude: latitude,
                    longitude: longitude,
                    dateDebut: dateDebut,
                    dateFin: dateFin,
                    idAsso: idAssoRef.path
                )
                
                let annotation = ActionAnnotation(action: action)
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                annotation.title = nom
                annotation.subtitle = description
                
                DispatchQueue.main.async {
                    self?.mapView.addAnnotation(annotation)
                }
            }
            
            print("✅ Actions récupérées et affichées")
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is ActionAnnotation else { return nil }
        
        let identifier = "CustomActionAnnotationView"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            if let pinImage = UIImage(named: "MapPin") {
                let size = CGSize(width: 30, height: 30)
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                pinImage.draw(in: CGRect(origin: .zero, size: size))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                annotationView?.image = resizedImage
            }
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let actionAnnotation = view.annotation as? ActionAnnotation else { return }
        
        let action = actionAnnotation.action
        
        let alert = UIAlertController(
            title: action.nom,
            message: """
            \(action.description)
            
            Du \(action.dateDebut) au \(action.dateFin)
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    // Classe personnalisée pour les annotations
    class ActionAnnotation: MKPointAnnotation {
        var action: MapViewController.Action
        
        init(action: MapViewController.Action) {
            self.action = action
            super.init()
        }
    }
    
    
    @IBAction func tapSurRechercher(_ sender: Any) {
        // Quand on entre une ville dans le rechercheTF, cela va zoomer sur la ville en question
        guard let ville = rechercheTF.text?.trimmingCharacters(in: .whitespacesAndNewlines), !ville.isEmpty else {
            // 🗺 Revenir à la position initiale (France, Nouvelle-Aquitaine)
            let defaultRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 45.0, longitude: -0.5),
                span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
            )
            mapView.setRegion(defaultRegion, animated: true)
            print("🔄 Champ vide : retour à la vue initiale.")
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(ville) { [weak self] placemarks, error in
            if let error = error {
                print("❌ Erreur de géocodage : \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                print("❌ Ville introuvable.")
                return
            }
            
            let coordinate = location.coordinate
            print("📍 Coordonnées de \(ville) : \(coordinate.latitude), \(coordinate.longitude)")
            
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
            )
            
            DispatchQueue.main.async {
                self?.mapView.setRegion(region, animated: true)
            }
        }
        
    }
}
