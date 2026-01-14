extends Node

const IP_ADDRESS := "127.0.0.1"
const PORT := 40499

var peer: ENetMultiplayerPeer
var sent_hello := false

func _ready() -> void:
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(IP_ADDRESS, PORT, 2)
	if err != OK:
		push_error("ENet client create failed: %s" % error_string(err))
		return
	# IMPORTANT: don't set multiplayer.multiplayer_peer = peer

func _process(_dt: float) -> void:
	peer.poll()
	# wait until connected
	if peer.get_connection_status() == ENetMultiplayerPeer.CONNECTION_CONNECTED and not sent_hello:
		print("send hello")
		sent_hello = true
		var msg := {
			"op": "chat",
			"id": 0,
			"msg": {"text": "Hello from Godot!"}
		}
		var bytes: PackedByteArray = JSON.stringify(msg).to_utf8_buffer()
		peer.transfer_channel = 1
		peer.put_packet(bytes)

	while peer.get_available_packet_count() > 0:
		var pkt: PackedByteArray = peer.get_packet()
		var txt := pkt.get_string_from_utf8()
		print("RAW -> ", txt)
		var parsed = JSON.parse_string(txt)
		if typeof(parsed) == TYPE_DICTIONARY:
			print("json:", parsed)
		else:
			push_warning("Could not parse: %s" % txt)


#extends Node
#
#const IP_ADDRESS := "127.0.0.1"
#const PORT := 40499
#
#var peer: ENetMultiplayerPeer
#
#func _ready() -> void:
	#peer = ENetMultiplayerPeer.new()
	#var err := peer.create_client(IP_ADDRESS, PORT)
	#if err != OK:
		#push_error("ENet client create failed: %s" % error_string(err))
		#return
#
	#multiplayer.connected_to_server.connect(on_connected)
	#multiplayer.connection_failed.connect(on_connection_failed)
	#multiplayer.server_disconnected.connect(on_server_disconnected)
	#
	## 🔽 Raw packet receive signal
	#multiplayer.peer_packet.connect(_on_peer_packet)
	#
#
	#multiplayer.multiplayer_peer = peer
	#print("status:", peer.get_connection_status())  # likely 1 (CONNECTING)
#
#func _process(_dt):
	## 🔽 poll raw packets (no header semantics)
	#while peer.get_available_packet_count() > 0:
		#var pkt: PackedByteArray = peer.get_packet()
		#var txt := pkt.get_string_from_utf8()
		#print("RAW -> ", txt)  # should start with '{'
		#var parsed = JSON.parse_string(txt)
		#if typeof(parsed) == TYPE_DICTIONARY:
			#print("json:", parsed)
		#else:
			#push_warning("Could not parse: %s" % txt)
#
#func on_connected() -> void:
	#print("connected ✅")
	#
	#var msg := {
	#"op": "chat",
	#"id": multiplayer.get_unique_id(),
	#"msg": {"text": "Hello from Godot!"}
	#}
#
	#var bytes: PackedByteArray = JSON.stringify(msg).to_utf8_buffer()
	#multiplayer.multiplayer_peer.transfer_channel = 1
	#multiplayer.multiplayer_peer.put_packet(bytes)
	#
#func _on_peer_packet(peer_id:int, packet:PackedByteArray) -> void:
	## If you need to know which channel/mode this packet used:
	#var ch := multiplayer.multiplayer_peer.get_packet_channel()
	#var mode := multiplayer.multiplayer_peer.get_packet_mode()
	#print("got ", packet.size(), "bytes from peer ", peer_id, " on channel ", ch, " mode ", mode)
#
	## Example: parse JSON
	#var txt := packet.get_string_from_utf8()
	#var parsed = JSON.parse_string(txt)
	#print(txt)
	#if typeof(parsed) == TYPE_DICTIONARY:
		#print("message:", parsed)
	#else:
		#push_warning("Could not parse: %s" % txt)
#
#func on_connection_failed() -> void:
	#print("connection failed ❌")
#
#func on_server_disconnected() -> void:
	#print("server disconnected 🔌")
	#
