extends Node

signal player_entered

var camera = preload("res://entities/player/camera.tscn").instance()
export var music = ""
export var musicfx = ""
export var light = "default"

func _ready():
	network.current_map = self
	add_child(camera)
	network.map_peers = []
	
	if global.next_entrance == "":
		screenfx.play("fadewhite")
		screenfx.seek(10)
		var entrance_picker = preload("res://ui/main/entrances.tscn").instance()
		add_child(entrance_picker)
		entrance_picker.get_entrances(get_tree().get_nodes_in_group("entrances"))
		yield(entrance_picker, "entrance_chosen")
		entrance_picker.queue_free()
	
	add_new_player(network.pid)
	for player in network.player_list.keys():
		if network.player_list[player] == name:
			add_new_player(player)
	# force the server to acknowledge this player's presence
	network.send_current_map() # starts player list updates
	screenfx.play("fadein")
	connect("player_entered", self, "player_entered")


func _process(delta): # can be on screen change instead of process
	if !network.is_map_host():
		return
	
	var active_zones = []
	var active_enemies = []
	
	for player in get_tree().get_nodes_in_group("player"):
		if !active_zones.has(player.current_zone) && player.current_zone != null:
			active_zones.append(player.current_zone)
	
	for zone in active_zones:
		for enemy in zone.get_enemies():
			active_enemies.append(enemy)
	
	for entity in get_tree().get_nodes_in_group("entity"):
		if entity is Player:
			continue
		if active_enemies.has(entity):
			entity.set_physics_process(true)
		else:
			entity.set_physics_process(false)
			if entity is Enemy:
				entity.position = entity.home_position

func add_new_player(id):
	var new_player = preload("res://entities/player/player.tscn").instance()
	new_player.name = str(id)
	new_player.set_network_master(id, true)
	
	add_child(new_player)
	new_player.camera = camera
	new_player.initialize()
	
	if id == network.pid:
		new_player.sprite.texture = load(global.options.player_data.skin)
		new_player.nametag.text = global.options.player_data.name
	else:
		new_player.sprite.texture = load(network.player_data.get(id).skin)
		new_player.nametag.text = network.player_data.get(id).name

func remove_player(id):
	if has_node(str(id)):
		get_node(str(id)).queue_free()
	for node in get_tree().get_nodes_in_group(str(id)):
		node.queue_free()

func update_puppets():
	var player_nodes = get_tree().get_nodes_in_group("player")
	var player_names = []
	for player in player_nodes:
		# first remove old players
		var id = int(player.name)
		if !network.map_peers.has(int(id)) && id != network.pid:
			remove_player(id)
		
		# add player names to array
		player_names.append(int(player.name))
	
	# match network peers to this new list of names
	for id in network.map_peers:
		if !player_names.has(id): # if there's fewer names than peers
			add_new_player(id) # add a new node for that name

func player_entered(id):
	return
	if id != network.pid:
		print("player ", id, " entered")

func pick_collectable():
	var choice = randi() % 4
	match choice:
		0:
			return "tetran"
		1:
			return "arrow"
		2:
			return "bomb"
		3:
			return "heart"

func spawn_collectable(collectable, pos, chance):
	if randi() % chance == 0:
		var path = str("res://entities/collectables/", pick_collectable(), ".tscn")
		var new_collectable = load(path).instance()
		call_deferred("add_child", new_collectable)
		new_collectable.position = pos








