// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use ddcp::{cli::Cli, DDCP};
use tracing::info;
use tracing_subscriber::filter::EnvFilter;
use tracing_subscriber::prelude::*;

fn main() {
    tracing_subscriber::registry()
    .with(tracing_subscriber::fmt::layer().with_writer(std::io::stderr))
    .with(
        EnvFilter::builder()
            .with_default_directive("linkray=info".parse().unwrap())
            .from_env_lossy(),
    )
    .init();

    tauri::Builder::default()
        .setup(|app| {
            tauri::async_runtime::spawn(async move {
                // TODO(ddcp): expose a less-hacky way to access these defaults
                // for embedding apps.
                let cli = Cli {
                    commands: ddcp::cli::Commands::Addr,
                    db_file: None,
                    state_dir: None,
                    ext_file: None,
                };
                let mut ddcp = DDCP::new(
                    Some(cli.db_file().expect("db_file").as_str()),
                    cli.state_dir().expect("state_dir").as_str(),
                    "../../ddcp/target/debug/crsqlite.so",
                ).await.expect("new ddcp instance");
                ddcp.wait_for_network().await.expect("wait for network");
                info!(addr = ddcp.addr());
                ddcp.serve().await.expect("serve");
                info!("shutting down now");
            });
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
