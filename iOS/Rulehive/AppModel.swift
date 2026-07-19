import Foundation
import SwiftData
import SwiftUI

/// App state: owns the SwiftData store (indexed games) and the free-tier gate.
@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    /// Free tier: up to this many games may be indexed at once.
    static let freeGameLimit = 3

    private let defaults = UserDefaults.standard

    init(container: ModelContainer) {
        self.container = container
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([Game.self])
        let local = ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: local) { return c }
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: mem)
    }

    /// Pure gate check — no SwiftData/StoreKit dependency, so it is trivially
    /// unit-testable: Pro accounts always may add another game; free accounts
    /// are capped at `freeGameLimit`.
    nonisolated static func canAddGame(existingCount: Int, isPro: Bool) -> Bool {
        isPro || existingCount < freeGameLimit
    }

    // MARK: Games

    func games() -> [Game] {
        var descriptor = FetchDescriptor<Game>()
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        return (try? container.mainContext.fetch(descriptor)) ?? []
    }

    var canAddAnotherGame: Bool {
        Self.canAddGame(existingCount: games().count, isPro: store?.isPro ?? false)
    }

    @discardableResult
    func addGame(title: String) -> Game {
        let game = Game(title: title)
        container.mainContext.insert(game)
        try? container.mainContext.save()
        objectWillChange.send()
        return game
    }

    func appendPage(_ page: PageRecord, to game: Game) {
        game.appendPage(page)
        try? container.mainContext.save()
        objectWillChange.send()
    }

    func removePage(id: UUID, from game: Game) {
        game.removePage(id: id)
        try? container.mainContext.save()
        objectWillChange.send()
    }

    func deleteGame(_ game: Game) {
        container.mainContext.delete(game)
        try? container.mainContext.save()
        objectWillChange.send()
    }

    func deleteAllData() {
        try? container.mainContext.delete(model: Game.self)
        try? container.mainContext.save()
    }
}
