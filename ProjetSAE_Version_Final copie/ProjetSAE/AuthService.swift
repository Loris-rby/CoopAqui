//
//  AuthService.swift
//  ProjetSAE
//
//  Created by etudiant on 07/05/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore


enum CompteType {
    case perso
    case association
}

enum AuthError: Error {
    case invalidType
    case firebaseError(String)
}

struct AuthService {
    
    static func login(email: String, password: String, expectedType: CompteType, completion: @escaping (Result<[String: Any], AuthError>) -> Void) {
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(.firebaseError(error.localizedDescription)))
                return
            }

            guard let uid = authResult?.user.uid else {
                completion(.failure(.firebaseError("Identifiant utilisateur introuvable.")))
                return
            }

            // On choisit la collection selon le type attendu
            let collection: String
            switch expectedType {
            case .perso:
                collection = "Utilisateur"
            case .association:
                collection = "associations"
            }

            let db = FirebaseFirestore.Firestore.firestore()
            let docRef = db.collection(collection).document(uid)

            docRef.getDocument { document, error in
                if let error = error {
                    completion(.failure(.firebaseError("Erreur Firestore : \(error.localizedDescription)")))
                    return
                }

                guard let document = document, document.exists,
                      let data = document.data() else {
                    completion(.failure(.firebaseError("Document utilisateur introuvable.")))
                    return
                }

                // Si on veut, on peut encore valider un champ "type" ici
                completion(.success(data))
            }
        }
    }

}
