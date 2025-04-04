extends Node

@onready var popup_menu: Control = null
@onready var wallet_address_label: Label = null

var is_wallet_connected: bool = false
var wallet_address: String = ""

func _ready():
	create_popup_menu()

func _input(event):
	if event.is_action_pressed("ui_accept"):  # X key (set to "ui_accept" in Input Map)
		show_popup_menu()

func create_popup_menu():
	popup_menu = Control.new()
	popup_menu.set_anchors_preset(Control.PRESET_CENTER)
	popup_menu.set_size(Vector2(300, 150))
	popup_menu.modulate = Color(1, 1, 1, 1)  # White background
	popup_menu.visible = false

	var label = Label.new()
	label.text = "Connect Wallet?"
	label.add_theme_font_size_override("font_size", 20)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var button_yes = Button.new()
	button_yes.text = "Yes"
	button_yes.set_anchors_preset(Control.PRESET_CENTER_TOP)
	button_yes.set_size(Vector2(100, 40))
	button_yes.position = Vector2(50, 70)
	button_yes.connect("pressed", _on_connect_wallet_pressed)

	var button_no = Button.new()
	button_no.text = "No"
	button_no.set_anchors_preset(Control.PRESET_CENTER_TOP)
	button_no.set_size(Vector2(100, 40))
	button_no.position = Vector2(160, 70)
	button_no.connect("pressed", _on_close_popup)

	# Wallet address label (hidden at first)
	wallet_address_label = Label.new()
	wallet_address_label.add_theme_font_size_override("font_size", 16)
	wallet_address_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	wallet_address_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_address_label.visible = false

	# Add elements to menu
	popup_menu.add_child(label)
	popup_menu.add_child(button_yes)
	popup_menu.add_child(button_no)
	popup_menu.add_child(wallet_address_label)

	add_child(popup_menu)

func show_popup_menu():
	popup_menu.visible = true

func _on_connect_wallet_pressed():
	connect_wallet()

func _on_close_popup():
	popup_menu.visible = false

func connect_wallet():
	if not OS.has_feature("web"):
		print("Wallet connection only available in web builds")
		return
	
	# Attempt to connect with MetaMask
	var script = "ethereum.request({ method: 'eth_requestAccounts' }).then(accounts => accounts[0]).catch(console.error);"
	var result = JavaScriptBridge.eval(script)

	if result != null:
		wallet_address = result
		is_wallet_connected = true
		wallet_address_label.text = "Wallet: " + wallet_address
		wallet_address_label.visible = true
		popup_menu.visible = false
	else:
		print("Wallet connection failed.")
