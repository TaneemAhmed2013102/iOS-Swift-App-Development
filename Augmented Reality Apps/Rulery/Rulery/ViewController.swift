import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var dotNodes = [SCNNode]()
    var focusNode: SCNNode!
    var statusLabel: UILabel!
    var isSurfaceDetected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Create and configure status label
        setupStatusLabel()
        
        // Create focus node
        createFocusNode()
        
        // Enable debug options during development
        sceneView.debugOptions = [.showFeaturePoints]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Setup Methods
    
    func setupStatusLabel() {
        statusLabel = UILabel(frame: CGRect(x: 0, y: 50, width: view.frame.width, height: 60))
        statusLabel.textAlignment = .center
        statusLabel.textColor = .white
        statusLabel.font = UIFont.boldSystemFont(ofSize: 20)
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        statusLabel.text = "Move device to detect surfaces"
        view.addSubview(statusLabel)
    }
    
    func createFocusNode() {
        let focusRing = SCNTorus(ringRadius: 0.05, pipeRadius: 0.002)
        focusRing.firstMaterial?.diffuse.contents = UIColor.yellow
        focusNode = SCNNode(geometry: focusRing)
        focusNode.eulerAngles.x = -.pi / 2
        focusNode.isHidden = true
        sceneView.scene.rootNode.addChildNode(focusNode)
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusNode()
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            break
        case .limited(let reason):
            switch reason {
            case .initializing, .relocalizing:
                statusLabel.text = "Initializing - keep moving slowly"
            case .excessiveMotion:
                statusLabel.text = "Move device slower"
            case .insufficientFeatures:
                statusLabel.text = "Point at more textured surfaces"
            default:
                statusLabel.text = "Tracking limited"
            }
        case .notAvailable:
            statusLabel.text = "Tracking unavailable"
        }
    }
    
    // MARK: - Focus Node Handling
    
    func updateFocusNode() {
        let screenCenter = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        
        // Perform hit test from screen center
        let hitTestResults = sceneView.hitTest(screenCenter, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane, .estimatedVerticalPlane])
        
        if let result = hitTestResults.first {
            let hitPosition = result.worldTransform.columns.3
            focusNode.position = SCNVector3(hitPosition.x, hitPosition.y, hitPosition.z)
            focusNode.isHidden = false
            isSurfaceDetected = true
            statusLabel.text = "Surface detected - tap to place dot"
        } else {
            focusNode.isHidden = true
            isSurfaceDetected = false
            statusLabel.text = "Move device to detect surfaces"
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isSurfaceDetected else {
            showErrorFeedback()
            return
        }
        
        // Place dot at focus node position
        placeDot(at: focusNode.position)
        
        // Handle dot limit
        if dotNodes.count >= 2 {
            calculateDistance()
            resetDots()
        }
    }
    
    func placeDot(at position: SCNVector3) {
        let dotGeometry = SCNSphere(radius: 0.01)
        dotGeometry.firstMaterial?.diffuse.contents = UIColor.systemRed
        
        let dotNode = SCNNode(geometry: dotGeometry)
        dotNode.position = position
        sceneView.scene.rootNode.addChildNode(dotNode)
        dotNodes.append(dotNode)
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    // MARK: - Measurement Logic
    
    func calculateDistance() {
        guard dotNodes.count >= 2 else { return }
        
        let start = dotNodes[0].position
        let end = dotNodes[1].position
        
        // Calculate distance
        let distance = sqrt(
            pow(end.x - start.x, 2) +
            pow(end.y - start.y, 2) +
            pow(end.z - start.z, 2)
        
        // Convert to centimeters
        let distanceCm = distance * 100
        
        // Show measurement
        showMeasurementPopup(distance: distanceCm)
    }
    
    func showMeasurementPopup(distance: Float) {
        let alert = UIAlertController(
            title: "Distance Measurement",
            message: String(format: "Distance: %.2f cm", distance),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    
    func resetDots() {
        for dot in dotNodes {
            dot.removeFromParentNode()
        }
        dotNodes.removeAll()
    }
    
    func showErrorFeedback() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        
        // Animate label to get attention
        UIView.animate(withDuration: 0.1, animations: {
            self.statusLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.statusLabel.backgroundColor = UIColor.red.withAlphaComponent(0.7)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.statusLabel.transform = .identity
                self.statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        resetDots()
        focusNode.isHidden = true
        statusLabel.text = "Reset - move device to detect surfaces"
    }
}