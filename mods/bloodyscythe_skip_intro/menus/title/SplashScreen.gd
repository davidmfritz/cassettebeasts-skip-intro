extends CanvasLayer

const TITLE_SCENE_PATH = "res://menus/title/TitleMenu.tscn"
const LOAD_AT_INDEX = 1

const splash_image: Resource = preload("res://rising_key_art_1080_logo.png")

export (Array, Resource) var splash_cards:Array

onready var container = $Container
onready var texture_rect = $Container / TextureRect
onready var video_player = $Container / VideoPlayer

var card_index:int = 0
var finished:bool = false
var t:float = 0.0
var load_promise:Promise

func _ready():
	SceneManager.transition = SceneManager.TransitionKind.TRANSITION_FADE
	SceneManager.transition_out()
	
	# remove all animations and logos
	splash_cards.clear()
	# simulate as though we're still just in the boot splash
	splash_cards.push_back(splash_image)
	
	setup_card()
	
	#prevent flickering of scenes that get loaded in
	var t = Timer.new()
	t.set_wait_time(0.4)
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	yield(t, "timeout")
	t.queue_free()
	
	# auto skip whatever scenes there are
	while card_index < splash_cards.size():
		next()

func setup_card():
	t = 0.0
	video_player.stop()
	
	if card_index == LOAD_AT_INDEX:
		start_full_load()
	
	if card_index >= splash_cards.size():
		finish()
		return 
	
	var card = splash_cards[card_index]
	if card is Texture:
		texture_rect.visible = true
		video_player.visible = false
		texture_rect.texture = card
		t = 0
		
	elif card is VideoStream:
		texture_rect.visible = false
		video_player.visible = true
		video_player.stream = card
		video_player.play()
		
	elif card is PackedScene:
		texture_rect.visible = false
		video_player.visible = false
		var scene = card.instance()
		assert (scene.has_node("AnimationPlayer"))
		container.add_child(scene)
		scene.get_node("AnimationPlayer").connect("animation_finished", self, "_on_AnimationPlayer_finished", [scene])
	else :
		assert (false)
	

func next():
	card_index += 1
	setup_card()

func _on_AnimationPlayer_finished(_anim_name, scene):
	container.remove_child(scene)
	scene.queue_free()
	next()

func _on_VideoPlayer_finished():
	next()

func _process(delta:float):
	if finished or t <= 0.0:
		return 
	t -= delta
	if t < 0.0:
		next()

func _input(event:InputEvent):
	if finished:
		return 
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		next()
		get_tree().set_input_as_handled()
		return 
	
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		next()
		get_tree().set_input_as_handled()
		return 

func start_full_load():
	load_promise = Promise.new()
	SceneManager.set_loading(true)
	SceneManager.start_preload("full_load", load_promise)

func finish():
	if finished:
		return 
	finished = true
	container.visible = false
	
	if not load_promise.ready:
		yield (load_promise, "fulfilled")
	
	SceneManager.change_scene(TITLE_SCENE_PATH, {hide_loading_ui = true})

