env.importPaths = [
	"/sys/lib",
	"./src",
]


import "importUtil"
import "mathUtil"
import "stringUtil"
import "qa"
import "json"

ensureImport "constants"

ensureImport "actions"
ensureImport "Animation"
ensureImport "AnimationSet"
ensureImport "AssetFactory"
ensureImport "behaviors"
ensureImport "Class"
ensureImport "Dice"
ensureImport "Entity"
ensureImport "Label"
ensureImport "Point"
ensureImport "Race"
ensureImport "Rectangle"
ensureImport "TileSet"
ensureImport "Timer"
ensureImport "WorldAction"


// You *could* think of race and class as external mutators.  If that helps.

applyRace = function(entity, racePath)
	race = AssetFactory.loadRace(racePath)
	race.apply entity
	return entity
end function


applyClass = function(entity, classPath)
	class = AssetFactory.loadClass(classPath)
	class.apply entity
	return entity
end function

initialize = function
	display(5).mode = displayMode.tile
	
	// Build the world tile set.
	tileImages = [
		AssetFactory.loadTile("floor"),
		AssetFactory.loadTile("wall")]
	tileSet = TileSet.fromImages(tileImages)
	display(5).tileSet = tileSet.image
	display(5).tileSetTileSize = [tileSet.tileWidth, tileSet.tileHeight]  // size of each tile in the image
	display(5).cellSize = display(5).tileSetTileSize

	mapWidth = floor(gfx.width / tileSet.tileWidth)
	mapHeight = floor(gfx.height / tileSet.tileHeight)
	display(5).extent = [mapWidth, mapHeight]  // columns, rows on screen

	// Build a simple map.
	display(5).clear 0
	for y in range(0, mapHeight - 1)
		display(5).setCell 0, y, 1
		display(5).setCell mapWidth - 1, y, 1
	end for
	for x in range(0, mapWidth - 1)
		display(5).setCell x, 0, 1
		display(5).setCell x, mapHeight - 1, 1
	end for

	text.clear
	display(4).clear
	
	globals.entities = []
	globals.worldActions = []

	globals.lastFrameTime = time
	globals.deltaTime = 0

	globals.boredTimerLabel = Label.make("bored timer: {value}", 25, 0, 20)
	globals.isBoredLabel = Label.make("is bored: {value}", 24, 0, 15)
	globals.energyLabel = Label.make("energy: {value}", 23, 0, 15)
end function


newGame = function
	// The set of animations that makes a "person".
	person = AssetFactory.loadAnimationSet("person")

	player = Entity.make(person)
	player.behaviors.push behaviors.playerInput
	player.moveTo 8, 8
	player.addToDisplay display(4)

	player = applyRace(player, "human")
	player = applyClass(player, "fighter")

	entities.push player
end function


loadGame = function(path)
	data = json.parse(file.open(path).read)

	n = 0
	while n < len(data.entities)
		e = Entity.fromSerializable(data.entities[n])
		e.addToDisplay display(4)
		entities.push e
		n += 1
	end while
end function


saveGame = function(path)
	data = {}
	data.entities = []
	n = 0
	while n < len(entities)
		e = entities[n]
		data.entities.push e.toSerializable
		
		n += 1
	end while

	file.writeLines path, json.toJSON(data)
end function


main = function
	isDone = false
	while not isDone
		if key.pressed("escape") then
			isDone = true
		end if

		boredTimerLabel.draw({ "value": entities[0].behaviors[0].boredTimer.remainingTime })
		isBoredLabel.draw({ "value": entities[0].behaviors[0].boredTimer.isTriggered })
		energyLabel.draw({ "value": entities[0].currentEnergy })

		// Animation instances are shared globally, so they need a single update path.
		AssetFactory.updateAnimations deltaTime
		
		// First loop to update the entities and build the action queue.
		n = 0
		while n < len(entities)
			e = entities[n]
			globals.worldActions += e.update(deltaTime)
			n += 1
		end while

		// Second loop to flush the action queue.
		while len(worldActions) > 0
			act = worldActions.pop
			act.action.execute act.entity
		end while

		deltaTime = time - lastFrameTime
		lastFrameTime = time
		yield
	end while
end function


initialize

// The environment needs to be basically setup before a game can either be initialized or loaded.
newGame
// loadGame "save.json"

// Start the main loop.
main

// Before end of first iteration, the world state must be serializable.
// This is where we will save the game state.
saveGame "save.json"
