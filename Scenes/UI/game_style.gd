extends RefCounted

const INK = Color("102b2d")
const PAPER = Color("ecedcf")
const MUTED = Color("9cb3a3")
const GOLD = Color("dfc784")
const MINT = Color("8cdbc0")

static func box(background: Color = INK, border: Color = Color("41625a"), radius: int = 12) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func label(parent: Node, text: String, rect: Rect2, font_size: int = 18, color: Color = PAPER) -> Label:
	var node = Label.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_color_override("font_color", color)
	node.add_theme_constant_override("outline_size", 0)
	node.add_theme_font_override("font", load("res://Assets/Fonts/Kodchasan-Bold.ttf"))
	node.add_theme_font_size_override("font_size", font_size)
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("normal", box(Color("d7c58b") if primary else Color("1a3c3b"), GOLD if primary else Color("45675d"), 8))
	node.add_theme_stylebox_override("hover", box(Color("e7d9aa") if primary else Color("31534a"), MINT, 8))
	node.add_theme_stylebox_override("pressed", box(Color("97b29a"), PAPER, 8))
	node.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), MINT, 8))
	node.add_theme_color_override("font_color", INK if primary else PAPER)
	node.add_theme_color_override("font_hover_color", INK if primary else PAPER)
	node.add_theme_color_override("font_focus_color", INK if primary else PAPER)
	node.add_theme_color_override("font_pressed_color", INK)
	node.add_theme_font_override("font", load("res://Assets/Fonts/Kodchasan-Bold.ttf"))
	node.add_theme_font_size_override("font_size", 17)
	node.pressed.connect(action)
	parent.add_child(node)
	return node
