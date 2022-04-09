import Foundation
import LocalAuthentication

let service = "GnuPG"

let emailRegex = try! NSRegularExpression(pattern: "\"(?<name>.*<(?<email>.*)>)\"")
let keyIDRegex = try! NSRegularExpression(pattern: "ID (?<keyId>.*),")
let sshIDRegex = try! NSRegularExpression(pattern: "SHA256:(?<keyId>.*)")

func findMatches(input: String, regex: NSRegularExpression) -> [String] {
    let range = NSRange(input.startIndex..<input.endIndex, in: input)
    let matches = regex.matches(in: input, options: [], range: range)
    var names: [String] = []
    guard let match = matches.first else { return names }
    for rangeIndex in 0..<match.numberOfRanges {
        let matchRange = match.range(at: rangeIndex)
        if matchRange == range { continue }
        if let substringRange = Range(matchRange, in: input) {
            let capture = String(input[substringRange])
            names.append(capture)
        }
    }
    return names
}

func main() {
    var key: String? = nil
    var reason = "log in to your account"
    
    let ctx = LAContext()
    guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
        print("ERR Your Mac doesn't support deviceOwnerAuthenticationWithBiometrics")
        exit(EXIT_FAILURE)
    }
    
    print("OK Pleased to meet you")
    while let input = readLine() {
        switch input {
        case _ where input.hasPrefix("SETKEYINFO"):
            // KeyInfo is always in the form of x/cacheId
            // https://gist.github.com/mdeguzis/05d1f284f931223624834788da045c65#file-info-pinentry-L357-L362
            key = input.components(separatedBy: "/")[1]
            print("OK")
        case _ where input.hasPrefix("SETDESC"):
            let description = String(input.dropFirst("SETDESC ".count)).removingPercentEncoding!
            
            var matches = findMatches(input: description, regex: emailRegex)
            if matches.count > 2 {
                let name = matches[1].components(separatedBy: " <")[0]
                let email = matches[2]
                reason = "access the PIN for \(name) <\(email)>"
                
                matches = findMatches(input: description, regex: keyIDRegex)
                if matches.count > 1 {
                    var keyID = matches[1]
                    // Drop the optional 0x prefix from keyID (--keyid-format)
                    // https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html
                    if keyID.hasPrefix("0x") {
                        keyID = String(keyID.dropFirst("0x".count))
                    }
                    reason += " (ID \(keyID))"
                }
            } else {
                matches = findMatches(input: description, regex: sshIDRegex)
                if matches.count > 1 {
                    reason = "access the PIN for ssh key \(matches[1])"
                }
            }
            print("OK")
        case _ where input.hasPrefix("GETPIN"):
            guard key != nil else { exit(EXIT_FAILURE) }
            
            ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success {
                    do {
                        let password = try readPassword(service: service, account: key!)
                        print("D \(String(data: password, encoding: .utf32)!)")
                        print("OK")
                    } catch {
                        print("ERR Failed to read passphrase from MacOS Keychain")
                        exit(EXIT_FAILURE)
                    }
                } else {
                    print("ERR \(error?.localizedDescription ?? "Failed to authenticate")")
                    exit(EXIT_FAILURE)
                }
            }
        case _ where input.hasPrefix("BYE"):
            print("OK closing connection")
            exit(EXIT_FAILURE)
        default:
            print("OK")
        }
    }
    
    dispatchMain()
}

setbuf(__stdoutp, nil)
main()
