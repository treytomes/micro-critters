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
ensureImport "Chunk"
ensureImport "Class"
ensureImport "Dice"
ensureImport "Entity"
ensureImport "Label"
ensureImport "Point"
ensureImport "Race"
ensureImport "Rectangle"
ensureImport "Tile"
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
	display(6).mode = displayMode.tile

	c = Chunk.make(0, 0, 0)
	c.render display(6)

	text.clear
	gfx.clear
	display(4).clear

	globals.entities = []
	globals.worldActions = []

	globals.lastFrameTime = time
	globals.deltaTime = 0
end function


newGame = function
	// The set of animations that makes a "person".
	person = AssetFactory.loadAnimationSet("person")

	globals.player = Entity.make(person)
	player.behaviors.push behaviors.playerInput
	player.moveTo 60, 8
	player.addToDisplay display(4)

	applyRace(player, "human")
	applyClass(player, "fighter")

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


scrollTo = function(entity)
	halfWidth = gfx.width / 2
	halfHeight = gfx.height / 2

	mapWidth = display(6).extent[0] * display(6).cellSize[0]
	mapHeight = display(6).extent[1] * display(6).cellSize[1]

	spriteX = entity.sprite.x + entity.sprite.image.width / 2
	spriteY = entity.sprite.y - entity.sprite.image.height / 2

	if spriteX - halfWidth < 0 then
		scrollX = 0
	else if spriteX > mapWidth - halfWidth then
		scrollX = mapWidth - gfx.width
	else
		scrollX = spriteX - halfWidth
	end if

	if spriteY - halfHeight < 0 then
		scrollY = 0
	else if spriteY > mapHeight - halfHeight then
		scrollY = mapHeight - gfx.height
	else
		scrollY = spriteY - halfHeight
	end if

	display(4).scrollX = scrollX
	display(4).scrollY = scrollY
	display(6).scrollX = scrollX
	display(6).scrollY = scrollY
end function


transitionSouth = function(entity)
	text.clear
	ss = Image.fromScreen
	transitionStartTime = time
	mapHeight = display(6).extent[1] * display(6).cellSize[1]
	y = 0
	display(6).scrollY = mapHeight - y
	// TODO: Load the new tile map data here. 
	while y < gfx.height
		display(6).scrollY = mapHeight - y
		gfx.fillRect 0, 0, gfx.width, y, color.clear
		gfx.drawImage ss, 0, y
		y = (time - transitionStartTime) / SCREEN_TRANSITION_TIME * gfx.height
	end while
	gfx.clear

	tileX = entity.getTileX
	tileY = entity.getTileY
	entity.moveTo tileX, display(6).extent[1] - 1
end function


transitionNorth = function(entity)
	text.clear
	ss = Image.fromScreen
	transitionStartTime = time
	mapHeight = display(6).extent[1] * display(6).cellSize[1]
	height = gfx.height
	display(6).scrollY = -height
	// TODO: Load the new tile map data here. 
	while height >= 0
		display(6).scrollY = -height
		gfx.fillRect 0, height, gfx.width, gfx.height - height, color.clear
		gfx.drawImage ss, 0, 0, gfx.width, height, 0, ss.height - height, gfx.width, height
		height = (1 - (time - transitionStartTime) / SCREEN_TRANSITION_TIME) * gfx.height
	end while
	gfx.clear
	
	tileX = entity.getTileX
	tileY = entity.getTileY
	entity.moveTo tileX, 0
end function


transitionWest = function(entity)
	text.clear
	ss = Image.fromScreen
	transitionStartTime = time
	mapWidth = display(6).extent[0] * display(6).cellSize[0]
	x = 0
	display(6).scrollX = mapWidth - x
	// TODO: Load the new tile map data here. 
	while x < gfx.width
		display(6).scrollX = mapWidth - x
		gfx.fillRect 0, 0, x, gfx.height, color.clear
		gfx.drawImage ss, x, 0
		x = (time - transitionStartTime) / SCREEN_TRANSITION_TIME * gfx.width
	end while
	gfx.clear

	tileX = entity.getTileX
	tileY = entity.getTileY
	entity.moveTo display(6).extent[0] - 1, tileY
end function


transitionEast = function(entity)
	text.clear
	ss = Image.fromScreen
	transitionStartTime = time
	mapWidth = display(6).extent[0] * display(6).cellSize[0]
	width = gfx.width
	display(6).scrollX = -width
	// TODO: Load the new tile map data here. 
	while width >= 0
		display(6).scrollX = -width
		gfx.fillRect width, 0, gfx.width - width, gfx.height, color.clear
		gfx.drawImage ss, 0, 0, width, gfx.height, ss.width - width, 0, width, gfx.height
		width = (1 - (time - transitionStartTime) / SCREEN_TRANSITION_TIME) * gfx.width
	end while
	gfx.clear

	tileX = entity.getTileX
	tileY = entity.getTileY
	entity.moveTo 0, tileY
end function


main = function
	// boredTimerLabel = Label.make("bored timer: {value}", 25, 0, 20)
	// isBoredLabel = Label.make("is bored: {value}", 24, 0, 15)
	// energyLabel = Label.make("energy: {value}", 23, 0, 15)
	positionLabel = Label.make("player: {0},{1}", 25, 0, 15)

	isDone = false
	while not isDone
		if key.pressed("escape") then
			isDone = true
		end if

		// boredTimerLabel.draw({ "value": entities[0].behaviors[0].boredTimer.remainingTime })
		// isBoredLabel.draw({ "value": entities[0].behaviors[0].boredTimer.isTriggered })
		// energyLabel.draw({ "value": entities[0].currentEnergy })
		positionLabel.draw([player.getTileX, player.getTileY])

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
		
		tx = player.getTileX
		ty = player.getTileY
		if tx < 0 then
			transitionWest player
		else if tx >= display(6).extent[0] then
			transitionEast player
		else if ty < 0 then
			transitionSouth player
		else if ty >= display(6).extent[1] then
			transitionNorth player
		else
			scrollTo player
		end if

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
