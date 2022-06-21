import Foundation
import LocalAuthentication

let service = "GnuPG"

let emailRegex = try! NSRegularExpression(pattern: "\"(?<name>.*<(?<email>.*)>)\"")
let keyIDRegex = try! NSRegularExpression(pattern: "ID (?<keyId>.*),")
let sshIDRegex = try! NSRegularExpression(pattern: "SHA256:(?<keyId>.*)")

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
            guard let description = input.dropPrefix("SETDESC ").removingPercentEncoding else { continue }
            
            var matches = description.matches(emailRegex)
            if matches.count > 2 {
                let name = matches[1].components(separatedBy: " <")[0]
                let email = matches[2]
                reason = "access the PIN for \(name) <\(email)>"
                
                matches = description.matches(keyIDRegex)
                if matches.count > 1 {
                    // Drop the optional 0x prefix from keyID (--keyid-format)
                    // https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html
                    let keyID = matches[1].dropPrefix("0x")
                    reason += " (ID \(keyID))"
                }
            } else {
                matches = description.matches(sshIDRegex)
                if matches.count > 1 {
                    reason = "access the PIN for ssh key \(matches[1])"
                }
            }
            print("OK")
        case _ where input.hasPrefix("GETPIN"):
            guard let account = key else { exit(EXIT_FAILURE) }
            
            ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success {
                    do {
                        let password = try readPassword(service: service, account: account)
                        guard let password = String(data: password, encoding: .utf8) else { exit(EXIT_FAILURE) }
                        print("D \(password)")
                        print("OK")
                    } catch {
                        print("ERR Failed to read passphrase from MacOS Keychain (\(error))")
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
