func connect_wallet():
    if not OS.has_feature("web"):
        print("Wallet connection only available in web builds")
        return
    
    var script = """
        if (typeof ethereum !== 'undefined') {
            ethereum.request({ method: 'eth_requestAccounts' }).then(accounts => {
                if (accounts.length > 0) {
                    console.log('MetaMask connected! Wallet address:', accounts[0]);
                    window.wallet_address_result = accounts[0];  
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
    
    JavaScriptBridge.eval(script)

    await get_tree().create_timer(0.5).timeout  # Wait for JS execution

    var result = JavaScriptBridge.eval("window.wallet_address_result")

    print("Received wallet address result:", result)

    if result == "error":
        print("Wallet connection failed.")
        status_label.text = "Failed to connect."
        status_label.visible = true
    elif result == "No account found":
        print("No account found.")
        status_label.text = "No account found."
        status_label.visible = true
    elif result == "Ethereum object not found":
        print("MetaMask is not available.")
        status_label.text = "MetaMask not found."
        status_label.visible = true
    else:
        # ✅ Successfully connected, update UI
        print("Wallet connected successfully. Address:", result)
        wallet_address = result
        is_wallet_connected = true
        
        # ✅ Make sure label updates correctly
        wallet_address_label.text = "Wallet: " + wallet_address
        wallet_address_label.show()  # Ensure it's visible
        wallet_address_label.modulate = Color(1, 1, 1, 1)  # Ensure full opacity
        
        # ✅ Hide popup and status message
        status_label.hide()
        popup_menu.hide()
