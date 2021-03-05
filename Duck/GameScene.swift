//  GameScene.swift
//
//  Created by Team DUCK on 2/18/21.

import SpriteKit
import GameplayKit
import UIKit

func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}

//For specific detections
struct PhysicsCategory {
    static let enemy : UInt32 = 0b1
    static let projectile : UInt32 = 0b10
    static let detection : UInt32 = 0b11
    static let none : UInt32 = 0b100
}

struct Nests {
    let loc : CGPoint
    let name : String
    let sprite : SKSpriteNode
    let isOccupied : Bool
    let nestNumber : Int
}

struct Buttons {
    let loc : CGPoint
    let sprite: SKSpriteNode
    let isPresent : Bool
    let parentButton : String
    let name : String
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    //Unique Duck Identifier
    var duckIDX = 0
    //Unique Nest Identifier
    var nestIDX = 0
    var buttonIDX = 0
    
    var currentMap = SKSpriteNode(imageNamed: "TestMap")
    var portal = SKSpriteNode(imageNamed:"portal")
    
    public var remainingLives = 10
    public var healthLabel = SKLabelNode()
    public var currentMoney = 100
    public var moneyLabel = SKLabelNode()
    //How much 1 duck costs and how much money you get per goose
    var duckCost = 100
    var gooseReward = 50
    
    
    //Stores Information on Ducks and their corresponding detection radiuses in an array
    //Stored in a swift lock-key system
    var duckLocs = [(SKSpriteNode,SKShapeNode)]()
    
    //An array of all the buttons CURRENTLY on the screen
    var currentButtons: [Buttons] = []
    
    //An array of all the nests CURRENTLY on the screen
    var currentNests: [Nests] = []
    
    
    /* -------------------- FUNCTIONS -------------------- */
    
    func random() -> CGFloat {
      return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }

    func random(min: CGFloat, max: CGFloat) -> CGFloat {
      return random() * (max - min) + min
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self

        //Adding nest to appropriate spots
        addNest(location: CGPoint(x: self.frame.width/2 - 358, y: self.frame.height/2 - 150))
        
        //Label for the lives remaining
        healthLabel.text = "Remaining Lives:  " + String(remainingLives)
        healthLabel.zPosition = 2
        healthLabel.position = CGPoint(x: self.frame.width/1.2, y:self.frame.height/1.1)
        healthLabel.fontSize = CGFloat(20)
        healthLabel.fontColor = .black
        addChild(healthLabel)
        
        //Label for current money supply
        moneyLabel.text = "$: " + String(currentMoney)
        moneyLabel.zPosition = 2
        moneyLabel.position = CGPoint(x: self.frame.width/1.7, y: self.frame.height/1.1)
        moneyLabel.fontSize = CGFloat(20)
        moneyLabel.fontColor = .black
        addChild(moneyLabel)
    
        //Map
        currentMap.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        currentMap.size = CGSize(width: self.frame.width, height: self.frame.height)
        currentMap.name = "map"
        currentMap.zPosition = -1
        
        addChild(currentMap)
        
        portal.position = CGPoint(x: self.frame.width/8.75, y: self.frame.height/1.05)
        portal.zPosition = 0
        portal.size = CGSize(width: 100, height: 110)
        
        addChild(portal)
 
        run(SKAction.repeat(SKAction.sequence([SKAction.run(addGoose), SKAction.wait(forDuration: 2.5)]), count: 10))

        }
    
