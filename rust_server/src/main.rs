use std::thread::sleep;
use std::time::Duration;
use enet::{Address, BandwidthLimit, ChannelLimit, Enet, Event, Host, Packet, PacketMode};
use serde::{Deserialize, Serialize};
// use bincode::{Encode,Decode };
use serde_json::Value;

#[derive(Debug, Serialize, Deserialize)]
struct NetworkMsg {
    id: usize,
    op: String,
    msg: Value,
}

fn main() {
    let enet = Enet::new().expect("enet init failed");

    // Bind to 127.0.0.1 for local testing; use 0.0.0.0 to allow remote clients.
    let address = Address::new("127.0.0.1".parse().unwrap(), 40499);

    let mut host: Host<()> = enet
        .create_host(
            Some(&address),
            64,                        // max peers
            ChannelLimit::Maximum,     // channels
            BandwidthLimit::Unlimited, // in
            BandwidthLimit::Unlimited, // out
        )
        .expect("host create failed");

    println!("Listening on {:?}", host.address());

    loop {
        match host.service(50).expect("service failed") {
            None => {
                println!("received nothing");
                sleep(Duration::from_secs(5));
            }
            Some(mut event) => match event {
                // tuple variant: the Peer comes as a positional value
                Event::Connect(ref mut peer) => {
                    println!("Client connected from {:?}", peer.address());
                    // Send a greeting on channel 1 to match the client’s channel

                    let data = NetworkMsg {
                        id: 0,
                        op: "system".to_string(),
                        msg: serde_json::Value::String("Hello from Server".to_string()),
                    };
                    let mut w: Vec<u8> = Vec::new();
                    //w.push(0);

                    w.append(&mut serde_json::to_vec(&data).unwrap());
                    //let data = br#"{"op":"welcome","msg":{"text":"Hello from Rust!"}}"#;
                    let pkt = Packet::new(&*w, PacketMode::ReliableSequenced).unwrap();

                    peer.send_packet(pkt, 1).unwrap();
                }
                // struct variant: named fields
                Event::Receive {
                    ref sender,
                    channel_id,
                    ref packet,
                    ..
                } => {
                    println!("Got {} bytes on ch {}", packet.data().len(), channel_id);

                    if let Ok(s) = str::from_utf8(packet.data()) {
                        match serde_json::from_str::<NetworkMsg>(s) {
                            Ok(m) => println!("JSON msg from {:?}: {:?}", sender.address(), m),
                            Err(e) => eprintln!("Bad JSON: {e} | raw={s}"),
                        }
                    } else {
                        eprintln!("Non-UTF8 packet from {:?}", sender.address());
                    }
                }
                Event::Disconnect(ref peer, ..) => {
                    println!("Client disconnected {:?}", peer.address());
                }
            },
        };
        host.flush()
    }
}
