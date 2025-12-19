use axum::{response::Html, routing::get, Router};
use std::net::SocketAddr;
use tracing::info;
use tracing_subscriber;

use anyhow::Context;

pub async fn run() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let app = Router::new().route(
        "/",
        get(|| async { Html("<h1>Anthropous Wallet API 🦀</h1><p>Powered by Alloy + Axum</p>") }),
    );

    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    info!("API server listening on http://{}", addr);

    // Bind to 0.0.0.0 in Docker, 127.0.0.1 locally
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .context("Failed to bind address")?;

    tracing::info!("Starting Secure Wallet Recovery Backend on http://{}", addr);

    // 7. Start Axum Server
    axum::serve(listener, app).await?;

    Ok(())
}
