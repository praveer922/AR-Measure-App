import Foundation
import RealityKit
import SwiftUI

class Coordinator {
    var arView: ARView?
    var startAnchor: AnchorEntity?
    var endAnchor: AnchorEntity?
    
    lazy var measurementButton: UIButton = {
        let button = UIButton(configuration: .filled())
        button.setTitle("0.00", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        return button
    }()
    
    lazy var resetButton: UIButton = {
        
        let button = UIButton(configuration: .gray(), primaryAction: UIAction(handler: { [weak self] action in
            guard let arView = self?.arView else { return }
            self?.startAnchor = nil
            self?.endAnchor = nil
            
            arView.scene.anchors.removeAll()
            self?.measurementButton.setTitle("0.00", for: .normal)
        }))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Reset", for: .normal)
        return button
        
    }()
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        
        guard let arView = arView else { return }
        let tappedLocation = recognizer.location(in: arView)
        
        let results = arView.raycast(from: tappedLocation, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let result = results.first {
            
            if startAnchor == nil {
                startAnchor = AnchorEntity(raycastResult: result)
                let ball = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.01), materials: [SimpleMaterial(color: .green,isMetallic: false)])
                startAnchor?.addChild(ball)
                
                guard let startAnchor = startAnchor else {
                    return
                }
                arView.scene.addAnchor(startAnchor)
            } else if endAnchor == nil {
                endAnchor = AnchorEntity(raycastResult: result)
                let ball = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.01), materials: [SimpleMaterial(color: .green,isMetallic: false)])
                endAnchor?.addChild(ball)
                
                guard let endAnchor = endAnchor,
                      let startAnchor = startAnchor
                else {
                    return
                }
                arView.scene.addAnchor(endAnchor)
                
                // calculate distance once endpoint is added
                let startPoint = startAnchor.position(relativeTo: nil)
                let endPoint = endAnchor.position(relativeTo: nil)
                let distance = simd_distance(startPoint, endPoint)
                measurementButton.setTitle(String(format: "%.2f meters", distance), for: .normal)
                
                // draw line between the two points
                
                // depth is equal to the distance between two entities
                let rectangle = ModelEntity(mesh: .generateBox(width: 0.003, height: 0.003, depth: distance), materials: [SimpleMaterial(color: UIColor(.blue), isMetallic: false)])
                    
                // middle point of two points
                let middlePoint : simd_float3 = simd_float3((startPoint.x + endPoint.x)/2, (startPoint.y + endPoint.y)/2, (startPoint.z + endPoint.z)/2)
                        
                let lineAnchor = AnchorEntity()
                lineAnchor.position = middlePoint
                lineAnchor.look(at: startPoint, from: middlePoint, relativeTo: nil)
                lineAnchor.addChild(rectangle)
                arView.scene.addAnchor(lineAnchor)
            }
            
            
            
        }
        
    }
    
    func setupUI() {
        
        guard let arView = arView else { return }
        
        let stackView = UIStackView(arrangedSubviews: [measurementButton, resetButton])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        arView.addSubview(stackView)
        
        stackView.centerXAnchor.constraint(equalTo: arView.centerXAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: arView.bottomAnchor, constant: -60).isActive = true
        stackView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
    }
    
}
