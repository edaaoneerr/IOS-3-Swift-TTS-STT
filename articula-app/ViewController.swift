//
//  ViewController.swift
//  articula-app
//
//  Created by Edanur Oner on 11.04.2023.
//

import UIKit
import AgoraChat
import AVFoundation
import AgoraRtcKit
import Speech


class ViewController: UIViewController {
    
    @IBOutlet weak var userIdField: UITextField!
    @IBOutlet weak var tokenField: UITextField!
    @IBOutlet weak var remoteUserIdField: UITextField!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var logView: UITextView!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var muteSwitch: UISwitch!
    
    // Volume Control
    var volume: Int = 50
    var isMuted: Bool = false
    var remoteUid: UInt = 0 // Stores the uid of the remote user
    
           var joined: Bool = false {
           didSet {
               DispatchQueue.main.async {
                   self.joinButton.setTitle( self.joined ? "Leave" : "Join", for: .normal)
               }
           }
       }
    
 
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var agoraEngine: AgoraRtcEngineKit!
    var userRole: AgoraClientRole = .broadcaster
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    
    let appID = "05604e2996a34fea932317738508b2e7"
    var token = "007eJxTYDh4kcl71lLmHtnVzLMYj17ST4g8O23Gkfxpq5M0OeSqX"
    var channelName = "Welcome"
    var msgToSend: String?
    let speechSynthesizer = AVSpeechSynthesizer()
    
    
   
    
    //MARK: - Handlers
        @objc func dismissKeyboard() {
            //Causes the view (or one of its embedded text fields) to resign the first responder status.
            view.endEditing(true)
        }
    
    
    
    @IBAction func joinClicked(_ sender: Any) {
        
        
        
        if userIdField.text != "" || remoteUserIdField.text != "" {
            self.loginAction {
                if !self.joined {
                   /* sender.isEnabled = false */
                    DispatchQueue.global(qos: .userInitiated).async {
                        print("starting STT")
                        if self.audioEngine.isRunning {
                            self.audioEngine.stop()
                            self.recognitionRequest?.endAudio()
                            print("Start Recording")
        //                    self.btnStart.isEnabled = false
        //                    self.btnStart.setTitle("Start Recording", for: .normal)
                        } else {
                            try? self.startRecording()
                            print("Stop Recording")
        //                    self.btnStart.setTitle("Stop Recording", for: .normal)
                        }
                        Task {

                            await self.joinChannel()
                          //  sender.isEnabled = true
                        }
                    }
                    
                    
                    
                } else {
                    self.logoutAction()
                    self.leaveChannel()
                }

            }
        }
        else{
            showMessage(title: "Enter User ID", text: "Please Enter Correct User ID")
        }
        
    }
    
    
    
    @IBAction func readClicked(_ sender: Any) {
        speak(logView.text ?? "No message here.")
    }
    
    
    @IBAction func volumeSliderChanged(_ sender: UISlider) {
        volume = Int(sender.value)
        print("Changing volume to \(volume)")
        agoraEngine.adjustAudioMixingVolume(volume)
    }
    
    
    @IBAction func muteTapped(_ sender: UISwitch) {
        isMuted = sender.isOn
        print("Changing mute state to \(isMuted)")
        agoraEngine.muteRemoteAudioStream(remoteUid, mute: isMuted)
    }
    
    
    
}


//MARK: - Lifecycle
extension ViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeAgoraEngine()
        
        speechRecognizer?.delegate = self

        speak("Hello! Do I know you?")
        
        self.userIdField.text = "edaaoneerr"
        self.tokenField.text = "007eJxTYBDQ/BzgfLF4nv/6yieLC9TPcc2NOtNy/k0gi4yEKM/jpz0KDAamZgYmqUaWlmaJxiZpqYmWxkbGhubmxhamBhZJRqnmJrzmKQ2BjAzhDRrMjAwQCOKzM4Sn5iTn56YyMAAAHvsdgg=="

        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized")
            case .denied:
                print("Speech recognition denied")
            case .restricted:
                print("Speech recognition restricted")
            case .notDetermined:
                print("Speech recognition not determined")
            @unknown default:
                fatalError()
            }
        }
        
        initChatSDK()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .duckOthers])
        } catch {
            print("Failed to set audio session category.")
        }
        
        view.addGestureRecognizer(tap)
        
    }
    
   
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        leaveChannel()
        DispatchQueue.global(qos: .userInitiated).async {AgoraRtcEngineKit.destroy()}
    }
}


//MARK: - Interface Setup
extension ViewController{
    func initializeAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        // Pass in your App ID here.
        config.appId = appID
        // Use AgoraRtcEngineDelegate for the following delegate parameter.
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraEngine.adjustRecordingSignalVolume(2)
    }
    
    func initChatSDK() {
        // Replaces <#Agora App Key#> with your own App Key.
        // Initializes the Agora Chat SDK.
        let options = AgoraChatOptions(appkey: "71944653#1103863")
        options.isAutoLogin = false // Disables auto login.
        options.enableConsoleLog = true
        AgoraChatClient.shared.initializeSDK(with: options)
        // Adds the chat delegate to receive messages.
        AgoraChatClient.shared.chatManager?.add(self, delegateQueue: nil)
    }
    
    
}


