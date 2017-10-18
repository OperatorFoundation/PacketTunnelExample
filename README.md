# PacketTunnelExample

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