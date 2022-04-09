# Pinentry-TouchID

Custom GPG pinentry program for macOS that allows using Touch ID for retrieving the key passphrase from the macOS keychain. (MacBook Pro with TouchID only)

## Installation

### Prerequisites

* [gnupg](https://formulae.brew.sh/formula/gnupg)
* [pinentry-mac](https://formulae.brew.sh/formula/pinentry-mac)

Install both using [Homebrew](https://brew.sh):

```sh
$ brew install gnupg pinentry-mac
```

### Pre-build Binaries

Download pre-build `pinentry-touchid` binaries from the [GitHub Releases page](https://github.com/felix-kaestner/pinentry-touchid/releases).

```sh
$ VERSION=$(curl -fsSL https://api.github.com/repos/felix-kaestner/pinentry-touchid/releases/latest | jq -r .tag_name)
$ curl -fsSL -o pinentry-touchid "https://github.com/felix-kaestner/pinentry-touchid/releases/download/${VERSION}/pinentry-touchid-${VERSION}-$(uname -s)-$(uname -m)"
$ mv pinentry-touchid /usr/local/bin/pinentry-touchid
```

### Manual

Clone the repository:

```sh
$ git clone https://github.com/felix-kaestner/pinentry-touchid.git
```

Build the binary using:

```sh
$ ./build.sh
```

## Quickstart

List the keygrip of the GPG Key for which you want to store the passphrase:

```sh
$ gpg --list-keys --with-keygrip

/Users/user/.gnupg/pubring.kbx
----------------------------------------
pub   rsa4096 2022-04-01 [SC]
      < ... >
      Keygrip = 78066B99A804208F8DDB3C8F388C56C1C74EA812
uid           [ultimate] Felix Kästner <mail@felix-kaestner.com>
```

Create a new entry in the MacOS Keychain for storing your passphrase:

Go to `Keychain Access` > Select the `login` keychain under _Default Keychains_ > Click on _Create new Keychain item._ in the upper right (via the pencil icon).
Fill in the prompt with the following information:

* Keychain Item Name: `"GnuPG"`
* Account Name: GPG Keygrip
* Password: Your Passphrase

Finally, click on `Add`.

<img width="641" src="https://user-images.githubusercontent.com/23213965/162564229-2f6149f6-49c5-472a-a1c9-e4a9c0494205.png">

Configure the `gpg-agent` to use `pinentry-touchid` as its pinentry program. Add or replace the following line to your gpg agent configuration in: `~/.gnupg/gpg-agent.conf`:
```sh
$ pinentry-program /usr/local/bin/pinentry-touchid
```

`Pinentry-TouchID` is now fully configured!
