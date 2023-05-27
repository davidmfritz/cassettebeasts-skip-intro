extends ContentInfo

const splash_screen: Resource = preload("menus/title/SplashScreen.gd")

func init_content() -> void:
	var scene = SceneManager.get_tree().root.get_node("/root/SplashScreen")
	scene.set_script(splash_screen)
