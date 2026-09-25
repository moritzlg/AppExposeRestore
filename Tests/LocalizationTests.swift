import Foundation

guard CommandLine.arguments.count == 2 else {
    fatalError("Pass the Resources directory")
}

let resources = URL(fileURLWithPath: CommandLine.arguments[1])
let languages = ["en", "de"]
let files = ["Localizable.strings", "InfoPlist.strings"]

for file in files {
    var reference: [String: String]?
    for language in languages {
        let url = resources.appendingPathComponent("\(language).lproj").appendingPathComponent(file)
        let data = try Data(contentsOf: url)
        var format = PropertyListSerialization.PropertyListFormat.openStep
        guard let strings = try PropertyListSerialization.propertyList(
            from: data, options: [], format: &format
        ) as? [String: String] else {
            fatalError("Invalid strings file: \(url.path)")
        }
        if let reference {
            precondition(strings.keys == reference.keys, "Missing or extra keys in \(url.path)")
            for key in strings.keys {
                let placeholders = try! NSRegularExpression(pattern: "%(?:[0-9]+\\$)?[@d]")
                let tokens: (String) -> [String] = { value in
                    placeholders.matches(in: value, range: NSRange(value.startIndex..., in: value))
                        .compactMap { Range($0.range, in: value).map { String(value[$0]) } }
                }
                precondition(tokens(strings[key]!) == tokens(reference[key]!),
                             "Placeholder mismatch for \(key) in \(url.path)")
            }
        } else {
            reference = strings
        }
    }
}

print("Localization resources: English/German key and format parity passed")
