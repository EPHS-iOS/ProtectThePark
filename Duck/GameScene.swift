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
    let nestNumber : Int
}

struct Buttons {
    let loc : CGPoint
    let sprite: SKSpriteNode
    var isPresent : Bool
    let parentButton : String
    let name : String
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    //Unique Duck Identifier
    var duckIDX = 0
    //Unique Nest Identifier
    var nestIDX = 0
    
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
    
    //An array of all the buttons
    var currentButtons: [Buttons] = []
    
    //An array of all the nests CURRENTLY on the screen
    var currentNests: [Nests] = []
    
    
    /* -------------------- FUNCTIONS -------------------- */
    
    func random() -> CGFloat {
      return CGFloat(Float(arc4random()) / 4294967296)
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
        addNest(location: CGPoint(x: self.frame.width/12, y: self.frame.height/8.5))
        addNest(location: CGPoint(x: self.frame.width/4.9, y: self.frame.height/1.8))
        addNest(location: CGPoint(x: self.frame.width/2.5, y: self.frame.height/2.2))
        addNest(location: CGPoint(x: self.frame.width/1.4, y: self.frame.height/1.75))
        addNest(location: CGPoint(x: self.frame.width/1.25, y: self.frame.height/3.75))
        
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
 
        run(firstWave())

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
    
    func showOptions(nn: SKSpriteNode) {
        
        if currentMoney < 100 {
            print("Could not purchase duck: Insufficient Costs")
            return
        }
        
        if nn.name?.suffix(4) == "true" {
            print("Could not purchase duck: Duck is already there!")
        }
        
        if nn.name?.suffix(1) == "0" {
            for button in currentButtons{
                if button.name.suffix(1) == "0"{
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    nn.name = nn.name! + "true"
                }
            }
        } else if nn.name?.suffix(1) == "1" {
            for button in currentButtons{
                if button.name.suffix(1) == "1"{
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    nn.name = nn.name! + "true"
                }
            }
        } else if nn.name?.suffix(1) == "2" {
            for button in currentButtons{
                if button.name.suffix(1) == "2"{
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    nn.name = nn.name! + "true"
                }
            }
        } else if nn.name?.suffix(1) == "3" {
            for button in currentButtons{
                if button.name.suffix(1) == "3"{
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    nn.name = nn.name! + "true"
                }
            }
        } else if nn.name?.suffix(1) == "4" {
            for button in currentButtons{
                if button.name.suffix(1) == "4"{
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    nn.name = nn.name! + "true"
                }
            }
        }

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            let location = touch.location(in: self)
            
            //For buttons
            enumerateChildNodes(withName: "//*", using: { (node, stop) in
                
                if node.name?.prefix(4) == "Nest" {
                    
                    if node.contains(location){
                        node.alpha = 0.5
                        self.showOptions(nn: node as! SKSpriteNode)
                    }
                    
                } else if node.name?.prefix(6) == "Option" {
                    if node.contains(touch.location(in: self)){
                        
                        if node.alpha == 0 {
                            print("Button does not exist yet...")
                            return
                            
                        }
                        
                        if node.name == "Option0" {
                            self.addDuck(loc: CGPoint(x: node.position.x + 5, y: node.position.y - 75))
                            node.alpha = 0
                        } else if node.name == "Option1" {
                            self.addDuck(loc: CGPoint(x: node.position.x + 5, y: node.position.y - 75))
                            node.alpha = 0
                        } else if node.name == "Option2" {
                            self.addDuck(loc: CGPoint(x: node.position.x + 5, y: node.position.y - 75))
                            node.alpha = 0
                        } else if node.name == "Option3" {
                            self.addDuck(loc: CGPoint(x: node.position.x + 5, y: node.position.y - 75))
                            node.alpha = 0
                        } else if node.name == "Option4" {
                            self.addDuck(loc: CGPoint(x: node.position.x + 5, y: node.position.y - 75))
                            node.alpha = 0
                        }
                        
                    }
                }
                
            })
            
            //Checks if there is a duck at where you tapped.
            for duck in duckLocs {
                if location.x >= duck.0.position.x - 20 && location.x <= duck.0.position.x + 20 && location.y >= duck.0.position.y - 20 && location.y <= duck.0.position.y + 20 {
                    print("Duck at this location: \(duck.0.position)")
                    if(duck.1.alpha > 0){
                        duck.1.alpha = 0
                    } else {
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
                }
                
            })
        }
    }
    
    /* -------------------- ADD FUNCTIONS -------------------- */
 
