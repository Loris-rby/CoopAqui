
import Foundation

let lesActions : [Action] = []


struct Action: Codable, Equatable {
    var id: String
    var nom: String
    var description: String
    var latitude: Double
    var longitude: Double
    var dateDebut: String
    var dateFin: String
    var idAsso: String
}


struct associations: Codable, Equatable {
    var id: String
    var nom: String
    var description: String
    var dateCreation: Date
    var adresse: String
    var mail: String
    var telephone: String
    var representant: String
}


struct UserLikes: Codable {
    var userId: String
    var likes: [Action]
}
