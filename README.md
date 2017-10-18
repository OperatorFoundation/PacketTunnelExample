# PacketTunnelExample

## This project is currently under construction, take nothing at face value <3 

## Git filter to avoid accidental checkin of private Xcode identifiers

Execute this on your project root to source the `.gitconfig` file which
filters `PRODUCT_BUNDLE_IDENTIFIER`, `DEVELOPMENT_TEAM`, `PROVISIONING_PROFILE`,
`CODE_SIGN_STYLE` and `ORGANIZATIONNAME` keys from your Xcode project
configuration in order to avoid accidental checkin of these:

```bash
$ git config --local include.path ../.gitconfig
```

## Setup app identifiers

- You need to pick 3 *unique* identifiers. (as in: unique in the whole App Store!)
    Follow the pattern as per the examples:

    1. A bundle ID (`com.example.PacketTunnelExample`)
    2. An extension bundle ID (`com.example.PacketTunnelExample.extension`)
    3. A group ID (`group.com.example.PacketTunnelExample`)

- Set these identifiers on the according targets of the project configuration:

    1. The bundle ID at the `General` tab of the `PacketTunnelExample` target.
    2. The extension bundle ID at the `General` tab of the `PacketTunnelExtension`
       target.
    3. The group ID at the `App Groups` section in the `Capabilities` tab of
       both mentioned targets. (Enable `App Groups` if it's not.)
    4. Delete the example group ID, if there.
    5. Also in the `Capabilities` tab of both targets turn on the `Network Extensions`
       capability and check the `Packet Tunnel` option, if not enabled.
    6. Fix the group ID in both files `PacketTunnelExample.entitlements` and
       `PacketTunnelExtension.entitlements`. 

## Signing

You can try to enable automatic signing, but the results are mixed. It seems,
that some people can make it work, some others not, depending on their Apple
Developer account and it's history. (Seems to be a bug on the server side with
some accounts.)

A free account is definitely not enough for the Network Extension to work. You
will need a paid Apple Developer account!

### Manual Signing

- Go to Apple's 
    [developer portal](https://developer.apple.com/account/ios/identifier/bundle):

    1. Generate an `App ID` using your bundle identifier.
    2. Generate an `App ID` using your extension bundle identifier.
    3. Create an `App Group`.
    4. 5. Create two new development `Provisioning Profiles`, one for each `App ID`.

- Load the provisioning profiles into Xcode using Xcode -> Preferences -> Accounts ->
  [Your Apple-ID] -> Download All Profiles or in the `General` tab of both targets use
  `Provisioning Profile` -> `Download Profile...`
    
## Running Test Server

You will need to run the test server on your development machine in order to test the packet tunnel client.

The packet tunnel server is built into the PacketTunnelExample project. Here's how you run it:

- Build the project (if you run into build issues, check out signing instructions above and make sure all your bundle ID's and signing teams are set up correctly

- Select PacketTunnelServer build scheme, right click and select "Edit Scheme". Select "Arguments" tab and add the following arguments:

	- port number (e.g. 8080)
	- config file path. Config file (config.plist) is included in the project. You can just specify an absolute path to the file. Easiest way to do that is to right click on config.plist, select "Show in Finder". Then drag the file from the Finder into the text box so that it's path is automagically copied

- Provided you did the above steps correctly, you should be able to run the server. If you see "Starting network service on port X" and "Network service published successfully" in the console, server is ready to accept client connections.

## Connecting to Test Server

- You will need to enter your dev machine's local IP address and the port number you selected in the previous step into "Server Address" field. That's all you should need to do to connect.

## Troubleshooting Server Connectivity

Most importantly, both your development machine and your test iOS device should be on the same local (WiFi) network. 

## Automatic-esque Signing