    func addNest(location: CGPoint) {
        let posScale = CGFloat(60)
        
        //Make the actual nest
        let nest = SKSpriteNode(imageNamed: "Nest")
        nest.position = location
        nest.name = "Nest\(nestIDX)"
        nest.size = CGSize(width: 75, height: 100)
        nest.zPosition = 2
        
        //Add the buttons for upgrades or ducks at a specified location above the nest.
        addOptions(loc: CGPoint(x: nest.position.x, y: nest.position.y + posScale),pB: nest.name!, id: "Option\(nest.name!.suffix(1))");
        
        addChild(nest)
        currentNests.append(Nests(loc: nest.position, name: nest.name!, sprite: nest, nestNumber: nestIDX))
        nestIDX += 1
    }
    
    func addOptions(loc: CGPoint, pB: String, id: String){
        print("id: " + id)
        let heightScale = CGFloat(25)
        
        let option = SKSpriteNode(imageNamed: "Breadcrumb")
        option.name = id
        option.position = loc
        option.zPosition = 2
        option.alpha = 0
        option.size = CGSize(width: option.size.width/(self.frame.width/heightScale), height: option.size.height/(self.frame.width/heightScale))
        
        addChild(option)
        currentButtons.append(Buttons(loc: option.position, sprite: option, isPresent: true, parentButton: pB, name: option.name!))
        
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
        
        duckIDX+=1
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
      
      // Add the goose to the scene
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
        
        let fourthMove = SKAction.sequence([ SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/1.30), duration: TimeInterval((685.0/250.0)/gooseSpeed)),
            SKAction.run {goose.zRotation = CGFloat(Double.pi * 0)}])
        
        let fifthMove = SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/5), duration: TimeInterval((320.0/250.0)/gooseSpeed))
        
        let finalAction = SKAction.sequence(
            [SKAction.run {self.remainingLives -= 1},
             SKAction.run{self.healthLabel.text = "Remaining Lives:  " + String(self.remainingLives)},
             SKAction.removeFromParent(),
             SKAction.run {
                if self.remainingLives <= 0 {
                    let gameOverScene = SKScene(fileNamed: "GameOver")
                    self.view?.presentScene(gameOverScene)
                    
                }
             }
            ])

      goose.run(SKAction.sequence([firstMove,secondMove,thirdMove, fourthMove, fifthMove, finalAction]))
        
    }
    

    /* -------------------- ACTIONS -------------------- */
    func launchBreadcrumb (startPoint: CGPoint, endPoint: CGPoint) {
        let crumb = SKSpriteNode (imageNamed: "Breadcrumb")
        crumb.size = CGSize(width: 30, height: 30)
        crumb.position = startPoint
        crumb.zPosition = 1
        crumb.name = "projectile"
        crumb.physicsBody = SKPhysicsBody(circleOfRadius: 1)
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
        let circleID  = (obj.name!.replacingOccurrences(of: "DetectionCircle", with: "Duck"))
        let spinningDuck = childNode(withName: circleID)!
        let distanceX = spinningDuck.position.x - thing.position.x
        let distanceY = spinningDuck.position.y - thing.position.y
        if distanceY >= 0 {
            spinningDuck.zRotation = CGFloat(2 * Double.pi - atan(Double(distanceX/distanceY))) //If duck is above or equal to goose
        } else {
            spinningDuck.zRotation = CGFloat(Double.pi - atan(Double(distanceX/distanceY))) //If duck is below goose
        }
        launchBreadcrumb(startPoint: obj.position, endPoint: thing.position)
    }
    
    //Used to actually deal damage to the goose if the breadcrumbs collide with a goose.
    func collisionHandler(proj: SKSpriteNode, enemy: SKSpriteNode) {
        enemy.removeFromParent()
        proj.removeFromParent()
        self.currentMoney += gooseReward
        self.moneyLabel.text = "$: " + String(self.currentMoney)
    }
      
    //Adds a series of geese with number "amt" and waits for "speed" seconds between each goose
    public func gooseSeries(amt: Int, speed: Double) -> SKAction {
        SKAction.repeat(SKAction.sequence([SKAction.run(addGoose), SKAction.wait(forDuration: speed)]), count: amt)
    }
    
    func firstWave() -> SKAction{
        SKAction.sequence([
            gooseSeries(amt: 10, speed: 1.5),
            gooseSeries(amt: 15, speed: 1.0),
            gooseSeries(amt: 20, speed: 0.5)
        ])
    }

}

