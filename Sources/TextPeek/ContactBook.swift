import Contacts

@MainActor
final class ContactBook {
    private let store = CNContactStore()
    private var names: [String: String]?

    func load() async {
        guard (try? await store.requestAccess(for: .contacts)) == true else { return }
        reload()
        NotificationCenter.default.addObserver(forName: .CNContactStoreDidChange, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { self.reload() }
        }
    }

    func name(for handle: String) -> String? {
        guard Self.isPersonal(handle) else { return nil }
        guard let names else { return handle }
        return names[Self.key(handle)]
    }

    private func reload() {
        let keys = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
        ]
        var names: [String: String] = [:]
        try? store.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys)) { contact, _ in
            let handles = contact.phoneNumbers.map(\.value.stringValue) + contact.emailAddresses.map { $0.value as String }
            for handle in handles {
                let name = CNContactFormatter.string(from: contact, style: .fullName) ?? contact.organizationName
                names[Self.key(handle)] = name.isEmpty ? handle : name
            }
        }
        names.removeValue(forKey: "")
        self.names = names
    }

    nonisolated static func isPersonal(_ handle: String) -> Bool {
        handle.contains("@") || handle.filter(\.isWholeNumber).count >= 7
    }

    nonisolated static func key(_ handle: String) -> String {
        handle.contains("@") ? handle.lowercased() : String(handle.filter(\.isWholeNumber).suffix(10))
    }
}
