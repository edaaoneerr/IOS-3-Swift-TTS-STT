
# Speech-to-Text Voice Calling App using Agora and iOS Speech

This project is a functional program that enables users to send messages while on a call using the Agora Voice Calling SDK and Agora Chat. The app uses the iOS Speech dependency to convert spoken messages to text, which are then sent to the recipient via Agora Chat. The app also includes a text-to-speech feature to allow the recipient to hear the message read aloud.

## Getting Started

Before running the app, you will need to have an Agora developer account and create a new project in the Agora console. You will also need to obtain an App ID and optionally a Token, which is required for using the Agora Voice Calling SDK and Agora Chat. Once you have your App ID, add it to the file in the project.

To use the speech-to-text and text-to-speech features, you will need to give the app permission to use the device's microphone and speaker. This can be done by going to the device's Settings app and granting permissions for the app to access the microphone and speaker.

## Dependencies

This project uses the following dependencies:

<ul>Agora Voice Calling SDK </ul>
<ul>Agora Chat </ul>
<ul>iOS Speech framework </ul>

## Usage

To use the app, simply open it on your iOS device and log in using your Agora credentials. Once logged in, you can initiate a call with another user who is also logged in to the app.

During the call, you can speak your message and it will be automatically converted to text and sent to the recipient via Agora Chat. If the recipient has the text-to-speech feature enabled, they will hear the message read aloud.

To use the text-to-speech feature, simply tap on the read button for the message you want to hear and it will be read aloud using the device's speaker.

## Limitations

This app currently only supports speech-to-text and text-to-speech in English. Other languages may be supported in future updates.
## Contributing

If you would like to contribute to this project, please submit a pull request or open an issue on GitHub.


## License

This project is licensed under the Apache 2.0 License. See the LICENSE file for more information.

