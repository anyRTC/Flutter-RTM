# ARRtm Example

Demonstrates how to use the `ar_rtm` plugin.

## Getting Started

### Create an Account and Obtain an App ID

1. Create a developer account at [anyrtc.io](https://www.anyrtc.io/).
2. In the Anyrtc.io Dashboard that appears, click **Projects** > **Project List** in the left navigation.
3. Copy the **App ID** from the Dashboard to a text file. You will use this ID later when you launch the app.

### Update and Run the Sample Application

Open the `main.dart` file. In the `_createClient()` method, update `YOUR APP ID` with your App ID.

```Dart
_client = await AgoraRtmClient.createInstance('YOUR APP ID');
```

### Run example

Connect device and run.
