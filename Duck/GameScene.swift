//  GameScene.swift
//
//  Created by Team DUCK on 2/18/21.
import Foundation
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

struct Scenes {
    let gameScene : SKScene = GameScene(fileNamed: "GameScene")!
    let gameOver : SKScene = GameScene(fileNamed: "GameOver")!
    let victory : SKScene = GameScene(fileNamed: "Victory")!
}

//For specific detections
struct PhysicsCategory {
    static let enemy : UInt32 = 0b1
    static let projectile : UInt32 = 0b10
    static let detection : UInt32 = 0b11
    static let none : UInt32 = 0
}

struct Nests {
    let loc : CGPoint
    let sprite : SKSpriteNode
    let nestNumber : Int
}

struct Ducks {
    var canFire = true
    let sprite: SKSpriteNode
    var damage: CGFloat
    var level: Int
    var upgradeCost: Int
    var cooldownDelay: TimeInterval
    var duckType: String
}

struct Buttons {
    let loc : CGPoint
    let sprite: SKSpriteNode
    var isPresent : Bool
    let parentButton : String
}

struct Gooses {
    var health : CGFloat
    let sprite : SKSpriteNode
}

struct breadcrumb  {
    let damage : CGFloat
    let sprite : SKSpriteNode
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    //Unique Duck Identifier
    var duckIDX = 0
    
    //Unique Nest Identifier
    var nestIDX = 0
    
    var currentMap = SKSpriteNode(imageNamed: "TestMap")
    var portal = SKSpriteNode(imageNamed:"gooseForest")
    
    public var remainingLives = 1000000
    public var healthLabel = SKLabelNode()
    public var currentMoney = 150
    public var moneyLabel = SKLabelNode()
    public var waveLabel = SKLabelNode()
    public var currentCrumb: breadcrumb = breadcrumb(damage: 0, sprite: SKSpriteNode())
    
    //How much 1 duck costs and how much money you get per goose
    var duckCost = 100
    var gooseReward = 600
    var variantCost = 1750
    
    //Stores Information on Ducks and their corresponding detection radiuses in an array
    //Stored in a swift lock-key system
    var duckInfo = [(SKSpriteNode,SKShapeNode)]()
    
    //An array of all the buttons
    var currentButtons: [Buttons] = []
    
    //An array of all the nests CURRENTLY on the screen
    var currentNests: [Nests] = []
    //array of geese
    var currentGeese: [Gooses] = []
    
    //An array of current ducks on the screen
    var currentDucks: [Ducks] = []
    
    var upgradeLabels: [SKLabelNode] = []
    
    var variantLabels: [SKLabelNode] = []
    
    var variantSprites: [SKSpriteNode] = []
    
    var isSpecialized: [Bool] = [false, false, false, false, false]
    
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
        addNest(location: CGPoint(x: self.frame.width/12, y: self.frame.height/8.5), isWater: false)
        addNest(location: CGPoint(x: self.frame.width/4.9, y: self.frame.height/1.8), isWater: false)
        addNest(location: CGPoint(x: self.frame.width/2.5, y: self.frame.height/2.2), isWater: false)
        addNest(location: CGPoint(x: self.frame.width/1.4, y: self.frame.height/1.75), isWater: false)
        addNest(location: CGPoint(x: self.frame.width/1.20, y: self.frame.height/3.50), isWater: true)
        
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
        
        //Label for current wave
        waveLabel.text = "Hello World"
        waveLabel.zPosition = 2
        waveLabel.position = CGPoint(x: self.frame.width/2.3, y: self.frame.height/1.1)
        waveLabel.fontSize = CGFloat(20)
        waveLabel.fontColor = .black
        addChild(waveLabel)
    
        //Map
        currentMap.position = CGPoint(x: self.frame.width/2, y: self.frame.height/2)
        currentMap.size = CGSize(width: self.frame.width, height: self.frame.height)
        currentMap.name = "map"
        currentMap.zPosition = -1
        
        addChild(currentMap)
    
        
        portal.position = CGPoint(x: self.frame.width/8.80, y: self.frame.height/1.05)
        portal.zPosition = 0
        portal.size = CGSize(width: portal.size.width/(self.frame.width/750), height: portal.size.height/(self.frame.height/550))
        
        addChild(portal)
 
