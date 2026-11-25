import SwiftUI

/// Routes workspace content by place-registry presentation id (S4-05+).
/// Reads `navigation.currentLocation`; list and detail mount as separate views.
struct WorkspaceDestinationHost: View {
    @Environment(WorkspaceNavigation.self) private var navigation
    @Environment(WorkspaceSession.self) private var session
    let userID: String
    let sessionDisplayName: String
    let store: any GenealogyStore

    var body: some View {
        let place = Self.place(for: navigation.currentLocation, projectDir: session.projectKey.projectDir)
        Group {
            destination(for: place?.presentation ?? .sourcesList)
        }
        .id(place?.viewIdentity)
        .environment(\.pvScrollMemory, scrollMemory)
        // Fill the detail area, then measure it once: every destination reads \.pvWidthClass from here.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pvMeasuresWidthClass()
        // A graph, composer or Promote entry made before its graph moved to another Source names the
        // old one: rewrite it in place to the graph's Source once the graph list says where it is.
        .onChange(of: pendingCorrection(for: place), initial: true) { _, correction in
            if let correction { navigation.replaceCurrent(with: correction) }
        }
    }

    /// What every scroll view on the page is asked to remember (D-5): this visit's id, the y each was
    /// left at, and where to report a new one.
    private var scrollMemory: PVScrollMemory {
        let arrival = navigation.arrival.id
        return PVScrollMemory(
            arrival: arrival,
            offsets: navigation.currentLocation.revisit.scrollOffsets
        ) { [weak navigation] slot, y in
            navigation?.noteScrollOffset(y, slot: slot, arrival: arrival)
        }
    }

    /// The rewrite the current location needs, nil when its place does not follow its graph's
    /// Source, the graph list has no row for it yet, or the location already names that Source.
    private func pendingCorrection(for place: ResolvedPlace?) -> WorkspaceLocation? {
        let location = navigation.currentLocation
        guard let graphId = location.graphId else { return nil }
        return place?.pendingGraphSourceCorrection(for: location, graph: session.evidenceGraph(id: graphId))
    }

    @ViewBuilder
    private func destination(for presentation: WorkspacePresentationID) -> some View {
        switch presentation {
        case .sourcesList:
            SourcesListView(
                session: session,
                userID: userID,
                projectUuid: navigation.projectUuid,
                store: store
            )
        case .sourcePage:
            if let sourceID = navigation.currentLocation.sourceId {
                SourcePageView(
                    sourceID: sourceID,
                    session: session,
                    userID: userID,
                    sessionDisplayName: sessionDisplayName,
                    store: store
                )
            }
        case .sourceGraph:
            if let sourceID = navigation.currentLocation.sourceId,
               let graphID = navigation.currentLocation.graphId
            {
                EvidenceGraphView(
                    graphID: graphID,
                    sourceID: sourceID,
                    session: session,
                    store: store,
                    userID: userID,
                    openingSubjectID: navigation.currentLocation.subjectId
                )
            }
        case .sourceCitationComposer:
            if let entry = CitationComposerEntry(location: navigation.currentLocation) {
                CitationComposerView(
                    entry: entry,
                    session: session,
                    store: store,
                    userID: userID
                )
            }
        case .sourcePromote:
            if let entry = PromoteEntry(location: navigation.currentLocation) {
                PromoteView(
                    entry: entry,
                    session: session,
                    store: store,
                    userID: userID
                )
            }
        case .metadata:
            MetadataView(
                session: session,
                userID: userID,
                store: store
            )
        case .sourceTypes:
            SourceTypesView(
                session: session,
                userID: userID,
                store: store
            )
        case .sourceTypePage:
            if let typeID = navigation.currentLocation.typeId {
                SourceTypePageView(
                    typeID: typeID,
                    session: session,
                    userID: userID,
                    store: store
                )
            }
        case .properties:
            PropertiesView(
                session: session,
                userID: userID,
                store: store
            )
            .accessibilityIdentifier("workspace.destination.properties")
        case .personsList:
            PersonsListView(session: session)
                .accessibilityIdentifier("workspace.destination.persons")
        case .personDetail:
            PersonDetailView(session: session, entityId: navigation.currentLocation.entityId ?? "", userID: userID)
                .accessibilityIdentifier("workspace.destination.personDetail")
        case .eventsList:
            EventsListView(session: session)
                .accessibilityIdentifier("workspace.destination.events")
        case .eventDetail:
            EventDetailView(session: session, entityId: navigation.currentLocation.entityId ?? "", userID: userID)
                .accessibilityIdentifier("workspace.destination.eventDetail")
        case .placesList:
            PlacesListView(session: session)
                .accessibilityIdentifier("workspace.destination.places")
        case .placeDetail:
            PlaceDetailView(session: session, entityId: navigation.currentLocation.entityId ?? "", userID: userID)
                .accessibilityIdentifier("workspace.destination.placeDetail")
        }
    }

    /// The place `location` resolves to; `body` mounts its presentation and resets on its `viewIdentity`.
    static func place(
        for location: WorkspaceLocation,
        projectDir: String,
        registry: PlaceRegistry = .standard
    ) -> ResolvedPlace? {
        registry.resolve(location, project: ProjectKey(projectDir: projectDir))
    }

    /// Mirrors the host `switch` for unit tests (which view family mounts).
    static func destinationKind(for presentation: WorkspacePresentationID) -> WorkspaceDestinationKind {
        switch presentation {
        case .sourcesList, .sourcePage, .sourceGraph, .sourceCitationComposer, .sourcePromote:
            return .sources
        case .metadata:
            return .metadata
        case .sourceTypes, .sourceTypePage:
            return .sourceTypes
        case .properties:
            return .properties
        case .personsList, .personDetail:
            return .persons
        case .eventsList, .eventDetail:
            return .events
        case .placesList, .placeDetail:
            return .places
        }
    }
}

/// Top-level destination view mounted by `WorkspaceDestinationHost`.
enum WorkspaceDestinationKind: Equatable {
    case sources
    case metadata
    case sourceTypes
    case properties
    case persons
    case events
    case places
}