    //Detects any COLLISIONS and CONTACTS
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if (firstBody.categoryBitMask == PhysicsCategory.enemy) && (secondBody.categoryBitMask == PhysicsCategory.detection) {
            detectionHandler(obj: secondBody.node as! SKShapeNode, thing: firstBody.node as! SKSpriteNode)
        }else if (secondBody.categoryBitMask == PhysicsCategory.enemy) && (firstBody.categoryBitMask == PhysicsCategory.detection) {
            detectionHandler(obj: firstBody.node as! SKShapeNode, thing: secondBody.node as! SKSpriteNode)
        }else if (firstBody.categoryBitMask == PhysicsCategory.enemy) && (secondBody.categoryBitMask == PhysicsCategory.projectile) {
            collisionHandler(proj: secondBody.node as! SKSpriteNode, enemy: firstBody.node as! SKSpriteNode)
        }else if (secondBody.categoryBitMask == PhysicsCategory.enemy) && (firstBody.categoryBitMask == PhysicsCategory.projectile) {
            collisionHandler(proj: firstBody.node as! SKSpriteNode, enemy: secondBody.node as! SKSpriteNode)
        }else{
            return
        }
        
    }
    
    func showOptions(location : CGPoint, nn: String) {
        var idx = 0
        let posScale: CGFloat = 60 //Lower the number, lower the position
        let heightScale: CGFloat = 25 //Lower the number, the bigger the sprite
        var createdButton = false //Checks whether or not this is the first time you create the button
        if(currentButtons.count <= 0) {
            let buttonInfo = Buttons(loc: location, sprite: SKSpriteNode(imageNamed: "Breadcrumb"), isPresent: true, parentButton: nn, name: "Button\(buttonIDX)")
            
            let button = buttonInfo.sprite
            button.position = CGPoint(x: buttonInfo.loc.x, y: buttonInfo.loc.y + posScale)
            button.size = CGSize(width: button.size.width/(self.frame.width/heightScale), height: button.size.height/(self.frame.width/heightScale))
            button.zPosition = 3
            button.alpha = 0.9
        
            buttonIDX+=1
            currentButtons.append(buttonInfo)
            addChild(button)
            createdButton = true
        }
        for button in currentButtons {
            if (button.parentButton == nn && button.isPresent == false) && (createdButton == false){
                print(1)
                
                let buttonInfo = Buttons(loc: location, sprite: SKSpriteNode(imageNamed: "Breadcrumb"), isPresent: true, parentButton: nn, name: "Button\(buttonIDX)")
                
                let button = buttonInfo.sprite
                button.position = CGPoint(x: buttonInfo.loc.x, y: buttonInfo.loc.y + posScale)
                button.size = CGSize(width: button.size.width/(self.frame.width/heightScale), height: button.size.height/(self.frame.width/heightScale))
                button.zPosition = 3
                button.alpha = 0.9
                button.name = buttonInfo.name
            
                buttonIDX+=1
                currentButtons.append(buttonInfo)
                addChild(button)
                
                return
            } else if button.isPresent && createdButton == false {
                print("falsed")
                currentButtons.remove(at: idx)
                button.sprite.removeFromParent()
                return
            }
            idx+=1
        }
        
        
    }
    
    //Make a button function:
    /*
     let buttonInfo = Buttons(loc: location, sprite: SKSpriteNode(imageNamed: "Breadcrumb"), didPress: true, parentButton: nn, name: "Button\(buttonIDX)")
     
     let button = buttonInfo.sprite
     button.position = buttonInfo.loc
     button.size = CGSize(width: button.size.width/(self.frame.width/20), height: button.size.height/(self.frame.width/20))
     button.zPosition = 3
     button.alpha = 0.9
 
     buttonIDX+=1
     currentButtons.append(buttonInfo)
     addChild(button)
     */
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            let location = touch.location(in: self)
            
            //For buttons
            enumerateChildNodes(withName: "//*", using: { (node, stop) in
                
                if node.name?.prefix(4) == "Nest" {
                    
                    if node.contains(location){
                        node.alpha = 0.5
                        self.showOptions(location: node.position, nn: node.name!)
                    }
                    
                } else if node.name?.prefix(6) == "Button" {
                    if node.contains(location) {
                        node.alpha = 0.5
                    }
                }
                
            })
            
            //Checks if there is a duck at where you tapped.
            for duck in duckLocs {
                if location.x >= duck.0.position.x - 20 && location.x <= duck.0.position.x + 20 && location.y >= duck.0.position.y - 20 && location.y <= duck.0.position.y + 20 {
                    print("Duck at this location: \(duck.0.position)")
                    if(duck.1.alpha > 0){
                        duck.1.alpha = 0
                    }else{
                        duck.1.alpha = 0.1
                    }
                }
            }
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            enumerateChildNodes(withName: "//*", using: { (node, stop) in
                
                if node.name?.prefix(4) == "Nest" {
                    if node.contains(touch.location(in: self)){
                        node.alpha = 1
                    }
                } else if node.name?.prefix(5) == "Button" {
                    if node.contains(touch.location(in: self)){
                        node.alpha = 1
                    }
                }
                
            })
        }
    }
    
    /* -------------------- ADD FUNCTIONS -------------------- */
 
    func addNest(location: CGPoint) {
        //Store Information in the struct
        let nestInfo = Nests(loc: location, name: "Nest\(nestIDX)", sprite: SKSpriteNode(imageNamed: "Nest"), isOccupied: false, nestNumber: nestIDX)
        currentNests.append(nestInfo)
        
        //Make the actual nest
        let nest = nestInfo.sprite
        nest.position = nestInfo.loc
        nest.name = nestInfo.name
        nest.size = CGSize(width: nest.size.width/(self.frame.width/45), height: nest.size.height/(self.frame.width/45))
        nest.zPosition = 2
        
        
        addChild(nest)
        nestIDX += 1
    }
    
    func addDuck(loc: CGPoint) {
        physicsWorld.contactDelegate = self
        
        //Only allows a duck to be placed if player has enough money and if there is not more than 5 ducks, and subtracts that money from their total
        if (self.currentMoney >= duckCost && duckIDX < 5) {
            self.currentMoney -= duckCost
            self.moneyLabel.text = "$: " + String(self.currentMoney)
        } else {
            return
        }
        //Makes a duck
        let duck = SKSpriteNode(imageNamed: "BasicDuckFullBody")
        duckIDX+=1
        duck.position = loc
        duck.size = CGSize(width: 100, height: 110)
        duck.name = "Duck\(duckIDX)"
        duck.zPosition = 3
        
        // Detection Circle to detect Geese that are close
        let detectionCircle = SKShapeNode(circleOfRadius: 100)
        detectionCircle.physicsBody = SKPhysicsBody(circleOfRadius: 80)
        detectionCircle.position = CGPoint(x: duck.position.x - 2, y: duck.position.y + 15)
        detectionCircle.fillColor = .cyan
        detectionCircle.physicsBody?.affectedByGravity = false
        detectionCircle.name = "DetectionCircle\(duckIDX)"
        detectionCircle.alpha = 0.1
        detectionCircle.physicsBody?.usesPreciseCollisionDetection = true
        detectionCircle.physicsBody?.isDynamic = true
        //Collisions:
        detectionCircle.physicsBody?.categoryBitMask = PhysicsCategory.detection
        detectionCircle.physicsBody?.collisionBitMask = PhysicsCategory.none
        detectionCircle.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        
        //Adds duck to current list of ducks
        duckLocs.append((duck, detectionCircle))
        addChild(detectionCircle)
        addChild(duck)
    }
    
    func addGoose() {  // Goose Spawner
      
        physicsWorld.contactDelegate = self
        
      // Create sprite
      let goose = SKSpriteNode(imageNamed: "BasicGooseFullBody")
        goose.size = CGSize(width: 58, height: 70)
        goose.physicsBody = SKPhysicsBody(circleOfRadius: 70)
        goose.zPosition = 1
        
        goose.physicsBody?.usesPreciseCollisionDetection = true
        goose.name = "enemy"
        goose.physicsBody?.isDynamic = false

        goose.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        goose.physicsBody?.collisionBitMask = PhysicsCategory.projectile
        goose.physicsBody?.contactTestBitMask = PhysicsCategory.detection | PhysicsCategory.projectile

        goose.position = CGPoint(x: self.frame.width/8.75, y: self.frame.height/1.05)
      
      // Add the monster to the scene
      addChild(goose)
        
      // Determine speed of the geese. Bigger number = faster
        let gooseSpeed = 0.9
      
      // Create the actions

        let firstMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/8.75, y: self.frame.height/2.82),duration: TimeInterval((320.0/250.0)/gooseSpeed)),
            SKAction.run {goose.zRotation = CGFloat(Double.pi/2.0)}
        ])
            
        let secondMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/3.3, y: self.frame.height/2.82), duration: TimeInterval((250.0/250.0)/gooseSpeed)),
            SKAction.run {goose.zRotation = CGFloat(Double.pi)}])
        
        let thirdMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/3.3, y: self.frame.height/1.30), duration: TimeInterval((245.0/250.0)/gooseSpeed)),
            SKAction.run {goose.zRotation = CGFloat(Double.pi/2.0)}])
        
        let fourthMove = SKAction.sequence([
                                            SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/1.30), duration: TimeInterval((685.0/250.0)/gooseSpeed)),
            SKAction.run {goose.zRotation = CGFloat(Double.pi * 0)}])
        
        let fifthMove = SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/5), duration: TimeInterval((320.0/250.0)/gooseSpeed))
        
        let finalAction = SKAction.sequence(
            [SKAction.run {self.remainingLives -= 1},
             SKAction.run{self.healthLabel.text = "Remaining Lives:  " + String(self.remainingLives)},
             SKAction.removeFromParent()])

      goose.run(SKAction.sequence([firstMove,secondMove,thirdMove, fourthMove, fifthMove, finalAction]))
        
    }
    
    /* -------------------- ACTIONS -------------------- */
    func launchBreadcrumb (startPoint: CGPoint, endPoint: CGPoint) {
        let crumb = SKSpriteNode (imageNamed: "Breadcrumb")
        crumb.size = CGSize(width: 30, height: 30)
        crumb.position = startPoint
        crumb.zPosition = 1
        crumb.name = "projectile"
        crumb.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        crumb.physicsBody?.usesPreciseCollisionDetection = true
        crumb.physicsBody?.affectedByGravity = false
        crumb.physicsBody?.isDynamic = true
       
        crumb.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        crumb.physicsBody?.collisionBitMask = PhysicsCategory.enemy
        crumb.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        
        let rotation = CGFloat (random(min: 0, max: CGFloat( 2.0 * Double.pi)))
        
        crumb.zRotation = rotation
        addChild(crumb)
          
        crumb.run(SKAction.sequence([SKAction.move(to: endPoint, duration: 0.2), SKAction.removeFromParent()]))
    }
    
    /* -------------------- HANDLERS -------------------- */
    
    //Used for the detection circle to indicate whether or not a goose has entered the "bread" zone
    //NOTE: This is where you can get the geese's position as well ("thing" is the reference to the goose)
    func detectionHandler(obj: SKShapeNode, thing: SKSpriteNode){
        thing.removeFromParent()
        self.currentMoney += gooseReward
        self.moneyLabel.text = "$: " + String(self.currentMoney)
        launchBreadcrumb(startPoint: obj.position, endPoint: thing.position)
    }
    
    //Used to actually deal damage to the goose if the breadcrumbs collide with a goose.
    func collisionHandler(proj: SKSpriteNode, enemy: SKSpriteNode){
        enemy.removeFromParent()
        self.currentMoney += gooseReward
        self.moneyLabel.text = "$: " + String(self.currentMoney)
    }
    
}
