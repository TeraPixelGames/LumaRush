extends Node
class_name ScreenshotUtil

# Minimal helper to capture current viewport as PNG.
# Codex should use this in UAT to generate golden images and compare with tolerance.
static func capture_png(path: String) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		push_error("ScreenshotUtil.capture_png: SceneTree/root unavailable")
		return
	var viewport: Viewport = tree.root
	var img: Image = viewport.get_texture().get_image()
	img.save_png(path)
