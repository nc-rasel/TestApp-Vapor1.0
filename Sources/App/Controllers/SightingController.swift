import Vapor
import HTTP

final class SightingConroller: ResourceRepresentable {
    let drop: Droplet
    
    init(droplet: Droplet) {
        self.drop = droplet
    }
    
    func index(request: Request) throws -> ResponseRepresentable {
        return try Sighting.all().makeNode().converted(to: JSON.self)
    }
    
    func store(request: Request) throws -> ResponseRepresentable {
        guard let bird = request.data["bird"]?.string else {
            throw Abort.badRequest
        }
        
        let response = try drop.client.get("http://ebird.org/ws1.1/ref/taxon/find", query: [
            "q" : bird ])
        
        let birds = response.data["name"]?
            .array?
            .flatMap({ $0.string })
        
        if birds == nil || birds?.count == 0 {
            throw Abort.custom(
                status: .badRequest,
                message: "Bird \(bird) was not found")
        }
        
        var sighting = Sighting(bird: bird)
        try sighting.save()
        
        return sighting
    }
    
    func show(request: Request, item sighting: Sighting) throws -> ResponseRepresentable {
        return sighting
    }
    
    func count(request: Request, item sighting: Sighting) throws -> ResponseRepresentable {
        let sightings = try Sighting.query().filter("bird", sighting.bird).all()
        
        return JSON([
            "count": Node(sightings.count)
            ])
    }
    
    func makeResource() -> Resource<Sighting> {
        return Resource(
            index: index,
            store: store,
            show: show
        )
    }
}