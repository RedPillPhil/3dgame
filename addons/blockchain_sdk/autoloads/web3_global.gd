extends Node

@onready var popup_menu: Control = null
@onready var wallet_address_label: Label = null
@onready var status_label: Label = null

var is_wallet_connected: bool = false
var wallet_address: String = ""

func _ready():
	create_popup_menu()

# Handle input for showing the popup (press the X key)
func _input(event):
	# Detect the key press for wallet connection
	if event.is_action_pressed("connect_wallet"):  # X key action
		show_popup_menu()

func create_popup_menu():
	# Create the popup menu for connecting the wallet
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

	# Status label (Fetching/Failed message)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.set_anchors_preset(Control.PRESET_CENTER)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.visible = false  # Hidden at first

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
	popup_menu.add_child(status_label)
	popup_menu.add_child(wallet_address_label)

	add_child(popup_menu)

func show_popup_menu():
	# Show the popup menu when triggered
	popup_menu.visible = true

func _on_connect_wallet_pressed():
	# Show the fetching status immediately after clicking Yes
	status_label.text = "Fetching User Address..."
	status_label.visible = true
	# Start the wallet connection process
	connect_wallet()

func _on_close_popup():
	# Hide the popup if user selects No
	popup_menu.visible = false

func connect_wallet():
	if not OS.has_feature("web"):
		print("Wallet connection only available in web builds")
		return
	
	# Define the JavaScript code to connect to MetaMask and fetch the address
	var script = """
		if (typeof ethereum !== 'undefined') {
			ethereum.request({ method: 'eth_requestAccounts' }).then(accounts => {
				if (accounts.length > 0) {
					window.wallet_address_result = accounts[0];  // Store the address in a global variable
				} else {
					window.wallet_address_result = 'No account found';
				}
			}).catch((error) => {
				window.wallet_address_result = 'error';
				console.error('Error in wallet connection:', error);  // Log any errors in the JS console
			});
		} else {
			window.wallet_address_result = 'Ethereum object not found';
			console.error('MetaMask not available.');
		}
	"""

	# Execute the script to request the wallet address
	print("Executing wallet connection script...")  # Debugging log in Godot
	JavaScriptBridge.eval(script)

	# Wait for the next frame to ensure the script is executed and the result is set
	await get_tree().idle_frame
	print("Finished waiting for script execution.")  # Debugging log in Godot

	# Retrieve the wallet address from the JavaScript global variable
	var result = JavaScriptBridge.eval("window.wallet_address_result")  # Fetch the result from JS
	print("Received wallet address result from JavaScript:", result)  # Debugging log in Godot

	# Check the result and update the UI accordingly
	if result == "error":
		print("Wallet connection failed.")  # Debugging log in Godot
		status_label.text = "Failed to connect."
	elif result == "No account found":
		print("No account found.")  # Debugging log in Godot
		status_label.text = "No account found."
	elif result == "Ethereum object not found":
		print("MetaMask is not available.")  # Debugging log in Godot
		status_label.text = "MetaMask not found."
	else:
		# Successfully connected, update the UI
		print("Wallet connected successfully. Address:", result)  # Debugging log in Godot
		wallet_address = result
		is_wallet_connected = true
		status_label.text = "Wallet connected"
		status_label.visible = false  # Hide the "Fetching User Address" status
		wallet_address_label.text = "Wallet: " + wallet_address
		wallet_address_label.visible = true  # Show wallet address label
		popup_menu.visible = false  # Hide the popup menu
