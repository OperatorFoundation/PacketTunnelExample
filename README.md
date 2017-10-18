# PacketTunnelExample

## This project is currently under construction, take nothing at face value <3 

## Git filter to avoid accidental checkin of private Xcode identifiers

Execute this on your project root to source the `.gitconfig` file which
filters PRODUCT_BUNDLE_IDENTIFIER, DEVELOPMENT_TEAM, PROVISIONING_PROFILE
and CODE_SIGN_STYLE keys from your Xcode project configuration in order to
avoid accidental checkin of these:

```bash
$ git config --local include.path ../.gitconfig
```

## Manual Signing

You will need:
 - A unique bundle identifier for the app (i.e. `com.example.packettunnel`)
 - A unique bundle identifier for the network extension (i.e. `com.example.packettunnel.extension`)
 - A group ID (i.e. `group.com.example.packettunnel`)

- This requires some manual set up in Apple's 
    [developer portal](https://developer.apple.com/account/ios/identifier/bundle):

    1. Generate an `App ID` using your bundle identifier.
    2. Generate an `App ID` using your extension bundle identifier.
    3. Create an `App Group`.
    4. 5. Create two new development `Provisioning Profiles`, one for each `App ID`.

- Load the provisioning profiles into Xcode using Xcode -> Preferences -> Accounts ->
[Your Apple-ID] -> Download All Profiles
    
- In Xcode:
    1. In the capabilities tab of the PacketTunnelExample target enable your new `App Group`.
    2. Also in the capabilities tabs of this target turn on the Network Extension capability and check the packet tunnel option.
    3. Repeat the last two steps for the PacketTunnelExtension.
    2. Check the `Network Extensions` checkbox on both of the `App ID`s.

## Automatic-esque Signing
