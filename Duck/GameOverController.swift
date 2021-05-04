//
//  GameOverController.swift
//  Duck
//
//  Created by Randy Thai on 4/29/21.
//  Main controller for GameOver scene.

import Foundation
import UIKit
import GameplayKit
import SpriteKit

class GameOverController : SKScene {
    
    func createButtons(){
        
        let mainButton = SKShapeNode(rectOf: CGSize(width: self.frame.width/6 + 60, height: self.frame.height/12 + 30), cornerRadius: CGFloat(15))
        mainButton.position = CGPoint(x: -self.frame.width/10 - 100, y: -self.frame.width/10 - 30)
        mainButton.fillColor = .red
        mainButton.alpha = 0.4
        mainButton.name = "main"
        
        let mainLabel = SKLabelNode()
        mainLabel.position = CGPoint(x: mainButton.position.x, y: mainButton.position.y - 5)
        mainLabel.fontSize = 18
        mainLabel.fontName = "HelveticaNeue-Bold"
        mainLabel.alpha = 0.7
        mainLabel.text = "Return to Main Menu"
        
        let retryButton = SKShapeNode(rectOf: CGSize(width: self.frame.width/6 + 60, height: self.frame.height/12 + 30), cornerRadius: CGFloat(15))
        retryButton.position = CGPoint(x: self.frame.width/10 + 100, y: -self.frame.width/10 - 30)
        retryButton.fillColor = .blue
        retryButton.alpha = 0.4
        retryButton.name = "retry"
        
        let retryLabel = SKLabelNode()
        retryLabel.position = CGPoint(x: retryButton.position.x, y: retryButton.position.y - 5)
        retryLabel.fontName = "HelveticaNeue-Bold"
        retryLabel.fontSize = 18
        retryLabel.alpha = 0.7
        retryLabel.text = "Retry"
        
        addChild(mainButton)
        addChild(mainLabel)
        addChild(retryButton)
        addChild(retryLabel)
        
    }
    
    override func didMove(to view: SKView) {
        
        print("Game Over!")
        
        let gameOverImage = SKSpriteNode(imageNamed:"CroppedGameOver")
        gameOverImage.size = CGSize(width: self.frame.width, height: self.frame.height)
        gameOverImage.zPosition = -1
        
        addChild(gameOverImage)
        
        createButtons()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            
        let touch:UITouch = touches.first! as UITouch
        let positionInScene = touch.location(in: self)
        let touchedNode = self.atPoint(positionInScene)
        
        if let name = touchedNode.name {

            if name == "retry" {

                switchScreen(scene: "GameScene")

            } else if name == "main" {

                print("Transferring to Main Menu.")


            }

        }
    
    }
    
    func switchScreen(scene : String){
        
        self.view!.presentScene(GameScene(fileNamed: scene))
        
    }
    
}

