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
    if event.is_action_pressed("connect_wallet"):  # X key action
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

    # Status label (Fetching/Failed message)
    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.set_anchors_preset(Control.PRESET_CENTER)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.visible = false

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
    popup_menu.visible = true

func _on_connect_wallet_pressed():
    status_label.text = "Fetching User Address..."
    status_label.visible = true
    connect_wallet()

func _on_close_popup():
    popup_menu.visible = false

func connect_wallet():
    if not OS.has_feature("web"):
        print("Wallet connection only available in web builds")
        return
    
    # JavaScript code to connect to MetaMask and fetch the address
    var script = """
        if (typeof ethereum !== 'undefined') {
            ethereum.request({ method: 'eth_requestAccounts' }).then(accounts => {
                if (accounts.length > 0) {
                    console.log('MetaMask connected! Wallet address:', accounts[0]);
                    window.wallet_address_result = accounts[0];  // Store address globally
                } else {
                    console.error('No accounts found in MetaMask.');
                    window.wallet_address_result = 'No account found';
                }
            }).catch((error) => {
                console.error('Error connecting to MetaMask:', error);
                window.wallet_address_result = 'error';
            });
        } else {
            console.error('MetaMask is not available. Please install MetaMask.');
            window.wallet_address_result = 'Ethereum object not found';
        }
    """
    
    # Execute the JavaScript code
    JavaScriptBridge.eval(script)

    # Wait a bit to let the JavaScript execute before fetching the result
    await get_tree().create_timer(0.5).timeout  

    # Fetch the wallet address from JavaScript
    var result = JavaScriptBridge.eval("window.wallet_address_result")

    # Debugging: Print the result in Godot's output
    print("Received wallet address result:", result)

    if result == "error":
        print("Wallet connection failed.")
        status_label.text = "Failed to connect."
    elif result == "No account found":
        print("No account found.")
        status_label.text = "No account found."
    elif result == "Ethereum object not found":
        print("MetaMask is not available.")
        status_label.text = "MetaMask not found."
    else:
        # Successfully connected, update UI with address
        print("Wallet connected successfully. Address:", result)
        wallet_address = result
        is_wallet_connected = true
        status_label.visible = false  # Hide fetching message
        wallet_address_label.text = "Wallet: " + wallet_address  # Update label
        wallet_address_label.visible = true  # Show the wallet address label
        popup_menu.visible = false  # Hide the popup menu