//MARK: - Agora Voice
extension ViewController{
    func joinChannel() async {
        if await !self.checkForPermissions() {
            showMessage(title: "Error", text: "Permissions were not granted")
            return
        }
        
        let option = AgoraRtcChannelMediaOptions()

        // Set the client role option as broadcaster or audience.
        if self.userRole == .broadcaster {
            option.clientRoleType = .broadcaster
        } else {
            option.clientRoleType = .audience
        }

        // For an audio call scenario, set the channel profile as communication.
        option.channelProfile = .communication

        // Join the channel with a temp token and channel name
        let result = agoraEngine.joinChannel(
            byToken: token, channelId: channelName, uid: 0, mediaOptions: option,
            joinSuccess: { (channel, uid, elapsed) in }
        )

        // Check if joining the channel was successful and set joined Bool accordingly
        if (result == 0) {
            joined = true
            showMessage(title: "Success", text: "Successfully joined the channel as \(self.userRole)")
            
        }
        
    }

    func leaveChannel() {
        let result = agoraEngine.leaveChannel(nil)
        // Check if leaving the channel was successful and set joined Bool accordingly
        if result == 0 { joined = false }
    }

    
    
}

//MARK: - Agora Chat
extension ViewController{
    func loginAction(completion: @escaping ()->()) {
        guard let userId = self.userIdField.text,
              let token = self.tokenField.text else {
            print("userId or token is empty")
            return
        }
        let err = AgoraChatClient.shared.login(withUsername: userId, agoraToken: token)
        if err == nil {
            print("login success")
            completion()
            
        } else {
            print("login failed:\(err?.errorDescription ?? "")")
        }
    }
    
    func logoutAction() {
        AgoraChatClient.shared.logout(false) { err in
            if err == nil {
                print("logout success")
            }
        }
    }
    
    // Sends a text message.
    func sendAction() {
        print("userid: \(remoteUserIdField.text ?? "1")", "msg: \(msgToSend ?? "Hello")")
        guard let remoteUser = remoteUserIdField.text,
              let text = msgToSend,
              let currentUserName = AgoraChatClient.shared.currentUsername else {
            print("Not login or remoteUser/text is empty")
            return
        }
        let msg = AgoraChatMessage(
            conversationId: remoteUser, from: currentUserName,
            to: remoteUser, body: .text(content: text), ext: nil
        )
        AgoraChatClient.shared.chatManager?.send(msg, progress: nil) { msg, err in
            if let err = err {
                print("send msg error.\(err.errorDescription ?? "Error occured")")
            } else {
                print("send msg success")
            }
        }
    }
    
}


//MARK: - STT and TTS
extension ViewController{
    func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.record)
        try audioSession.setMode(AVAudioSession.Mode.measurement)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode

        recognitionRequest.shouldReportPartialResults = true

        var recognitionTask: SFSpeechRecognitionTask?

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { result, error in
            var isFinal = false

            if let result = result {
                let transcription = result.bestTranscription.formattedString
                print(transcription)
                
                self.msgToSend = transcription
                self.logView.text = self.msgToSend
                self.sendAction()
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                recognitionTask = nil
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

    }
    
    func speak(_ text: String) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechUtterance.volume = 4.0
        speechUtterance.rate = 0.5 // adjust the speaking rate as needed
        speechSynthesizer.speak(speechUtterance)
    }
}

//MARK: - Helpers
extension ViewController{
    func checkForPermissions() async -> Bool {
        let hasPermissions = await self.avAuthorization(mediaType: .audio)
        return hasPermissions
    }

    func avAuthorization(mediaType: AVMediaType) async -> Bool {
        let mediaAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch mediaAuthorizationStatus {
        case .denied, .restricted: return false
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: mediaType) { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default: return false
        }
    }
    
    func showMessage(title: String, text: String, delay: Int = 2) -> Void {
        let deadlineTime = DispatchTime.now() + .seconds(delay)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            self.present(alert, animated: true)
            alert.dismiss(animated: true, completion: nil)
        })
    }
}

//MARK: - AgoraRtcEngineDelegate
extension ViewController: AgoraRtcEngineDelegate{
    // Callback called when a new host joins the channel
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        remoteUid = uid
    }
}

//MARK: - AgoraChatManagerDelegate
extension ViewController: AgoraChatManagerDelegate{
    
    func messagesDidReceive(_ aMessages: [AgoraChatMessage]) {
        
        for msg in aMessages {
            print("msg body type: \(msg.body)")
            switch msg.swiftBody {
            case let .text(content):
                print("receive text msg,content: \(content)")
                self.textField.text = content
                print("speaking...")
                self.speak(content)
                
                
            default:
                break
            }
        }
    }
}

//MARK: - SFSpeechRecognizerDelegate
extension ViewController: SFSpeechRecognizerDelegate{
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
    }
}