        run(endlessMode())

        }
    
    //Detects any COLLISIONS and CONTACTS
    func didBegin(_ contact: SKPhysicsContact) {
        
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if (firstBody.categoryBitMask == PhysicsCategory.enemy) && (secondBody.categoryBitMask == PhysicsCategory.detection) {
        
            var aDuck : SKSpriteNode
            let id = secondBody.node!.name?.suffix(1)
            for duck in currentDucks {
                if duck.sprite.name!.suffix(1) == id {
                    aDuck = duck.sprite
                    detectionHandler(circle: secondBody.node as! SKShapeNode, goose: firstBody.node as! SKSpriteNode, duck: aDuck)
                }
            }
            
            
        }else if (secondBody.categoryBitMask == PhysicsCategory.enemy) && (firstBody.categoryBitMask == PhysicsCategory.detection) {
            
            var aDuck : SKSpriteNode
            let id = firstBody.node!.name?.suffix(1)
            for duck in currentDucks {
                if duck.sprite.name!.suffix(1) == id {
                    aDuck = duck.sprite
                    detectionHandler(circle: firstBody.node as! SKShapeNode, goose: secondBody.node as! SKSpriteNode, duck: aDuck)
                }
            }
            
            
        }else if (firstBody.categoryBitMask == PhysicsCategory.enemy) && (secondBody.categoryBitMask == PhysicsCategory.projectile) {
           
            collisionHandler(proj: secondBody.node as! SKSpriteNode, enemy: firstBody.node as! SKSpriteNode, dmg: currentCrumb.damage)
        }else if (secondBody.categoryBitMask == PhysicsCategory.enemy) && (firstBody.categoryBitMask == PhysicsCategory.projectile) {
           
            collisionHandler(proj: firstBody.node as! SKSpriteNode, enemy: secondBody.node as! SKSpriteNode, dmg: currentCrumb.damage)
        }else{
            return
        }
        
    }
    
    func showOptions(nn: SKSpriteNode) {
        
        if currentMoney < duckCost {
            print("Could not purchase duck: Insufficient Costs")
            return
        }
        
        if nn.name?.suffix(4) == "true" {
            print("Could not purchase duck: Duck is already there!")
        }
        
        if nn.name?.suffix(1) == "0" {
            for button in currentButtons{
                if button.sprite.name!.suffix(1) == "0"{
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
                if button.sprite.name!.suffix(1) == "1"{
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
                if button.sprite.name!.suffix(1) == "2"{
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
                if button.sprite.name!.suffix(1) == "3"{
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
                if button.sprite.name!.suffix(1) == "4"{
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
    
    func showUpgrades (duck: Ducks) {
        //print(duck.sprite.name!)
        let idNum = duck.sprite.name!.suffix(1)
        for label in upgradeLabels {
            if label.name!.suffix(1) == idNum {
                updateLabel(label: label, duck: duck)
            }
        }
        
        
        if duck.sprite.name!.suffix(1) == "0" {
            var i = 0
            while i < currentButtons.count{
                let button = currentButtons[i]
                if button.sprite.name!.suffix(1) == "0" {
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    currentButtons[i].sprite.name = "Upgrade0"
                    
                }
                i += 1
                
            }
            i = 0
            
        } else if duck.sprite.name!.suffix(1) == "1" {
            var j = 0
            while j < currentButtons.count{
                let button = currentButtons[j]
                if button.sprite.name!.suffix(1) == "1" {
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    currentButtons[j].sprite.name! = "Upgrade1"
                    
                }
                j += 1
               
                
            }
            
        }else if duck.sprite.name!.suffix(1) == "2" {
            var k = 0
            while k < currentButtons.count{
                let button = currentButtons[k]
                if button.sprite.name!.suffix(1) == "2" {
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    currentButtons[k].sprite.name! = "Upgrade2"
                }
                k += 1
                
              
            }
            
        } else if duck.sprite.name!.suffix(1) == "3" {
            var l = 0
            while l < currentButtons.count{
                let button = currentButtons[l]
                if button.sprite.name!.suffix(1) == "3" {
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    currentButtons[l].sprite.name! = "Upgrade3"
                    
                }
                l += 1
               
                
            }
            
        } else if duck.sprite.name!.suffix(1) == "4" {
            var m = 0
            while m < currentButtons.count{
                let button = currentButtons[m]
                if button.sprite.name!.suffix(1) == "4" {
                    if button.sprite.alpha == 1 {
                        button.sprite.alpha = 0
                        return
                    }
                    
                    button.sprite.alpha = 1
                    currentButtons[m].sprite.name! = "Upgrade4"
                    
                }
                m += 1
                
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
                        
                        let upDown : CGFloat = -60
                        let leftRight: CGFloat = -3
                        
                        if node.name == "Option0" {
                            self.addDuck(loc: CGPoint(x: node.position.x + leftRight, y: node.position.y + upDown), id: String(node.name!.suffix(1)))
                            node.alpha = 0
                        } else if node.name == "Option1" {
                            self.addDuck(loc: CGPoint(x: node.position.x + leftRight, y: node.position.y + upDown), id: String(node.name!.suffix(1)))
                            node.alpha = 0
                        } else if node.name == "Option2" {
                            self.addDuck(loc: CGPoint(x: node.position.x + leftRight, y: node.position.y + upDown), id: String(node.name!.suffix(1)))
                            node.alpha = 0
                        } else if node.name == "Option3" {
                            self.addDuck(loc: CGPoint(x: node.position.x + leftRight, y: node.position.y + upDown), id: String(node.name!.suffix(1)))
                            node.alpha = 0
                        } else if node.name == "Option4" {
                            self.addDuck(loc: CGPoint(x: node.position.x + leftRight, y: node.position.y + upDown), id: String(node.name!.suffix(1)))
                            node.alpha = 0
                        }
                        
                    }
                }
                
                else if node.name?.prefix(7) == "Upgrade" {
                    if node.contains(location) {
                        if node.alpha == 0 {
                            print("Upgrade button does not exist")
                            return
                        }
                        let nodeIDNum = node.name!.suffix(1)
                        var i = 0
                        while i < self.currentDucks.count {
                            if self.currentDucks[i].sprite.name?.suffix(1) == nodeIDNum {
                                self.currentDucks[i] = self.upgradeDuck(duck: self.currentDucks[i], label: self.upgradeLabels[Int(nodeIDNum)!])
                            }
                            
                            
                            i += 1
                        }
                        
                    }
                }
                else if node.name?.prefix(4) == "Duck" {
                    if node.contains(location) {
                        for ducks in self.currentDucks {
                            if ducks.sprite.name!.suffix(1) == node.name?.suffix(1) {
                                self.showUpgrades(duck: ducks)
                            }
                        }
                        
                    }
                }
                else if node.name?.prefix(8) == "VarToast" {
                    if node.contains(location) {
                        if self.currentMoney >= self.variantCost {
                            let idNUM = node.name?.suffix(1)
                            let idINT : Int = Int(idNUM ?? "")!
                            for duck in self.currentDucks {
                                if duck.sprite.name?.suffix(1) == idNUM && !self.isSpecialized[idINT] {
                                    duck.sprite.removeFromParent()
                                    //self.isSpecialized[idINT] = true
                                    self.addToaster(loc: CGPoint(x: node.position.x - self.frame.width/9 , y: node.position.y - self.frame.height/9.5) , id: ("Toaster" + idNUM!))
                                    node.name! = "UpToast\(idNUM!)"
                                    
                                    for label in self.variantLabels {
                                        if label.name! == "LabelToaster\(duck.sprite.name!.suffix(1))" {
                                            self.updateLabel(label:  label, duck: duck)
                                            
                                        }
                                    var i = 0
                                    while i < self.upgradeLabels.count {
                                        if self.upgradeLabels[i].name!.suffix(1) == idNUM {
                                            self.upgradeLabels[i].removeFromParent()
                                        }
                                        if self.currentButtons[i].sprite.name!.prefix(7) == "Upgrade" && self.currentButtons[i].sprite.name!.suffix(1) == idNUM {
                                            self.currentButtons[i].sprite.removeFromParent()
                                        }
                                        i += 1
                                    }
                                        var j = 0
                                            while j < self.variantSprites.count{
                                                if self.variantSprites[j].name! == "VarBaguette\(idNUM!)" {
                                                    self.variantSprites[j].removeFromParent()
                                                    self.variantSprites.remove(at: j)
                                                }
                                                j += 1
                                            }
                                   
                                        
                                    }
                                    
                                    
                                }
                            }
                        }
                    }
                    
                    
                } else if node.name?.prefix(7) == "UpToast" {
                    if node.contains(location) {
                        let nodeIDNum = node.name!.suffix(1)
                        var i = 0
                        while i < self.currentDucks.count {
                            if self.currentDucks[i].sprite.name?.suffix(1) == nodeIDNum {
                                var j = 0
                                var labelIndex = 0
                                while j < self.variantLabels.count {
                                    if self.variantLabels[j].name?.suffix(1) == nodeIDNum {
                                        labelIndex = j
                                    }
                                    
                                    j += 1
                                }
                                self.currentDucks[i] = self.upgradeDuck(duck: self.currentDucks[i], label: self.variantLabels[labelIndex])
                            }
                            
                            
                            i += 1
                        }
                    }
                } else if node.name?.prefix(11) == "VarBaguette" {
                    if node.contains(location) {
                        if self.currentMoney >= self.variantCost {
                            let idNUM = node.name?.suffix(1)
                            let idINT : Int = Int(idNUM ?? "")!
                            for duck in self.currentDucks {
                                if duck.sprite.name?.suffix(1) == idNUM && !self.isSpecialized[idINT] {
                                    duck.sprite.removeFromParent()
                                    //self.isSpecialized[idINT] = true
                                    self.addBaguette(loc: CGPoint(x: node.position.x - self.frame.width/9 , y: node.position.y + self.frame.height/9.5) , id: ("Baguette" + idNUM!))
                                    node.name! = "UpBaguette\(idNUM!)"
                                    
                                    for label in self.variantLabels {
                                        if label.name! == "LabelToaster\(duck.sprite.name!.suffix(1))" {
                                            self.updateLabel(label:  label, duck: duck)
                                            
                                        }
                                    var i = 0
                                    while i < self.upgradeLabels.count {
                                        if self.upgradeLabels[i].name!.suffix(1) == idNUM {
                                            self.upgradeLabels[i].removeFromParent()
                                        }
                                        if self.currentButtons[i].sprite.name!.prefix(7) == "Upgrade" && self.currentButtons[i].sprite.name!.suffix(1) == idNUM {
                                            self.currentButtons[i].sprite.removeFromParent()
                                        }
                                        i += 1
                                    }
                                    var j = 0
                                        while j < self.variantSprites.count{
                                            if self.variantSprites[j].name! == "VarToast\(idNUM!)" {
                                                self.variantSprites[j].removeFromParent()
                                                self.variantSprites.remove(at: j)
                                            }
                                            j += 1
                                        }
                                        
                                        
                                    }
                                    
                                    
                                }
                            }
                        }
                    }
                } else if node.name?.prefix(10) == "UpBaguette" {
                    if node.contains(location) {
                        
                        let nodeIDNum = node.name!.suffix(1)
                        var i = 0
                        while i < self.currentDucks.count {
                            if self.currentDucks[i].sprite.name?.suffix(1) == nodeIDNum {
                                var j = 0
                                var labelIndex = 0
                                while j < self.variantLabels.count {
                                    if self.variantLabels[j].name?.suffix(1) == nodeIDNum {
                                        labelIndex = j
                                    }
                                    
                                    j += 1
                                }
                               // print (node.name!)
                                //print (self.currentDucks[i].sprite.name! + " leveled up")
                                self.currentDucks[i] = self.upgradeDuck(duck: self.currentDucks[i], label: self.variantLabels[labelIndex])
                            }
                            
                            
                            i += 1
                        }
                    }
                }
                
            })
            
            //Checks if there is a duck at where you tapped.
            for duck in duckInfo {
                if location.x >= duck.0.position.x - 20 && location.x <= duck.0.position.x + 20 && location.y >= duck.0.position.y - 20 && location.y <= duck.0.position.y + 20 {
                    
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
 
    func addNest(location: CGPoint, isWater: Bool) {
        let posScale = CGFloat(60)
        
        //Make the actual nest
        let nest: SKSpriteNode
        if isWater {
            nest = SKSpriteNode(imageNamed: "InnerTube")
            nest.size = CGSize(width: nest.size.width/(self.frame.width/250), height: nest.size.height/(self.frame.width/250))
        } else {
            nest = SKSpriteNode(imageNamed: "Nest")
            nest.size = CGSize(width: nest.size.width/(self.frame.width/45), height: nest.size.height/(self.frame.width/45))
        }
        nest.position = location
        nest.name = "Nest\(nestIDX)"
        
        nest.zPosition = 2
        
        //Add the buttons for upgrades or ducks at a specified location above the nest.
        addOptions(loc: CGPoint(x: nest.position.x, y: nest.position.y + posScale),pB: nest.name!, id: "Option\(nest.name!.suffix(1))");
        
        addChild(nest)
        currentNests.append(Nests(loc: nest.position, sprite: nest, nestNumber: nestIDX))
        nestIDX += 1
    }
    
    func addOptions(loc: CGPoint, pB: String, id: String){
        let heightScale = CGFloat(900)
        
        let option = SKSpriteNode(imageNamed: "breadcrumbIcon")
        option.name = id
        option.position = loc
        option.zPosition = 2
        option.alpha = 0
        option.size = CGSize(width: option.size.width/(self.frame.width/heightScale), height: option.size.height/(self.frame.width/heightScale))
        
        let label = SKLabelNode()
        label.name = "Label\(id.suffix(1))"
        label.fontColor = .black
        label.text = "$100"
        label.position = CGPoint(x: loc.x, y: loc.y + 20)
        label.fontSize = CGFloat(20)
        
        addChild(option)
        addChild(label)
        currentButtons.append(Buttons(loc: option.position, sprite: option, isPresent: true, parentButton: pB))
        upgradeLabels.append(label)
        
    }
    
    func addVariantBranch(loc: CGPoint, id: String) {
        let toast = SKSpriteNode(imageNamed: "toastIcon")
        let toastScale: CGFloat = 900
        toast.name = "VarToast" + id
        toast.position = CGPoint(x: loc.x, y: loc.y + 40)
        toast.zPosition = 2
        toast.alpha = 1
        toast.size = CGSize(width: toast.size.width/(self.frame.width/toastScale), height: toast.size.height/(self.frame.width/toastScale))
        
        let baguette = SKSpriteNode(imageNamed: "baguetteIcon")
        let bagScale: CGFloat = 900
        baguette.name = "VarBaguette" + id
        baguette.position = CGPoint(x: loc.x, y: loc.y - 20)
        baguette.zPosition = 2
        baguette.alpha = 1
        baguette.size = CGSize(width: baguette.size.width/(self.frame.width/bagScale), height: baguette.size.height/(self.frame.width/bagScale))
        
        
        let label = SKLabelNode()
        label.fontColor = .black
        label.text = "$" + String(variantCost)
        label.name = "LabelVariant\(id.suffix(1))"
        label.position = CGPoint(x: loc.x, y: loc.y)
        label.fontSize = CGFloat(20)
        
        addChild(toast)
        addChild(label)
        print(label.name!)
        addChild(baguette)
        
        variantSprites.append(toast)
        variantSprites.append(baguette)
        variantLabels.append(label)
    }
    
    func addDuck(loc: CGPoint, id: String) {
        
        //Only allows a duck to be placed if player has enough money and subtracts that money from their total
        if (self.currentMoney >= duckCost) {
            self.currentMoney -= duckCost
            self.moneyLabel.text = "$: " + String(self.currentMoney)
        } else {
            return
        }
        //Makes a duck
        let duck = SKSpriteNode(imageNamed: "BasicDuckFullBody")
        duck.position = loc
        duck.size = CGSize(width: duck.size.width/(self.frame.width/50), height: duck.size.height/(self.frame.width/50))
        duck.name = "Duck" + id
        duck.zPosition = 3
        
        // Detection Circle to detect Geese that are close
        let detectionCircle = SKShapeNode(circleOfRadius: 100)
        detectionCircle.physicsBody = SKPhysicsBody(circleOfRadius: 80)
        detectionCircle.position = duck.position
        detectionCircle.fillColor = .cyan
        detectionCircle.physicsBody?.affectedByGravity = false
        detectionCircle.name = "DetectionCircle" + id
        detectionCircle.alpha = 0.1
        detectionCircle.physicsBody?.isDynamic = true
        
        //Collisions:
        //The circle is a type of detection.
        detectionCircle.physicsBody?.categoryBitMask = PhysicsCategory.detection
        
        //Do we want it to BOUNCE off things? We don't want the detection circle to collide with anything, so we set it to none.
        detectionCircle.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        //DETECTIONS between objects; does not have an effect on if an object will or can bounce off one another or COLLIDE? Since we want the detection circle to detect geese or any enemy that are in the circle, we put the category "enemy" in.
        detectionCircle.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        
        let newDuck = Ducks(canFire: true, sprite: duck, damage: damageCalc(currentLvl: 1, duckType: "Crumb"), level: 1, upgradeCost: upgradeCostCalc(currentLvl: 1, duckType: "Crumb"), cooldownDelay: 0.6, duckType: "Crumb")
        currentDucks.append(newDuck)
        
        duckIDX+=1
        //Adds duck to current list of ducks
        duckInfo.append((duck, detectionCircle))
        addChild(detectionCircle)
        addChild(duck)
        
        updateLabel(label: upgradeLabels[Int(id)!], duck: newDuck)
        
    }
    
    func addToaster (loc: CGPoint, id: String) {
        if (self.currentMoney >= variantCost) {
            self.currentMoney -= variantCost
            self.moneyLabel.text = "$: " + String(self.currentMoney)
        } else {
            return
        }
        
        let sizeScale: CGFloat = 60
        let toaster = SKSpriteNode (imageNamed: "ToasterDuck")
        toaster.size = CGSize(width: toaster.size.width/(self.frame.width/sizeScale), height: toaster.size.height/(self.frame.width/sizeScale))
        toaster.position = loc
        toaster.name = id
        toaster.zPosition = 3
        toaster.alpha = 1
        
        
        addChild(toaster)
        let newToaster = Ducks(canFire: true, sprite: toaster, damage: damageCalc(currentLvl: 4, duckType: "Toast"), level: 4, upgradeCost: upgradeCostCalc(currentLvl: 4, duckType: "Toast"), cooldownDelay: 0.3, duckType: "Toast")
        
        var i = 0
        while i < currentDucks.count {
            if currentDucks[i].sprite.name?.suffix(1) == toaster.name?.suffix(1) {
                currentDucks[i] = newToaster
            }
            
            i += 1
        }
        
        var j = 0
        while j < variantLabels.count {
            if variantLabels[j].name?.suffix(1) == toaster.name?.suffix(1) {
                updateLabel(label: variantLabels[j], duck: newToaster)
            }
            j += 1
        }
    }
    
    func addBaguette (loc: CGPoint, id: String) {
        if (self.currentMoney >= variantCost) {
            self.currentMoney -= variantCost
            self.moneyLabel.text = "$: " + String(self.currentMoney)
        } else {
            return
        }
        
        let sizeScale: CGFloat = 600
        let baguette = SKSpriteNode (imageNamed: "BaguetteDuck")
        baguette.size = CGSize(width: baguette.size.width/(self.frame.width/sizeScale), height: baguette.size.height/(self.frame.width/sizeScale))
        baguette.position = loc
        baguette.name = id
        baguette.zPosition = 3
        baguette.alpha = 1
        
        
        addChild(baguette)
        let newBaguette = Ducks(canFire: true, sprite: baguette, damage: damageCalc(currentLvl: 4, duckType: "Baguette"), level: 4, upgradeCost: upgradeCostCalc(currentLvl: 4, duckType: "Baguette"), cooldownDelay: 1.5, duckType: "Baguette")
        
        var i = 0
        while i < currentDucks.count {
            if currentDucks[i].sprite.name?.suffix(1) == baguette.name?.suffix(1) {
                currentDucks[i] = newBaguette
            }
            
            i += 1
        }
        
        var j = 0
        while j < variantLabels.count {
            if variantLabels[j].name?.suffix(1) == baguette.name?.suffix(1) {
                updateLabel(label: variantLabels[j], duck: newBaguette)
            }
            j += 1
        }
    }
    
    
    func addGoose(health: Int, speed: Double) {  // Goose Spawner
        
      // Create sprite
      let goose = SKSpriteNode(imageNamed: "BasicGooseFullBody")
        goose.size = CGSize(width: goose.size.width/(self.frame.width/65), height: goose.size.height/(self.frame.width/65))
        goose.physicsBody = SKPhysicsBody(circleOfRadius: goose.size.width - 25)
        goose.zPosition = 1
        goose.physicsBody?.affectedByGravity = false
        
        goose.name = "enemy"
        goose.physicsBody?.isDynamic = true

        //Collisions
        goose.physicsBody?.categoryBitMask = PhysicsCategory.enemy //Goose is a type of enemy
        goose.physicsBody?.collisionBitMask = PhysicsCategory.none //We want the breadcrumb to look like it's bouncing off of the goose, so we put projectile in for collisionBitMask
        goose.physicsBody?.contactTestBitMask = PhysicsCategory.projectile | PhysicsCategory.detection// We also want the goose to detect if it has been hit by a breadcrumb, not only just bouncing it off. In addition, we want the detection circle to detect if a goose is in its radius, so we add that too.

        goose.position = CGPoint(x: self.frame.width/8.75, y: self.frame.height/1.05)
      
      // Add the goose to the scene
      addChild(goose)
        let goose1 = Gooses(health : CGFloat(health), sprite: goose)
        currentGeese.append(goose1)
        
      
        let gooseSpeed = speed
      
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
                   // let NewGameOver = self.storyboard?.instantiateViewController(withIdentifier: "NewGameOver") as! NewGameOver

                  //  self.navigationController.pushViewController(NewGameOver, animated: true)
                    //self.performSegueWithIdentifier("toGameOver", sender: nil)
                    let gameOverScene = SKScene(fileNamed: "GameOver")
                     gameOverScene!.scaleMode = .aspectFill
                   self.view?.presentScene(gameOverScene)
                    
                }
             }
             
            ])

      goose.run(SKAction.sequence([firstMove,secondMove,thirdMove, fourthMove, fifthMove, finalAction]))
    }
    
    
    func addDemon(hp: CGFloat){
        let demon = SKSpriteNode(imageNamed: "DemonGoose")
        demon.size = CGSize(width: demon.size.width/(self.frame.width/75), height: demon.size.height/(self.frame.width/75))
        demon.physicsBody = SKPhysicsBody(circleOfRadius: demon.size.width - 25)
        demon.zPosition = 1
        demon.physicsBody?.affectedByGravity = false
        
        demon.name = "enemy"
        demon.physicsBody?.isDynamic = true

        //Collisions
        demon.physicsBody?.categoryBitMask = PhysicsCategory.enemy //Goose is a type of enemy
        demon.physicsBody?.collisionBitMask = PhysicsCategory.none //We want the breadcrumb to look like it's bouncing off of the goose, so we put projectile in for collisionBitMask
        demon.physicsBody?.contactTestBitMask = PhysicsCategory.projectile | PhysicsCategory.detection// We also want the goose to detect if it has been hit by a breadcrumb, not only just bouncing it off. In addition, we want the detection circle to detect if a goose is in its radius, so we add that too.

        demon.position = CGPoint(x: self.frame.width/8.75, y: self.frame.height/1.05)
        
        addChild(demon)
        let newDemon = Gooses(health : hp, sprite: demon)
        currentGeese.append(newDemon)
        
        
        let gooseSpeed = 0.5
        
        let firstMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/8.75, y: self.frame.height/2.82),duration: TimeInterval((320.0/250.0)/gooseSpeed)),
            SKAction.run {demon.zRotation = CGFloat(Double.pi/2.0)}
        ])
            
        let secondMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/3.3, y: self.frame.height/2.82), duration: TimeInterval((250.0/250.0)/gooseSpeed)),
            SKAction.run {demon.zRotation = CGFloat(Double.pi)}])
        
        let thirdMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/3.3, y: self.frame.height/1.30), duration: TimeInterval((245.0/250.0)/gooseSpeed)),
            SKAction.run {demon.zRotation = CGFloat(Double.pi/2.0)}])
        
        let fourthMove = SKAction.sequence([ SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/1.30), duration: TimeInterval((685.0/250.0)/gooseSpeed)),
            SKAction.run {demon.zRotation = CGFloat(Double.pi * 0)}])
        
        let fifthMove = SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/5), duration: TimeInterval((320.0/250.0)/gooseSpeed))
        
        let finalAction = SKAction.sequence(
            [SKAction.run {self.remainingLives -= 5},
             SKAction.run{self.healthLabel.text = "Remaining Lives:  " + String(self.remainingLives)},
             SKAction.removeFromParent(),
             SKAction.run {
                if self.remainingLives <= 0 {
                  
                    
                    let gameOverScene = SKScene(fileNamed: "GameOver")
                    self.view?.presentScene(gameOverScene)
                    
                }
             }
            ])

      demon.run(SKAction.sequence([firstMove,secondMove,thirdMove, fourthMove, fifthMove, finalAction]))
    }
    
    func addTuff(hp: CGFloat){
        let tuff = SKSpriteNode(imageNamed: "TuffGoose2")
        tuff.size = CGSize(width: tuff.size.width/(self.frame.width/150), height: tuff.size.height/(self.frame.width/150))
        tuff.physicsBody = SKPhysicsBody(circleOfRadius: tuff.size.width - 25)
        tuff.zPosition = 1
        tuff.physicsBody?.affectedByGravity = false
        
        tuff.name = "enemy"
        tuff.physicsBody?.isDynamic = true

        //Collisions
        tuff.physicsBody?.categoryBitMask = PhysicsCategory.enemy //Goose is a type of enemy
        tuff.physicsBody?.collisionBitMask = PhysicsCategory.none //We want the breadcrumb to look like it's bouncing off of the goose, so we put projectile in for collisionBitMask
        tuff.physicsBody?.contactTestBitMask = PhysicsCategory.projectile | PhysicsCategory.detection// We also want the goose to detect if it has been hit by a breadcrumb, not only just bouncing it off. In addition, we want the detection circle to detect if a goose is in its radius, so we add that too.

        tuff.position = CGPoint(x: self.frame.width/8.75, y: self.frame.height/1.05)
        
        addChild(tuff)
        let newTuff = Gooses(health : hp, sprite: tuff)
        currentGeese.append(newTuff)
        
        
        let gooseSpeed = 0.5
        
        let firstMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/8.75, y: self.frame.height/2.82),duration: TimeInterval((320.0/250.0)/gooseSpeed)),
            SKAction.run {tuff.zRotation = CGFloat(Double.pi/2.0)}
        ])
            
        let secondMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/3.3, y: self.frame.height/2.82), duration: TimeInterval((250.0/250.0)/gooseSpeed)),
            SKAction.run {tuff.zRotation = CGFloat(Double.pi)}])
        
        let thirdMove = SKAction.sequence([
            SKAction.move(to: CGPoint(x: self.frame.width/3.3, y: self.frame.height/1.30), duration: TimeInterval((245.0/250.0)/gooseSpeed)),
            SKAction.run {tuff.zRotation = CGFloat(Double.pi/2.0)}])
        
        let fourthMove = SKAction.sequence([ SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/1.30), duration: TimeInterval((685.0/250.0)/gooseSpeed)),
            SKAction.run {tuff.zRotation = CGFloat(Double.pi * 0)}])
        
        let fifthMove = SKAction.move(to: CGPoint(x: self.frame.width/1.08, y: self.frame.height/5), duration: TimeInterval((320.0/250.0)/gooseSpeed))
        
        let finalAction = SKAction.sequence(
            [SKAction.run {self.remainingLives -= 3},
             SKAction.run{self.healthLabel.text = "Remaining Lives:  " + String(self.remainingLives)},
             SKAction.removeFromParent(),
             SKAction.run {
                if self.remainingLives <= 0 {
                  
                    
                    let gameOverScene = SKScene(fileNamed: "GameOver")
                    self.view?.presentScene(gameOverScene)
                    
                }
             }
            ])

        tuff.run(SKAction.sequence([firstMove,secondMove,thirdMove, fourthMove, fifthMove, finalAction]))
    }

    /* -------------------- ACTIONS -------------------- */
    func launchBreadcrumb (startPoint: CGPoint, endPoint: CGPoint, duck: Ducks) -> breadcrumb {
        var crumb = SKSpriteNode()
        if duck.duckType == "Toast" {
             crumb = SKSpriteNode (imageNamed: "toast")
        } else if duck.duckType == "Baguette"{
             crumb = SKSpriteNode (imageNamed: "baguette")
        } else {
             crumb = SKSpriteNode (imageNamed: "breadcrumb")
        }
        crumb.size = CGSize(width: 30, height: 30)
        crumb.position = startPoint
        crumb.zPosition = 3
        crumb.name = "projectile"
        crumb.physicsBody = SKPhysicsBody(circleOfRadius: 1)
        crumb.physicsBody?.usesPreciseCollisionDetection = true
        crumb.physicsBody?.affectedByGravity = false
        crumb.physicsBody?.isDynamic = true
        crumb.physicsBody?.categoryBitMask = PhysicsCategory.projectile //Breadcrumb is type projectile
        crumb.physicsBody?.collisionBitMask = PhysicsCategory.none //We want the breadcrumb to bounce off the goose
        crumb.physicsBody?.contactTestBitMask = PhysicsCategory.enemy //We want to detect when the breadcrumb touches the goose
        
        let rotation = CGFloat (random(min: 0, max: CGFloat( 2.0 * Double.pi)))
        
        crumb.zRotation = rotation
        addChild(crumb)
        crumb.run(SKAction.sequence([SKAction.move(to: endPoint, duration: 0.2), SKAction.removeFromParent()]))
        return breadcrumb(damage: duck.damage, sprite : crumb)
        
       
    }
    
    func upgradeCostCalc(currentLvl: Int, duckType: String) -> Int{
        if duckType == "Crumb" {
            return (100 * currentLvl) + (50 * currentLvl * currentLvl)
        } else if duckType == "Toast" {
            return (50 * currentLvl) + (50 * currentLvl * currentLvl)
        } else if duckType == "Baguette" {
            return (200 * currentLvl) + (5 * currentLvl * currentLvl * currentLvl)
        }
        
        return 0
    }
    
    func damageCalc(currentLvl: Int, duckType: String) -> CGFloat{
        if duckType == "Crumb" {
            return CGFloat((10 * currentLvl) + (20 * currentLvl * currentLvl))
        } else if duckType == "Toast" {
            return CGFloat((5 * currentLvl) + (20 * currentLvl * currentLvl))
        } else if duckType == "Baguette" {
            return CGFloat((25 * currentLvl) + (10 * currentLvl * currentLvl * currentLvl))
        }
        
        return 0
    }
    
    func updateLabel(label: SKLabelNode, duck: Ducks) {
        if duck.duckType == "Crumb" {
            if duck.level < 5{
                label.text = "$\(duck.upgradeCost)"
            } else {
                label.text = "Max level"
                addVariantBranch(loc: CGPoint(x: duck.sprite.position.x + 75, y: duck.sprite.position.y), id: String(duck.sprite.name!.suffix(1)))
            }
        } else {
            if duck.level < 10{
                label.text = "$\(duck.upgradeCost)"
            } else {
                label.text = "Max level"
            }
        }
    }
    
    func addMoney(money: Int) -> SKAction {
        return SKAction.run{
        self.currentMoney += money
        self.moneyLabel.text = "$: \(self.currentMoney)"
        }
    }
    
    func upgradeDuck(duck: Ducks, label: SKLabelNode) -> Ducks{
        if self.currentMoney < duck.upgradeCost{
            print ("Not enough money to upgrade.")
            return duck
        } else if (duck.duckType == "Crumb" && duck.level >= 5) || (duck.level >= 10){
            print ("This duck is max level")
            return duck
        } else {
            self.currentMoney -= duck.upgradeCost
            self.moneyLabel.text = "$: " + String(self.currentMoney)
            var newDuck = duck
            newDuck.level = duck.level + 1
            newDuck.upgradeCost = upgradeCostCalc(currentLvl: newDuck.level, duckType: duck.duckType)
            newDuck.damage = damageCalc(currentLvl: newDuck.level, duckType: duck.duckType)
            updateLabel(label: label, duck: newDuck)
            return newDuck
            
        }
    }
    
    
    
    /* -------------------- HANDLERS -------------------- */
     //Used for the detection circle to indicate whether or not a goose has entered the "bread" zone
    //NOTE: This is where you can get the geese's position as well.
    func detectionHandler(circle: SKShapeNode, goose: SKSpriteNode, duck: SKSpriteNode){

       // print (circle.name!)
        //print (duck.name!)
        let distanceX = duck.position.x - goose.position.x
        let distanceY = duck.position.y - goose.position.y
        if distanceY >= 0 {
            duck.zRotation = CGFloat(2 * Double.pi - atan(Double(distanceX/distanceY))) //If duck is above or equal to goose
        } else {
            duck.zRotation = CGFloat(Double.pi - atan(Double(distanceX/distanceY))) //If duck is below goose
        }
        
        //Cooldown
        var i = 0
        while i < currentDucks.count {
             //print(i)
            //Check for the duck that is associated with the detection circle that was triggered.
            if currentDucks[i].sprite.name!.suffix(1) == duck.name!.suffix(1) {
                //print(currentDucks[i].sprite.name! + " canFire = " + String(currentDucks[i].canFire))
               // print(i)
                
                if currentDucks[i].canFire  == false {
                    //If there is a cooldown, do nothing.
                    //return
                }
                       
                else if currentDucks[i].canFire {
                    //If there is not a cooldown, shoot the breadcrumb, wait for 2 seconds, and set cooldown back to false.
                    //print("Firing cooldown sequence" + String(i))
                    run (self.cooldownManager(i: i, circle: circle, duck: duck, goose: goose))
                    
                }
                
            }
            
            i += 1
        }
        i = 0
        
    }
    

    //Used to actually deal damage to the goose if the breadcrumbs collide with a goose.
    func collisionHandler(proj: SKSpriteNode, enemy: SKSpriteNode, dmg: CGFloat) {
       var i = 0
        while (i < currentGeese.count) {
            if currentGeese[i].sprite == enemy {
                currentGeese[i].health -= dmg
                //print ("Dealt " + String(Int(dmg)))
                if currentGeese[i].health <= 0 {
                    enemy.removeFromParent()
                    self.currentMoney += gooseReward
                    self.moneyLabel.text = "$: " + String(self.currentMoney)
                }
            }
            i += 1
        }
        proj.removeFromParent()
        
    }
    
    func cooldownManager(i: Int, circle: SKShapeNode, duck: SKSpriteNode, goose: SKSpriteNode) -> SKAction{
        SKAction.sequence([
        
            SKAction.run{
                //print(self.currentDucks[i].sprite.name! + " is firing")
                //print("i is: " + String(i))
                self.currentCrumb = self.launchBreadcrumb(startPoint: circle.position, endPoint: goose.position, duck: self.currentDucks[i])
            //print(self.currentDucks[Int(duck.name!.suffix(1))!].name + " is going to be set to false")
            
            //self.currentDucks[Int(duck.name!.suffix(1))!].canFire = false
                var j = 0
                while j < self.currentDucks.count {
                    if self.currentDucks[j].sprite.name!.suffix(i) == duck.name!.suffix(1) {
                        self.currentDucks[j].canFire = false
                    }
                    j+=1
                }
                j=0
            },
            SKAction.wait(forDuration: self.currentDucks[i].cooldownDelay),
            SKAction.run{
                
                //self.currentDucks[Int(duck.name!.suffix(1))!].canFire = true
                var j = 0
                while j < self.currentDucks.count {
                    if self.currentDucks[j].sprite.name!.suffix(i) == duck.name!.suffix(1) {
                        self.currentDucks[j].canFire = true
                    }
                    j+=1
                }
                j=0
                
            }
            
        ])
    }
    /* -----------------WAVE CREATION --------------  */
    
    
    //Adds a series of geese with number "amt" and waits for "gap" seconds between each goose. All geese in the series will have health of "hp" and move at speed "spd"
    public func gooseSeries(amt: Int, gap: Double, hp: Int, spd: Double) -> SKAction {
       // SKAction.repeat(SKAction.sequence([SKAction.run(addGoose(health: hp, speed: spd)), SKAction.wait(forDuration: gap)]), count: amt)
        let gooseWait = SKAction.sequence([
        SKAction.run {
            self.addGoose(health: hp, speed: spd)
        },
        SKAction.wait(forDuration: gap),
        ])
        return SKAction.sequence([
            SKAction.repeat(gooseWait, count: amt),
            SKAction.wait(forDuration: 0.1)
        
        ])
            
    }
    //Puts all waves in order with a set delay between each one
    func waveSequence() -> SKAction{
        let waveDelay : TimeInterval = 3.0
           return SKAction.sequence([
           wave1(),
           SKAction.wait(forDuration: waveDelay),
           addMoney(money: 75),
           wave2(),
           SKAction.wait(forDuration: waveDelay),
           addMoney(money: 75),
           wave3(),
           SKAction.wait(forDuration: waveDelay),
           addMoney(money: 75),
           wave4(),
           SKAction.wait(forDuration: waveDelay),
           addMoney(money: 75),
           wave5(),
           SKAction.wait(forDuration: waveDelay),
           addMoney(money: 100),
           wave6(),
           SKAction.wait(forDuration: 15.0),
           victoryScreen()
           
        
        ])
    }
    
    func endlessMode() -> SKAction{
         SKAction.sequence([
            wave1(),
            SKAction.wait(forDuration: 3.0),
            addMoney(money: 75),
            multiWave(i: 2),
            multiWave(i: 3),
            multiWave(i: 4),
            multiWave(i: 5),
            SKAction.run{self.addTuff(hp: 500)},
            multiWave(i: 6),
            multiWave(i: 7),
            multiWave(i: 8),
            multiWave(i: 9),
            multiWave(i: 10),
            SKAction.run{self.addDemon(hp: 1000)},
            SKAction.wait(forDuration: 30.0),
            victoryScreen()
        ])
        
        
   
    }
    
    func multiWave(i: Int) -> SKAction{
        SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            waveGenerator(difficulty: 1 + i/5, waveNum: i)
            
        ])
    }
    
    //The individual geese spawn commands for each wave for easy customization
    func wave1() -> SKAction{
        SKAction.sequence([
            SKAction.run {
                self.waveLabel.text = "Wave 1"
            },
            gooseSeries(amt: 1, gap: 1.5, hp: 10, spd: 1.0),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 3, gap: 1.0, hp : 10, spd: 1.1),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 2, gap: 0.4, hp : 50, spd: 1.3)
        ])
    }
    
    func wave2() -> SKAction{
       
        SKAction.sequence([
            SKAction.run {
                self.waveLabel.text = "Wave 2"
            },
            gooseSeries(amt: 1, gap: 1.0, hp: 75, spd: 1.0),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 2, gap: 1.0, hp : 100, spd: 1.3),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 1, gap: 0.5, hp : 200, spd: 1.5)
        ])
    }
    
    func wave3() -> SKAction{
       
        SKAction.sequence([
            SKAction.run {
                self.waveLabel.text = "Wave 3"
            },
            gooseSeries(amt: 1, gap: 0.7, hp: 100, spd: 1.3),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 2, gap: 0.7, hp : 300, spd: 1.3),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 2, gap: 1.0, hp : 275, spd: 1.5)
        ])
    }
    
    func wave4() -> SKAction{
       
        SKAction.sequence([
            SKAction.run {
                self.waveLabel.text = "Wave 4"
            },
            gooseSeries(amt: 1, gap: 0.5, hp: 400, spd: 1.3),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 1, gap: 0.8, hp : 550, spd: 1.3),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 2, gap: 1.0, hp : 675, spd: 1.0)
        ])
    }
    
    func wave5() -> SKAction{
       
        SKAction.sequence([
            SKAction.run {
                self.waveLabel.text = "Wave 5"
            },
            gooseSeries(amt: 1, gap: 0.4, hp: 700, spd: 1.3),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 2, gap: 0.6, hp : 775, spd: 1.7),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 2, gap: 0.5, hp : 850, spd: 1.5),
            SKAction.wait(forDuration: 0.1),
            SKAction.run{self.addTuff(hp: 1200)}
        ])
    }
    
    func wave6() -> SKAction{
        SKAction.sequence([
            SKAction.run {
                self.waveLabel.text = "Wave 6"
            },
            gooseSeries(amt: 10, gap: 0.4, hp: 1000, spd: 1.3),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 20, gap: 0.6, hp : 1200, spd: 1.7),
            SKAction.wait(forDuration: 0.1),
            gooseSeries(amt: 30, gap: 0.3, hp : 1200, spd: 1.5),
        ])
    }
    
    func waveGenerator(difficulty: Int, waveNum: Int) -> SKAction {
        SKAction.sequence([
            SKAction.run {
                self.waveLabel.text = "Wave \(waveNum)"
                print("Wave \(waveNum)" + " \(difficulty)")
            },
            SKAction.repeat(gooseSeries(amt: difficulty * Int(random(min: 5, max: 10)), gap: Double(random(min: 0.3, max: 1.0)), hp: difficulty * difficulty * Int(random(min: 40, max: 60)), spd: Double(random(min: 0.9, max: 1.7))), count: 2 + difficulty)
            ,
            addMoney(money: 25 + (50 * difficulty)),
            SKAction.wait(forDuration: 3.0)
            
    
    ])
    }
    
    func victoryScreen() -> SKAction{
            
            SKAction.sequence([
                
                SKAction.run {
                    self.waveLabel.text = "The end"
                    let VictoryScene = SKScene(fileNamed: "Victory")
                    VictoryScene?.scaleMode = .aspectFill
                    
                    self.view?.presentScene(VictoryScene)
                },
                ])
            }

}
