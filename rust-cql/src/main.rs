/*
 * Copyright 2026-present ScyllaDB
 * SPDX-License-Identifier: LicenseRef-ScyllaDB-Source-Available-1.0
 */

use anyhow::{Context, Result};
use clap::Parser;
use rustls::pki_types::CertificateDer;
use rustls::ClientConfig;
use rustls::RootCertStore;
use rustls_pki_types::pem::PemObject;
use scylla::client::session::Session;
use scylla::client::session::TlsContext;
use scylla::client::session_builder::SessionBuilder;
use std::path::PathBuf;
use std::time::Duration;
use tokio::fs;
use tokio::time::sleep;
use tracing::{error, info};
use tracing_subscriber::fmt;
use tracing_subscriber::prelude::*;
use tracing_subscriber::EnvFilter;
use std::sync::Arc;

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
struct Args {
    /// ScyllaDB URI
    #[clap(long)]
    scylla_uri: String,

    /// ScyllaDB username
    #[clap(long)]
    user: Option<String>,

    /// Path to ScyllaDB password file
    #[clap(long)]
    password_file: Option<PathBuf>,

    /// Path to ScyllaDB TLS certificate file
    #[clap(long)]
    certificate_file: Option<PathBuf>,
}

async fn configure_authentication(
    mut builder: SessionBuilder,
    user: Option<String>,
    pass_path: Option<PathBuf>,
) -> Result<SessionBuilder> {
    if let (Some(user), Some(pass_path)) = (user, pass_path) {
        info!(
            "Using username/password authentication. {} {}",
            user,
            pass_path.display()
        );
        let password = fs::read_to_string(pass_path).await?;
        builder = builder.user(user, password.trim());
    }
    Ok(builder)
}

async fn configure_tls(
    mut builder: SessionBuilder,
    cert_file: Option<PathBuf>,
) -> Result<SessionBuilder> {
    if let Some(cert_path) = cert_file {
        let cert_pem = tokio::fs::read(&cert_path)
            .await
            .with_context(|| format!("Failed to read certificate file at {cert_path:?}"))?;

        let ca_der = CertificateDer::pem_slice_iter(&cert_pem)
            .collect::<Result<Vec<_>, _>>()
            .context("Failed to parse certificate PEM")?;

        let mut root_store = RootCertStore::empty();
        root_store.add_parsable_certificates(ca_der);

        let client_cfg = ClientConfig::builder()
            .with_root_certificates(root_store)
            .with_no_client_auth();

        let tls_context: TlsContext = TlsContext::from(Arc::new(client_cfg));
        builder = builder.tls_context(Some(tls_context));

        info!("TLS (rustls) enabled with certificate from {:?}", cert_path);
    }
    Ok(builder)
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::registry()
        .with(EnvFilter::try_from_default_env().or_else(|_| EnvFilter::try_new("info"))?)
        .with(fmt::layer().with_target(false).with_ansi(true))
        .init();

    let args = Args::parse();

    info!("Attempting to connect to ScyllaDB at {}", args.scylla_uri);

    let mut builder = SessionBuilder::new().known_node(&args.scylla_uri);
    builder = configure_authentication(builder, args.user, args.password_file).await?;
    builder = configure_tls(builder, args.certificate_file).await?;

    let session: Arc<Session> = Arc::new(
        builder
            .build()
            .await
            .context("Failed to build Scylla session")?,
    );

    info!("Session created successfully.");

    let query =
        "SELECT state_id FROM system.group0_history WHERE key = 'history' ORDER BY state_id DESC LIMIT 1";

    loop {
        match session.query_unpaged(query, ()).await {
            Ok(_) => {
                info!("Query executed successfully.");
            }
            Err(e) => {
                error!("Query failed: {}", e);
            }
        }

        sleep(Duration::from_secs(5)).await;
    }
}
