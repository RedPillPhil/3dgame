extends Node

signal wallet_connected(address: String)
signal wallet_error(error: String)

var popup_menu: Control
var wallet_address_label: Label
var status_label: Label
var flashing_timer: Timer

func _ready():
	create_popup_menu()

func create_popup_menu():
	popup_menu = Control.new()
	popup_menu.set_anchors_preset(Control.PRESET_CENTER)
	popup_menu.set_size(Vector2(250, 120))
	popup_menu.modulate = Color(1, 1, 1, 1)  # White background
	popup_menu.visible = true  # Show menu at start

	var label = Label.new()
	label.text = "Connect Wallet?"
	label.add_theme_font_size_override("font_size", 20)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var button_yes = Button.new()
	button_yes.text = "Yes"
	button_yes.set_size(Vector2(100, 40))
	button_yes.position = Vector2(25, 60)
	button_yes.connect("pressed", _on_connect_wallet_pressed)

	var button_no = Button.new()
	button_no.text = "No"
	button_no.set_size(Vector2(100, 40))
	button_no.position = Vector2(130, 60)
	button_no.connect("pressed", _on_close_popup)

	# Status label (Fetching/Failed message)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.set_anchors_preset(Control.PRESET_CENTER)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.visible = false  # Hidden at first

	# Wallet address label (Hidden at first)
	wallet_address_label = Label.new()
	wallet_address_label.add_theme_font_size_override("font_size", 16)
	wallet_address_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	wallet_address_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_address_label.visible = false

	# Timer for flashing effect
	flashing_timer = Timer.new()
	flashing_timer.wait_time = 0.5  # Blink every 0.5 seconds
	flashing_timer.autostart = false
	flashing_timer.connect("timeout", _toggle_fetching_visibility)

	popup_menu.add_child(label)
	popup_menu.add_child(button_yes)
	popup_menu.add_child(button_no)
	popup_menu.add_child(status_label)
	popup_menu.add_child(wallet_address_label)
	add_child(popup_menu)
	add_child(flashing_timer)

func _on_connect_wallet_pressed():
	popup_menu.visible = false  # Hide menu after clicking
	show_fetching_status()
	connect_wallet()

func _on_close_popup():
	popup_menu.visible = false  # Hide menu

func show_fetching_status():
	status_label.text = "Fetching User Address..."
	status_label.visible = true
	flashing_timer.start()

func show_failure_status():
	flashing_timer.stop()
	status_label.text = "Failed."
	status_label.visible = true

func _toggle_fetching_visibility():
	status_label.visible = not status_label.visible  # Blinking effect

func connect_wallet():
	var script = """
		(async function() {
			if (typeof window.ethereum !== 'undefined') {
				try {
					const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
					return accounts[0] || 'error';
				} catch (err) {
					return 'error';
				}
			} else {
				return 'no_metamask';
			}
		})()
	"""

	var result = JavaScriptBridge.eval(script, true)  # Ensure synchronous return

	if result == null or result == "":
		print("No response from MetaMask")
		wallet_error.emit("No response from MetaMask")
		show_failure_status()
	elif result == "no_metamask":
		print("MetaMask not installed")
		wallet_error.emit("MetaMask not installed")
		show_failure_status()
	elif result == "error":
		print("Wallet connection failed")
		wallet_error.emit("Wallet connection failed")
		show_failure_status()
	else:
		print("Wallet connected: ", result)  # Debugging print
		status_label.visible = false  # Stop flashing and hide message
		flashing_timer.stop()
		
		# Ensure UI updates happen correctly
		wallet_address_label.call_deferred("set_text", "Wallet: " + str(result))
		wallet_address_label.call_deferred("set_visible", true)

		wallet_connected.emit(result)  # Emit signal with address
